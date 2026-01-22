/*
 * ScratchBird JDBC Driver
 * Copyright (c) 2025 ScratchBird Project
 */
package com.scratchbird.jdbc;

import java.io.*;
import java.net.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.security.KeyStore;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.net.ssl.*;

/**
 * Protocol handler for ScratchBird native wire protocol.
 *
 * <p>This class manages the low-level communication with the ScratchBird server
 * using the native binary protocol on port 3092.</p>
 */
public class SBProtocolHandler {

    private static final Logger LOGGER = Logger.getLogger(SBProtocolHandler.class.getName());

    // Protocol message types
    private static final byte MSG_STARTUP = 'S';
    private static final byte MSG_AUTH_REQUEST = 'R';
    private static final byte MSG_AUTH_OK = 'A';
    private static final byte MSG_QUERY = 'Q';
    private static final byte MSG_PARSE = 'P';
    private static final byte MSG_BIND = 'B';
    private static final byte MSG_DESCRIBE = 'D';
    private static final byte MSG_EXECUTE = 'E';
    private static final byte MSG_SYNC = 'Y';
    private static final byte MSG_CLOSE = 'C';
    private static final byte MSG_TERMINATE = 'X';
    private static final byte MSG_ROW_DESCRIPTION = 'T';
    private static final byte MSG_DATA_ROW = 'D';
    private static final byte MSG_COMMAND_COMPLETE = 'C';
    private static final byte MSG_READY_FOR_QUERY = 'Z';
    private static final byte MSG_ERROR = 'E';
    private static final byte MSG_NOTICE = 'N';
    private static final byte MSG_PARAMETER_STATUS = 'S';
    private static final byte MSG_CANCEL_REQUEST = 'F';
    private static final byte MSG_BACKEND_KEY_DATA = 'K';

    // Protocol version
    private static final int PROTOCOL_VERSION_MAJOR = 1;
    private static final int PROTOCOL_VERSION_MINOR = 0;

    // Connection properties
    private final SBConnectionProperties props;

    // Network I/O
    private Socket socket;
    private InputStream inputStream;
    private OutputStream outputStream;
    private DataInputStream dataInput;
    private DataOutputStream dataOutput;

    // Connection state
    private boolean connected = false;
    private int processId;
    private int secretKey;
    private int networkTimeout = 0;

    // Server parameters
    private Map<String, String> serverParameters = new HashMap<>();

    // Buffer for message construction
    private ByteArrayOutputStream messageBuffer = new ByteArrayOutputStream(8192);
    private DataOutputStream messageOutput = new DataOutputStream(messageBuffer);

    private SBScramClient scramClient;

    /**
     * Creates a new protocol handler.
     *
     * @param props connection properties
     */
    public SBProtocolHandler(SBConnectionProperties props) {
        this.props = props;
    }

    /**
     * Establishes connection to the server.
     *
     * @throws SQLException if connection fails
     */
    public void connect() throws SQLException {
        try {
            // Create socket
            socket = new Socket();
            socket.setTcpNoDelay(true);
            socket.setKeepAlive(props.isTcpKeepAlive());

            if (props.getSocketTimeout() > 0) {
                socket.setSoTimeout(props.getSocketTimeout() * 1000);
            }

            // Connect with timeout
            InetSocketAddress address = new InetSocketAddress(props.getHost(), props.getPort());
            socket.connect(address, props.getConnectTimeout() * 1000);

            // Setup streams
            inputStream = new BufferedInputStream(socket.getInputStream(), 65536);
            outputStream = new BufferedOutputStream(socket.getOutputStream(), 65536);
            dataInput = new DataInputStream(inputStream);
            dataOutput = new DataOutputStream(outputStream);

            // Upgrade to SSL if needed
            String sslMode = props.getSslMode();
            if (sslMode != null && !"disable".equalsIgnoreCase(sslMode)) {
                boolean allowFallback = "allow".equalsIgnoreCase(sslMode) ||
                                        "prefer".equalsIgnoreCase(sslMode);
                upgradeToSSL(allowFallback);
            }

            // Send startup message
            sendStartupMessage();

            // Handle authentication
            handleAuthentication();

            connected = true;

        } catch (IOException e) {
            close();
            throw new SQLException("Failed to connect: " + e.getMessage(), "08001", e);
        }
    }

    /**
     * Sends startup message to server.
     */
    private void sendStartupMessage() throws IOException {
        messageBuffer.reset();

        // Protocol version (4 bytes)
        messageOutput.writeInt((PROTOCOL_VERSION_MAJOR << 16) | PROTOCOL_VERSION_MINOR);

        // Parameters (key=value pairs, null terminated)
        writeString("user");
        writeString(props.getUser() != null ? props.getUser() : "");

        writeString("database");
        writeString(props.getDatabase() != null ? props.getDatabase() : "");

        if (props.getApplicationName() != null) {
            writeString("application_name");
            writeString(props.getApplicationName());
        }

        writeString("client_encoding");
        writeString("UTF8");

        // Terminate parameters list
        messageOutput.writeByte(0);

        // Send message (length prefix + content)
        byte[] message = messageBuffer.toByteArray();
        dataOutput.writeInt(message.length + 4);  // Length includes itself
        dataOutput.write(message);
        dataOutput.flush();
    }

    /**
     * Handles authentication handshake.
     */
    private void handleAuthentication() throws IOException, SQLException {
        while (true) {
            byte type = dataInput.readByte();
            int length = dataInput.readInt() - 4;

            switch (type) {
                case MSG_AUTH_REQUEST:
                    handleAuthRequest(length);
                    break;

                case MSG_AUTH_OK:
                    // Authentication successful
                    break;

                case MSG_PARAMETER_STATUS:
                    handleParameterStatus(length);
                    break;

                case MSG_BACKEND_KEY_DATA:
                    processId = dataInput.readInt();
                    secretKey = dataInput.readInt();
                    break;

                case MSG_READY_FOR_QUERY:
                    dataInput.readByte();  // Transaction status
                    return;  // Authentication complete

                case MSG_ERROR:
                    String error = readErrorMessage(length);
                    throw new SQLException("Authentication failed: " + error, "28000");

                default:
                    // Skip unknown message
                    dataInput.skipBytes(length);
                    break;
            }
        }
    }

    /**
     * Handles authentication request from server.
     */
    private void handleAuthRequest(int length) throws IOException, SQLException {
        int authType = dataInput.readInt();
        length -= 4;

        switch (authType) {
            case 0:  // AuthenticationOk
                break;

            case 3:  // CleartextPassword
                sendPasswordMessage(props.getPassword());
                break;

            case 5:  // MD5Password
                byte[] salt = new byte[4];
                dataInput.readFully(salt);
                String md5Pass = encryptPasswordMD5(props.getPassword(), props.getUser(), salt);
                sendPasswordMessage(md5Pass);
                break;

            case 10:  // SASL
                byte[] mechanisms = new byte[length];
                dataInput.readFully(mechanisms);
                handleSASLAuth(mechanisms);
                break;
            case 11:  // SASLContinue
                byte[] serverFirst = new byte[length];
                dataInput.readFully(serverFirst);
                handleSASLContinue(new String(serverFirst, StandardCharsets.UTF_8));
                break;
            case 12:  // SASLFinal
                byte[] serverFinal = new byte[length];
                dataInput.readFully(serverFinal);
                handleSASLFinal(new String(serverFinal, StandardCharsets.UTF_8));
                break;

            default:
                dataInput.skipBytes(length);
                throw new SQLException("Unsupported authentication type: " + authType, "28000");
        }
    }

    /**
     * Sends password message.
     */
    private void sendPasswordMessage(String password) throws IOException {
        messageBuffer.reset();
        writeString(password != null ? password : "");

        byte[] message = messageBuffer.toByteArray();
        dataOutput.writeByte('p');
        dataOutput.writeInt(message.length + 4);
        dataOutput.write(message);
        dataOutput.flush();
    }

    /**
     * Encrypts password using MD5.
     */
    private String encryptPasswordMD5(String password, String user, byte[] salt) {
        try {
            java.security.MessageDigest md = java.security.MessageDigest.getInstance("MD5");

            // md5(password + user)
            md.update((password != null ? password : "").getBytes(StandardCharsets.UTF_8));
            md.update((user != null ? user : "").getBytes(StandardCharsets.UTF_8));
            byte[] digest1 = md.digest();

            // md5(hex(digest1) + salt)
            md.reset();
            md.update(bytesToHex(digest1).getBytes(StandardCharsets.US_ASCII));
            md.update(salt);
            byte[] digest2 = md.digest();

            return "md5" + bytesToHex(digest2);

        } catch (java.security.NoSuchAlgorithmException e) {
            throw new RuntimeException("MD5 not available", e);
        }
    }

    /**
     * Handles SASL authentication (stub).
     */
    private void handleSASLAuth(byte[] mechanismData) throws IOException, SQLException {
        List<String> mechanisms = new ArrayList<>();
        StringBuilder sb = new StringBuilder();
        for (byte b : mechanismData) {
            if (b == 0) {
                if (sb.length() > 0) {
                    mechanisms.add(sb.toString());
                    sb.setLength(0);
                }
            } else {
                sb.append((char) b);
            }
        }

        String selected = null;
        for (String mech : mechanisms) {
            if ("SCRAM-SHA-256".equalsIgnoreCase(mech)) {
                selected = "SCRAM-SHA-256";
                break;
            }
        }
        if (selected == null) {
            throw new SQLException("SASL SCRAM-SHA-256 not offered by server", "28000");
        }

        scramClient = new SBScramClient(props.getUser());
        String clientFirst = scramClient.getClientFirstMessage();
        sendSaslInitialResponse(selected, clientFirst);
    }

    private void handleSASLContinue(String serverFirst) throws IOException, SQLException {
        if (scramClient == null) {
            throw new SQLException("SCRAM state missing during SASL continue", "28000");
        }
        String clientFinal = scramClient.handleServerFirst(serverFirst, props.getPassword());
        sendSaslResponse(clientFinal);
    }

    private void handleSASLFinal(String serverFinal) throws SQLException {
        if (scramClient == null) {
            throw new SQLException("SCRAM state missing during SASL final", "28000");
        }
        scramClient.verifyServerFinal(serverFinal);
    }

    private void sendSaslInitialResponse(String mechanism, String initialResponse) throws IOException {
        byte[] responseBytes = initialResponse.getBytes(StandardCharsets.UTF_8);
        messageBuffer.reset();
        writeString(mechanism);
        messageOutput.writeInt(responseBytes.length);
        messageOutput.write(responseBytes);

        byte[] message = messageBuffer.toByteArray();
        dataOutput.writeByte('p');
        dataOutput.writeInt(message.length + 4);
        dataOutput.write(message);
        dataOutput.flush();
    }

    private void sendSaslResponse(String response) throws IOException {
        byte[] responseBytes = response.getBytes(StandardCharsets.UTF_8);
        dataOutput.writeByte('p');
        dataOutput.writeInt(responseBytes.length + 4);
        dataOutput.write(responseBytes);
        dataOutput.flush();
    }

    /**
     * Handles parameter status message.
     */
    private void handleParameterStatus(int length) throws IOException {
        String name = readString();
        String value = readString();
        serverParameters.put(name, value);
        LOGGER.log(Level.FINEST, "Server parameter: {0}={1}", new Object[]{name, value});
    }

    /**
     * Reads error message from server.
     */
    private String readErrorMessage(int length) throws IOException {
        StringBuilder sb = new StringBuilder();
        byte[] data = new byte[length];
        dataInput.readFully(data);

        int pos = 0;
        while (pos < data.length) {
            byte field = data[pos++];
            if (field == 0) break;

            int end = pos;
            while (end < data.length && data[end] != 0) end++;
            String value = new String(data, pos, end - pos, StandardCharsets.UTF_8);
            pos = end + 1;

            switch (field) {
                case 'S': sb.append("Severity: ").append(value).append("; "); break;
                case 'C': sb.append("Code: ").append(value).append("; "); break;
                case 'M': sb.append("Message: ").append(value).append("; "); break;
                case 'D': sb.append("Detail: ").append(value).append("; "); break;
                case 'H': sb.append("Hint: ").append(value).append("; "); break;
            }
        }
        return sb.toString();
    }

    /**
     * Executes a simple query.
     *
     * @param sql SQL statement
     * @return query result
     * @throws SQLException if execution fails
     */
    public SBQueryResult execute(String sql) throws SQLException {
        try {
            // Send Query message
            messageBuffer.reset();
            writeString(sql);

            byte[] message = messageBuffer.toByteArray();
            dataOutput.writeByte(MSG_QUERY);
            dataOutput.writeInt(message.length + 4);
            dataOutput.write(message);
            dataOutput.flush();

            // Read response
            return readQueryResult();

        } catch (IOException e) {
            throw new SQLException("Query execution failed: " + e.getMessage(), "08006", e);
        }
    }

    /**
     * Reads query result from server.
     */
    private SBQueryResult readQueryResult() throws IOException, SQLException {
        SBQueryResult result = new SBQueryResult();
        List<SBColumnInfo> columns = new ArrayList<>();
        List<Object[]> rows = new ArrayList<>();

        while (true) {
            byte type = dataInput.readByte();
            int length = dataInput.readInt() - 4;

            switch (type) {
                case MSG_ROW_DESCRIPTION:
                    columns = readRowDescription(length);
                    result.setColumns(columns);
                    break;

                case MSG_DATA_ROW:
                    Object[] row = readDataRow(length, columns);
                    rows.add(row);
                    break;

                case MSG_COMMAND_COMPLETE:
                    String tag = readString();
                    result.setCommandTag(tag);
                    result.setUpdateCount(parseUpdateCount(tag));
                    break;

                case MSG_READY_FOR_QUERY:
                    dataInput.readByte();  // Transaction status
                    result.setRows(rows);
                    return result;

                case MSG_ERROR:
                    String error = readErrorMessage(length);
                    throw new SQLException(error, "42000");

                case MSG_NOTICE:
                    // Just skip notices for now
                    dataInput.skipBytes(length);
                    break;

                case MSG_PARAMETER_STATUS:
                    handleParameterStatus(length);
                    break;

                default:
                    dataInput.skipBytes(length);
                    break;
            }
        }
    }

    /**
     * Reads row description (column metadata).
     */
    private List<SBColumnInfo> readRowDescription(int length) throws IOException {
        int columnCount = dataInput.readShort();
        List<SBColumnInfo> columns = new ArrayList<>(columnCount);

        for (int i = 0; i < columnCount; i++) {
            SBColumnInfo col = new SBColumnInfo();
            col.setName(readString());
            col.setTableOid(dataInput.readInt());
            col.setColumnNumber(dataInput.readShort());
            col.setTypeOid(dataInput.readInt());
            col.setTypeSize(dataInput.readShort());
            col.setTypeModifier(dataInput.readInt());
            col.setFormatCode(dataInput.readShort());
            columns.add(col);
        }
        return columns;
    }

    /**
     * Reads a data row.
     */
    private Object[] readDataRow(int length, List<SBColumnInfo> columns) throws IOException {
        int columnCount = dataInput.readShort();
        Object[] row = new Object[columnCount];

        for (int i = 0; i < columnCount; i++) {
            int valueLength = dataInput.readInt();
            if (valueLength == -1) {
                row[i] = null;  // NULL value
            } else {
                byte[] data = new byte[valueLength];
                dataInput.readFully(data);
                row[i] = parseValue(data, columns.get(i));
            }
        }
        return row;
    }

    /**
     * Parses a value based on column type.
     */
    private Object parseValue(byte[] data, SBColumnInfo column) throws IOException {
        if (column.getFormatCode() == 1) {
            return parseBinaryValue(data, column.getTypeOid());
        }
        return parseTextValue(new String(data, StandardCharsets.UTF_8), column.getTypeOid());
    }

    /**
     * Parses update count from command tag.
     */
    private long parseUpdateCount(String tag) {
        if (tag == null) return 0;
        String[] parts = tag.split(" ");
        if (parts.length >= 2) {
            try {
                return Long.parseLong(parts[parts.length - 1]);
            } catch (NumberFormatException e) {
                // Ignore
            }
        }
        return 0;
    }

    /**
     * Upgrades connection to SSL.
     */
    private void upgradeToSSL(boolean allowFallback) throws IOException, SQLException {
        // Send SSLRequest
        dataOutput.writeInt(8);  // Length
        dataOutput.writeInt(80877103);  // SSL request code
        dataOutput.flush();

        // Read response
        int response = inputStream.read();
        if (response != 'S') {
            if (allowFallback && response == 'N') {
                return;
            }
            throw new SQLException("Server does not support SSL", "08001");
        }

        // Upgrade to SSL socket
        SSLSocketFactory factory = createSslContext().getSocketFactory();
        SSLSocket sslSocket = (SSLSocket) factory.createSocket(
            socket, props.getHost(), props.getPort(), true);
        if ("verify-full".equalsIgnoreCase(props.getSslMode())) {
            SSLParameters params = sslSocket.getSSLParameters();
            params.setEndpointIdentificationAlgorithm("HTTPS");
            sslSocket.setSSLParameters(params);
        }
        sslSocket.startHandshake();

        // Replace streams
        socket = sslSocket;
        inputStream = new BufferedInputStream(socket.getInputStream(), 65536);
        outputStream = new BufferedOutputStream(socket.getOutputStream(), 65536);
        dataInput = new DataInputStream(inputStream);
        dataOutput = new DataOutputStream(outputStream);
    }

    private SSLContext createSslContext() throws SQLException {
        try {
            KeyManager[] keyManagers = null;
            TrustManager[] trustManagers = null;

            if (props.getSslRootCert() != null) {
                trustManagers = buildTrustManagers(props.getSslRootCert());
            }

            if (props.getSslCert() != null) {
                keyManagers = buildKeyManagers(props.getSslCert(), props.getSslPassword());
            }

            SSLContext context = SSLContext.getInstance("TLS");
            context.init(keyManagers, trustManagers, null);
            return context;
        } catch (Exception e) {
            throw new SQLException("Failed to initialize SSL context: " + e.getMessage(), "08001", e);
        }
    }

    private TrustManager[] buildTrustManagers(String caPath) throws Exception {
        java.security.cert.CertificateFactory cf =
            java.security.cert.CertificateFactory.getInstance("X.509");
        java.security.cert.Certificate cert;
        try (InputStream in = new FileInputStream(caPath)) {
            cert = cf.generateCertificate(in);
        }
        KeyStore trustStore = KeyStore.getInstance(KeyStore.getDefaultType());
        trustStore.load(null, null);
        trustStore.setCertificateEntry("ca", cert);
        TrustManagerFactory tmf =
            TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(trustStore);
        return tmf.getTrustManagers();
    }

    private KeyManager[] buildKeyManagers(String keystorePath, String password) throws Exception {
        String lower = keystorePath.toLowerCase();
        String type = (lower.endsWith(".p12") || lower.endsWith(".pfx")) ? "PKCS12" : "JKS";
        KeyStore keyStore = KeyStore.getInstance(type);
        char[] pass = password != null ? password.toCharArray() : new char[0];
        try (InputStream in = new FileInputStream(keystorePath)) {
            keyStore.load(in, pass);
        }
        KeyManagerFactory kmf =
            KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        kmf.init(keyStore, pass);
        return kmf.getKeyManagers();
    }

    private Object parseBinaryValue(byte[] data, int oid) {
        ByteBuffer buf = ByteBuffer.wrap(data).order(ByteOrder.BIG_ENDIAN);
        switch (oid) {
            case 16:  // bool
                return data[0] != 0;
            case 21:  // int2
                return buf.getShort();
            case 23:  // int4
                return buf.getInt();
            case 20:  // int8
                return buf.getLong();
            case 700: // float4
                return buf.getFloat();
            case 701: // float8
                return buf.getDouble();
            case 17:  // bytea
                return data;
            case 2950: // uuid
                long msb = buf.getLong();
                long lsb = buf.getLong();
                return new java.util.UUID(msb, lsb);
            default:
                return new String(data, StandardCharsets.UTF_8);
        }
    }

    private Object parseTextValue(String text, int oid) {
        switch (oid) {
            case 16:   // bool
                return "t".equals(text) || "true".equalsIgnoreCase(text);
            case 21:   // int2
                return Short.parseShort(text);
            case 23:   // int4
                return Integer.parseInt(text);
            case 20:   // int8
                return Long.parseLong(text);
            case 700:  // float4
                return Float.parseFloat(text);
            case 701:  // float8
                return Double.parseDouble(text);
            case 1700: // numeric
                return new java.math.BigDecimal(text);
            case 17:   // bytea
                return decodeBytea(text);
            case 1082: // date
                return java.sql.Date.valueOf(text);
            case 1083: // time
                return java.sql.Time.valueOf(text);
            case 1114: // timestamp
            case 1184: // timestamptz
                return java.sql.Timestamp.valueOf(text.replace('T', ' '));
            case 2950: // uuid
                return java.util.UUID.fromString(text);
            case 869:  // inet
            case 650:  // cidr
                return text;
            case 114:  // json
            case 3802: // jsonb
                return text;
            case 1000: // bool[]
                return buildArray("boolean", text);
            case 1001: // bytea[]
                return buildArray("bytea", text);
            case 1005: // int2[]
                return buildArray("smallint", text);
            case 1007: // int4[]
                return buildArray("integer", text);
            case 1016: // int8[]
                return buildArray("bigint", text);
            case 1021: // float4[]
                return buildArray("real", text);
            case 1022: // float8[]
                return buildArray("double precision", text);
            case 1009: // text[]
            case 1015: // varchar[]
                return buildArray("text", text);
            case 1182: // date[]
                return buildArray("date", text);
            case 1115: // timestamp[]
            case 1185: // timestamptz[]
                return buildArray("timestamp", text);
            case 2951: // uuid[]
                return buildArray("uuid", text);
            default:
                return text;
        }
    }

    private SBArray buildArray(String baseType, String literal) {
        Object[] elements = parseArrayLiteral(literal);
        Object[] converted = convertArrayElements(baseType, elements);
        return new SBArray(baseType, converted);
    }

    private Object[] parseArrayLiteral(String literal) {
        if (literal == null) {
            return new Object[0];
        }
        String trimmed = literal.trim();
        if (trimmed.equals("{}")) {
            return new Object[0];
        }
        if (!trimmed.startsWith("{") || !trimmed.endsWith("}")) {
            return new Object[]{trimmed};
        }
        ParseResult result = parseArray(trimmed, 0);
        return result.items.toArray(new Object[0]);
    }

    private static class ParseResult {
        final List<Object> items;
        final int nextIdx;

        ParseResult(List<Object> items, int nextIdx) {
            this.items = items;
            this.nextIdx = nextIdx;
        }
    }

    private ParseResult parseArray(String text, int start) {
        List<Object> items = new ArrayList<>();
        StringBuilder token = new StringBuilder();
        boolean inQuotes = false;
        boolean tokenActive = false;
        boolean tokenQuoted = false;
        int i = start + 1;

        while (i < text.length()) {
            char ch = text.charAt(i);
            if (inQuotes) {
                if (ch == '\\' && i + 1 < text.length()) {
                    token.append(text.charAt(i + 1));
                    i += 2;
                    continue;
                }
                if (ch == '"') {
                    inQuotes = false;
                    tokenQuoted = true;
                    i++;
                    continue;
                }
                token.append(ch);
                tokenActive = true;
                i++;
                continue;
            }

            if (ch == '"') {
                inQuotes = true;
                tokenActive = true;
                i++;
                continue;
            }
            if (ch == '{') {
                ParseResult nested = parseArray(text, i);
                items.add(nested.items.toArray(new Object[0]));
                i = nested.nextIdx;
                tokenActive = false;
                tokenQuoted = false;
                token.setLength(0);
                continue;
            }
            if (ch == '}') {
                if (tokenActive || tokenQuoted) {
                    items.add(parseArrayToken(token.toString(), tokenQuoted));
                }
                return new ParseResult(items, i + 1);
            }
            if (ch == ',') {
                if (tokenActive || tokenQuoted) {
                    items.add(parseArrayToken(token.toString(), tokenQuoted));
                } else {
                    items.add("");
                }
                token.setLength(0);
                tokenActive = false;
                tokenQuoted = false;
                i++;
                continue;
            }
            if (!Character.isWhitespace(ch) || tokenActive) {
                token.append(ch);
                tokenActive = true;
            }
            i++;
        }
        return new ParseResult(items, text.length());
    }

    private Object parseArrayToken(String token, boolean quoted) {
        String value = token;
        if (!quoted) {
            String upper = value.trim();
            if ("NULL".equalsIgnoreCase(upper)) {
                return null;
            }
        }
        return quoted ? value : value.trim();
    }

    private Object[] convertArrayElements(String baseType, Object[] elements) {
        Object[] converted = new Object[elements.length];
        for (int i = 0; i < elements.length; i++) {
            Object element = elements[i];
            if (element instanceof Object[]) {
                converted[i] = convertArrayElements(baseType, (Object[]) element);
                continue;
            }
            if (element == null) {
                converted[i] = null;
                continue;
            }
            String text = element.toString();
            converted[i] = convertElement(baseType, text);
        }
        return converted;
    }

    private Object convertElement(String baseType, String text) {
        if (text == null) {
            return null;
        }
        String lower = baseType.toLowerCase();
        switch (lower) {
            case "boolean":
                return "t".equalsIgnoreCase(text) || "true".equalsIgnoreCase(text);
            case "smallint":
                return Short.parseShort(text);
            case "integer":
                return Integer.parseInt(text);
            case "bigint":
                return Long.parseLong(text);
            case "real":
                return Float.parseFloat(text);
            case "double precision":
                return Double.parseDouble(text);
            case "numeric":
                return new java.math.BigDecimal(text);
            case "bytea":
                return decodeBytea(text);
            case "date":
                return java.sql.Date.valueOf(text);
            case "time":
                return java.sql.Time.valueOf(text);
            case "timestamp":
                return java.sql.Timestamp.valueOf(text.replace('T', ' '));
            case "uuid":
                return java.util.UUID.fromString(text);
            default:
                return text;
        }
    }

    private byte[] decodeBytea(String text) {
        if (text == null) {
            return null;
        }
        if (text.startsWith("\\x") || text.startsWith("0x")) {
            String hex = text.startsWith("\\x") ? text.substring(2) : text.substring(2);
            int len = hex.length();
            byte[] out = new byte[len / 2];
            for (int i = 0; i < out.length; i++) {
                out[i] = (byte) Integer.parseInt(hex.substring(i * 2, i * 2 + 2), 16);
            }
            return out;
        }
        return text.getBytes(StandardCharsets.UTF_8);
    }

    /**
     * Cancels current query.
     */
    public void cancelCurrentQuery() throws SQLException {
        if (!connected) return;

        try {
            // Send cancel on a new connection
            Socket cancelSocket = new Socket();
            cancelSocket.connect(new InetSocketAddress(props.getHost(), props.getPort()),
                props.getConnectTimeout() * 1000);

            DataOutputStream out = new DataOutputStream(cancelSocket.getOutputStream());
            out.writeInt(16);  // Length
            out.writeInt(80877102);  // Cancel request code
            out.writeInt(processId);
            out.writeInt(secretKey);
            out.flush();
            cancelSocket.close();

        } catch (IOException e) {
            throw new SQLException("Failed to cancel query: " + e.getMessage(), "08006", e);
        }
    }

    /**
     * Checks if connection is alive.
     */
    public boolean isAlive(int timeout) {
        if (!connected || socket == null || socket.isClosed()) {
            return false;
        }
        try {
            int oldTimeout = socket.getSoTimeout();
            socket.setSoTimeout(timeout * 1000);
            try {
                // Send a sync and wait for response
                dataOutput.writeByte(MSG_SYNC);
                dataOutput.writeInt(4);
                dataOutput.flush();

                byte type = dataInput.readByte();
                dataInput.readInt();  // length
                if (type == MSG_READY_FOR_QUERY) {
                    dataInput.readByte();  // status
                    return true;
                }
            } finally {
                socket.setSoTimeout(oldTimeout);
            }
        } catch (IOException e) {
            return false;
        }
        return false;
    }

    /**
     * Aborts the connection.
     */
    public void abort() {
        try {
            if (socket != null) {
                socket.close();
            }
        } catch (IOException e) {
            // Ignore
        }
        connected = false;
    }

    /**
     * Closes the connection.
     */
    public void close() {
        if (connected) {
            try {
                // Send terminate message
                dataOutput.writeByte(MSG_TERMINATE);
                dataOutput.writeInt(4);
                dataOutput.flush();
            } catch (IOException e) {
                // Ignore
            }
        }

        try {
            if (socket != null) socket.close();
        } catch (IOException e) {
            // Ignore
        }

        connected = false;
    }

    /**
     * Sets network timeout.
     */
    public void setNetworkTimeout(int milliseconds) {
        this.networkTimeout = milliseconds;
        try {
            if (socket != null) {
                socket.setSoTimeout(milliseconds);
            }
        } catch (IOException e) {
            // Ignore
        }
    }

    /**
     * Gets network timeout.
     */
    public int getNetworkTimeout() {
        return networkTimeout;
    }

    /**
     * Gets a server parameter.
     */
    public String getServerParameter(String name) {
        return serverParameters.get(name);
    }

    // ==================== Helper Methods ====================

    private void writeString(String s) throws IOException {
        if (s != null) {
            messageOutput.write(s.getBytes(StandardCharsets.UTF_8));
        }
        messageOutput.writeByte(0);  // Null terminator
    }

    private String readString() throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        int b;
        while ((b = dataInput.read()) > 0) {
            baos.write(b);
        }
        return baos.toString("UTF-8");
    }

    private static String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b & 0xff));
        }
        return sb.toString();
    }
}
