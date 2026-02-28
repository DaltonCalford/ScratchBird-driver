/*
 * ScratchBird-driver
 * Copyright (c) 2025-2026 Dalton Calford
 *
 * Licensed under the Initial Developer's Public License Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
 */
/*
 * ScratchBird JDBC Driver
 * Copyright (c) 2025 ScratchBird Project
 */
package com.scratchbird.jdbc;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Reader;
import java.io.StringReader;
import java.io.StringWriter;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.lang.reflect.Constructor;
import java.sql.SQLException;
import java.sql.SQLFeatureNotSupportedException;
import java.sql.SQLXML;
import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLOutputFactory;
import javax.xml.stream.XMLStreamReader;
import javax.xml.stream.XMLStreamWriter;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.sax.SAXResult;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.sax.SAXTransformerFactory;
import javax.xml.transform.sax.TransformerHandler;
import javax.xml.transform.stax.StAXResult;
import javax.xml.transform.stax.StAXSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import org.w3c.dom.Node;
import org.xml.sax.Attributes;
import org.xml.sax.InputSource;
import org.xml.sax.helpers.DefaultHandler;

/**
 * JDBC SQLXML implementation for ScratchBird.
 */
public class SBSQLXML implements SQLXML {
    @FunctionalInterface
    private interface Materializer {
        String materialize() throws Exception;
    }

    private String data;
    private boolean freed = false;
    private Materializer pendingMaterializer;

    public SBSQLXML() {
        this.data = null;
    }

    public SBSQLXML(String xml) {
        this.data = xml;
    }

    @Override
    public void free() throws SQLException {
        data = null;
        freed = true;
        pendingMaterializer = null;
    }

    @Override
    public InputStream getBinaryStream() throws SQLException {
        checkFreed();
        materializeIfPending();
        if (data == null) return null;
        return new ByteArrayInputStream(data.getBytes(StandardCharsets.UTF_8));
    }

    @Override
    public OutputStream setBinaryStream() throws SQLException {
        checkFreed();
        pendingMaterializer = null;
        return new ByteArrayOutputStream() {
            @Override
            public void close() {
                data = new String(toByteArray(), StandardCharsets.UTF_8);
            }
        };
    }

    @Override
    public Reader getCharacterStream() throws SQLException {
        checkFreed();
        materializeIfPending();
        if (data == null) return null;
        return new StringReader(data);
    }

    @Override
    public Writer setCharacterStream() throws SQLException {
        checkFreed();
        pendingMaterializer = null;
        return new StringWriter() {
            @Override
            public void close() {
                data = toString();
            }
        };
    }

    @Override
    public String getString() throws SQLException {
        checkFreed();
        materializeIfPending();
        return data;
    }

    @Override
    public void setString(String value) throws SQLException {
        checkFreed();
        this.data = value;
        this.pendingMaterializer = null;
    }

    @Override
    public <T extends Source> T getSource(Class<T> sourceClass) throws SQLException {
        checkFreed();
        materializeIfPending();

        String xml = data == null ? "" : data;
        if (sourceClass == null || sourceClass == Source.class || sourceClass == StreamSource.class) {
            @SuppressWarnings("unchecked")
            T streamSource = (T) new StreamSource(new StringReader(xml));
            return streamSource;
        }
        if (sourceClass == DOMSource.class) {
            @SuppressWarnings("unchecked")
            T domSource = (T) new DOMSource(parseDom(xml));
            return domSource;
        }
        if (sourceClass == SAXSource.class) {
            @SuppressWarnings("unchecked")
            T saxSource = (T) new SAXSource(new InputSource(new StringReader(xml)));
            return saxSource;
        }
        if (sourceClass == StAXSource.class) {
            try {
                XMLInputFactory factory = XMLInputFactory.newFactory();
                XMLStreamReader reader = factory.createXMLStreamReader(new StringReader(xml));
                @SuppressWarnings("unchecked")
                T staxSource = (T) new StAXSource(reader);
                return staxSource;
            } catch (Exception ex) {
                throw new SQLException("Failed to build StAXSource from SQLXML", "HY000", ex);
            }
        }
        if (sourceClass != null && StreamSource.class.isAssignableFrom(sourceClass)) {
            return instantiateStreamSourceSubclass(sourceClass, xml);
        }
        if (sourceClass != null && DOMSource.class.isAssignableFrom(sourceClass)) {
            return instantiateDomSourceSubclass(sourceClass, xml);
        }
        if (sourceClass != null && SAXSource.class.isAssignableFrom(sourceClass)) {
            return instantiateSaxSourceSubclass(sourceClass, xml);
        }
        if (sourceClass != null && StAXSource.class.isAssignableFrom(sourceClass)) {
            return instantiateStaxSourceSubclass(sourceClass, xml);
        }
        throw new SQLFeatureNotSupportedException("Source class not supported: " + sourceClass);
    }

    @Override
    public <T extends Result> T setResult(Class<T> resultClass) throws SQLException {
        checkFreed();
        if (resultClass == null || resultClass == Result.class || resultClass == StreamResult.class) {
            StringWriter writer = new StringWriter();
            pendingMaterializer = writer::toString;
            @SuppressWarnings("unchecked")
            T streamResult = (T) new StreamResult(writer);
            return streamResult;
        }
        if (resultClass == DOMResult.class) {
            DOMResult domResult = new DOMResult();
            pendingMaterializer = () -> serializeDom(domResult.getNode());
            @SuppressWarnings("unchecked")
            T result = (T) domResult;
            return result;
        }
        if (resultClass == SAXResult.class) {
            try {
                TransformerFactory transformerFactory = TransformerFactory.newInstance();
                if (transformerFactory instanceof SAXTransformerFactory saxFactory) {
                    TransformerHandler handler = saxFactory.newTransformerHandler();
                    StringWriter writer = new StringWriter();
                    handler.setResult(new StreamResult(writer));
                    pendingMaterializer = writer::toString;
                    @SuppressWarnings("unchecked")
                    T result = (T) new SAXResult(handler);
                    return result;
                }
                SaxCaptureHandler handler = new SaxCaptureHandler();
                pendingMaterializer = handler::toXml;
                @SuppressWarnings("unchecked")
                T result = (T) new SAXResult(handler);
                return result;
            } catch (Exception ex) {
                throw new SQLException("Failed to initialize SAXResult for SQLXML", "HY000", ex);
            }
        }
        if (resultClass == StAXResult.class) {
            try {
                StringWriter writer = new StringWriter();
                XMLOutputFactory outputFactory = XMLOutputFactory.newFactory();
                XMLStreamWriter streamWriter = outputFactory.createXMLStreamWriter(writer);
                pendingMaterializer = () -> {
                    streamWriter.flush();
                    streamWriter.close();
                    return writer.toString();
                };
                @SuppressWarnings("unchecked")
                T result = (T) new StAXResult(streamWriter);
                return result;
            } catch (Exception ex) {
                throw new SQLException("Failed to initialize StAXResult for SQLXML", "HY000", ex);
            }
        }
        if (resultClass != null && StreamResult.class.isAssignableFrom(resultClass)) {
            return instantiateStreamResultSubclass(resultClass);
        }
        if (resultClass != null && DOMResult.class.isAssignableFrom(resultClass)) {
            return instantiateDomResultSubclass(resultClass);
        }
        if (resultClass != null && SAXResult.class.isAssignableFrom(resultClass)) {
            return instantiateSaxResultSubclass(resultClass);
        }
        if (resultClass != null && StAXResult.class.isAssignableFrom(resultClass)) {
            return instantiateStaxResultSubclass(resultClass);
        }
        throw new SQLFeatureNotSupportedException("Result class not supported: " + resultClass);
    }

    private <T extends Source> T instantiateStreamSourceSubclass(Class<T> sourceClass, String xml) throws SQLException {
        try {
            Constructor<T> ctor = sourceClass.getDeclaredConstructor();
            ctor.setAccessible(true);
            T instance = ctor.newInstance();
            if (!(instance instanceof StreamSource streamSource)) {
                throw new SQLFeatureNotSupportedException("Source class not supported: " + sourceClass);
            }
            streamSource.setReader(new StringReader(xml));
            return instance;
        } catch (SQLFeatureNotSupportedException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new SQLFeatureNotSupportedException("Source class not supported: " + sourceClass);
        }
    }

    private <T extends Source> T instantiateDomSourceSubclass(Class<T> sourceClass, String xml) throws SQLException {
        try {
            Constructor<T> ctor = sourceClass.getDeclaredConstructor();
            ctor.setAccessible(true);
            T instance = ctor.newInstance();
            if (!(instance instanceof DOMSource domSource)) {
                throw new SQLFeatureNotSupportedException("Source class not supported: " + sourceClass);
            }
            domSource.setNode(parseDom(xml));
            return instance;
        } catch (SQLFeatureNotSupportedException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new SQLFeatureNotSupportedException("Source class not supported: " + sourceClass);
        }
    }

    private <T extends Source> T instantiateSaxSourceSubclass(Class<T> sourceClass, String xml) throws SQLException {
        try {
            Constructor<T> ctor = sourceClass.getDeclaredConstructor();
            ctor.setAccessible(true);
            T instance = ctor.newInstance();
            if (!(instance instanceof SAXSource saxSource)) {
                throw new SQLFeatureNotSupportedException("Source class not supported: " + sourceClass);
            }
            saxSource.setInputSource(new InputSource(new StringReader(xml)));
            return instance;
        } catch (SQLFeatureNotSupportedException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new SQLFeatureNotSupportedException("Source class not supported: " + sourceClass);
        }
    }

    private <T extends Source> T instantiateStaxSourceSubclass(Class<T> sourceClass, String xml) throws SQLException {
        try {
            XMLInputFactory factory = XMLInputFactory.newFactory();
            XMLStreamReader reader = factory.createXMLStreamReader(new StringReader(xml));
            try {
                Constructor<T> ctor = sourceClass.getDeclaredConstructor(XMLStreamReader.class);
                ctor.setAccessible(true);
                return ctor.newInstance(reader);
            } catch (NoSuchMethodException ex) {
                throw new SQLFeatureNotSupportedException("Source class not supported: " + sourceClass);
            }
        } catch (SQLFeatureNotSupportedException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new SQLException("Failed to build StAXSource from SQLXML", "HY000", ex);
        }
    }

    private <T extends Result> T instantiateStreamResultSubclass(Class<T> resultClass) throws SQLException {
        try {
            Constructor<T> ctor = resultClass.getDeclaredConstructor();
            ctor.setAccessible(true);
            T instance = ctor.newInstance();
            if (!(instance instanceof StreamResult streamResult)) {
                throw new SQLFeatureNotSupportedException("Result class not supported: " + resultClass);
            }
            StringWriter writer = new StringWriter();
            streamResult.setWriter(writer);
            pendingMaterializer = writer::toString;
            return instance;
        } catch (SQLFeatureNotSupportedException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new SQLFeatureNotSupportedException("Result class not supported: " + resultClass);
        }
    }

    private <T extends Result> T instantiateDomResultSubclass(Class<T> resultClass) throws SQLException {
        try {
            Constructor<T> ctor = resultClass.getDeclaredConstructor();
            ctor.setAccessible(true);
            T instance = ctor.newInstance();
            if (!(instance instanceof DOMResult domResult)) {
                throw new SQLFeatureNotSupportedException("Result class not supported: " + resultClass);
            }
            pendingMaterializer = () -> serializeDom(domResult.getNode());
            return instance;
        } catch (SQLFeatureNotSupportedException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new SQLFeatureNotSupportedException("Result class not supported: " + resultClass);
        }
    }

    private <T extends Result> T instantiateSaxResultSubclass(Class<T> resultClass) throws SQLException {
        try {
            Constructor<T> ctor = resultClass.getDeclaredConstructor();
            ctor.setAccessible(true);
            T instance = ctor.newInstance();
            if (!(instance instanceof SAXResult saxResult)) {
                throw new SQLFeatureNotSupportedException("Result class not supported: " + resultClass);
            }
            TransformerFactory transformerFactory = TransformerFactory.newInstance();
            if (transformerFactory instanceof SAXTransformerFactory saxFactory) {
                TransformerHandler handler = saxFactory.newTransformerHandler();
                StringWriter writer = new StringWriter();
                handler.setResult(new StreamResult(writer));
                saxResult.setHandler(handler);
                pendingMaterializer = writer::toString;
                return instance;
            }
            SaxCaptureHandler handler = new SaxCaptureHandler();
            saxResult.setHandler(handler);
            pendingMaterializer = handler::toXml;
            return instance;
        } catch (SQLFeatureNotSupportedException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new SQLFeatureNotSupportedException("Result class not supported: " + resultClass);
        }
    }

    private <T extends Result> T instantiateStaxResultSubclass(Class<T> resultClass) throws SQLException {
        try {
            StringWriter writer = new StringWriter();
            XMLOutputFactory outputFactory = XMLOutputFactory.newFactory();
            XMLStreamWriter streamWriter = outputFactory.createXMLStreamWriter(writer);
            pendingMaterializer = () -> {
                streamWriter.flush();
                streamWriter.close();
                return writer.toString();
            };
            Constructor<T> ctor = resultClass.getDeclaredConstructor(XMLStreamWriter.class);
            ctor.setAccessible(true);
            return ctor.newInstance(streamWriter);
        } catch (NoSuchMethodException ex) {
            throw new SQLFeatureNotSupportedException("Result class not supported: " + resultClass);
        } catch (Exception ex) {
            throw new SQLException("Failed to initialize StAXResult for SQLXML", "HY000", ex);
        }
    }

    private void materializeIfPending() throws SQLException {
        if (pendingMaterializer == null) {
            return;
        }
        try {
            data = pendingMaterializer.materialize();
            pendingMaterializer = null;
        } catch (SQLException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new SQLException("Failed to materialize SQLXML data", "HY000", ex);
        }
    }

    private Node parseDom(String xml) throws SQLException {
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setNamespaceAware(true);
            factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
            disableExternalEntities(factory);
            DocumentBuilder builder = factory.newDocumentBuilder();
            return builder.parse(new InputSource(new StringReader(xml)));
        } catch (Exception ex) {
            throw new SQLException("Failed to parse SQLXML DOM source", "22000", ex);
        }
    }

    private String serializeDom(Node node) throws SQLException {
        if (node == null) {
            return null;
        }
        try {
            Transformer transformer = TransformerFactory.newInstance().newTransformer();
            StringWriter writer = new StringWriter();
            transformer.transform(new DOMSource(node), new StreamResult(writer));
            return writer.toString();
        } catch (Exception ex) {
            throw new SQLException("Failed to serialize SQLXML DOM result", "22000", ex);
        }
    }

    private void disableExternalEntities(DocumentBuilderFactory factory) {
        try {
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        } catch (Exception ignored) {
            // Parser does not expose this hardening switch.
        }
        try {
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
        } catch (Exception ignored) {
            // Parser does not expose this hardening switch.
        }
        try {
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        } catch (Exception ignored) {
            // Parser does not expose this hardening switch.
        }
    }

    private void checkFreed() throws SQLException {
        if (freed) {
            throw new SQLException("SQLXML has been freed", "HY000");
        }
    }

    private static final class SaxCaptureHandler extends DefaultHandler {
        private final StringBuilder builder = new StringBuilder();
        private boolean startedDocument;

        @Override
        public void startDocument() {
            startedDocument = true;
        }

        @Override
        public void startElement(String uri, String localName, String qName, Attributes attributes) {
            String element = localName != null && !localName.isEmpty() ? localName : qName;
            builder.append('<').append(element);
            if (attributes != null) {
                for (int i = 0; i < attributes.getLength(); i++) {
                    String name = attributes.getQName(i);
                    if (name == null || name.isEmpty()) {
                        name = attributes.getLocalName(i);
                    }
                    builder.append(' ').append(name).append("=\"")
                        .append(escapeXml(attributes.getValue(i))).append('"');
                }
            }
            builder.append('>');
        }

        @Override
        public void characters(char[] ch, int start, int length) {
            if (length <= 0) {
                return;
            }
            builder.append(escapeXml(new String(ch, start, length)));
        }

        @Override
        public void endElement(String uri, String localName, String qName) {
            String element = localName != null && !localName.isEmpty() ? localName : qName;
            builder.append("</").append(element).append('>');
        }

        private String toXml() {
            if (!startedDocument && builder.length() == 0) {
                return null;
            }
            return builder.toString();
        }
    }

    private static String escapeXml(String value) {
        if (value == null || value.isEmpty()) {
            return "";
        }
        StringBuilder out = new StringBuilder(value.length());
        for (int i = 0; i < value.length(); i++) {
            char ch = value.charAt(i);
            switch (ch) {
                case '&' -> out.append("&amp;");
                case '<' -> out.append("&lt;");
                case '>' -> out.append("&gt;");
                case '"' -> out.append("&quot;");
                case '\'' -> out.append("&apos;");
                default -> out.append(ch);
            }
        }
        return out.toString();
    }
}
