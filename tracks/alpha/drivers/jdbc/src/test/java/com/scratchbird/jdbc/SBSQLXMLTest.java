/*
 * ScratchBird-driver
 * Copyright (c) 2025-2026 Dalton Calford
 *
 * Licensed under the Initial Developer's Public License Version 1.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 * https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
 */
package com.scratchbird.jdbc;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.io.StringReader;
import java.io.Writer;
import javax.xml.stream.XMLStreamWriter;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMResult;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.sax.SAXResult;
import javax.xml.transform.sax.SAXSource;
import javax.xml.transform.stax.StAXResult;
import javax.xml.transform.stax.StAXSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import org.junit.jupiter.api.Test;

class SBSQLXMLTest {

    @Test
    void supportsDomSourceAndDomResultRoundTrip() throws Exception {
        SBSQLXML sourceXml = new SBSQLXML("<root><value>1</value></root>");
        DOMSource source = sourceXml.getSource(DOMSource.class);
        assertNotNull(source.getNode());

        SBSQLXML target = new SBSQLXML();
        DOMResult result = target.setResult(DOMResult.class);
        TransformerFactory.newInstance().newTransformer().transform(source, result);

        String xml = target.getString();
        assertNotNull(xml);
        assertTrue(xml.contains("root"));
        assertTrue(xml.contains("value"));
    }

    @Test
    void supportsSaxAndStaxSourcesAndResults() throws Exception {
        SBSQLXML sourceXml = new SBSQLXML("<root><n>7</n></root>");
        SAXSource saxSource = sourceXml.getSource(SAXSource.class);
        assertNotNull(saxSource.getInputSource());
        StAXSource staxSource = sourceXml.getSource(StAXSource.class);
        assertNotNull(staxSource.getXMLStreamReader());

        SBSQLXML saxTarget = new SBSQLXML();
        SAXResult saxResult = saxTarget.setResult(SAXResult.class);
        TransformerFactory.newInstance().newTransformer().transform(
            new StreamSource(new StringReader("<sax><ok>true</ok></sax>")), saxResult);
        assertTrue(saxTarget.getString().contains("sax"));

        SBSQLXML staxTarget = new SBSQLXML();
        StAXResult staxResult = staxTarget.setResult(StAXResult.class);
        XMLStreamWriter writer = staxResult.getXMLStreamWriter();
        writer.writeStartDocument();
        writer.writeStartElement("stax");
        writer.writeCharacters("ok");
        writer.writeEndElement();
        writer.writeEndDocument();
        assertTrue(staxTarget.getString().contains("<stax>ok</stax>"));
    }

    @Test
    void nullResultClassUsesStreamResultAndMaterializesOnRead() throws Exception {
        SBSQLXML sqlxml = new SBSQLXML();
        StreamResult result = sqlxml.setResult(null);
        Writer writer = result.getWriter();
        writer.write("<doc/>");
        writer.close();

        assertEquals("<doc/>", sqlxml.getString());
    }

    @Test
    void genericSourceAndResultClassRequestsUseStreamImplementations() throws Exception {
        SBSQLXML sqlxml = new SBSQLXML("<root/>");
        Source source = sqlxml.getSource(Source.class);
        assertTrue(source instanceof StreamSource);

        SBSQLXML target = new SBSQLXML();
        Result result = target.setResult(Result.class);
        assertTrue(result instanceof StreamResult);
        Writer writer = ((StreamResult) result).getWriter();
        writer.write("<generic/>");
        writer.close();
        assertEquals("<generic/>", target.getString());
    }
}
