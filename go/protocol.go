package scratchbird

import (
	"encoding/binary"
	"errors"
	"io"
)

const (
	protocolMagic = 0x53425750 // SBWP
	protocolMajor = 1
	protocolMinor = 1
	protocolVer   = (protocolMajor << 8) | protocolMinor
	headerSize    = 40
	maxMessageSize = 1024 * 1024 * 1024
)

type messageType byte

const (
	msgStartup     messageType = 0x01
	msgAuthResponse messageType = 0x02
	msgQuery       messageType = 0x03
	msgParse       messageType = 0x04
	msgBind        messageType = 0x05
	msgDescribe    messageType = 0x06
	msgExecute     messageType = 0x07
	msgClose       messageType = 0x08
	msgSync        messageType = 0x09
	msgFlush       messageType = 0x0A
	msgCancel      messageType = 0x0B
	msgCopyData    messageType = 0x0D
	msgCopyDone    messageType = 0x0E
	msgCopyFail    messageType = 0x0F

	msgAuthRequest       messageType = 0x40
	msgAuthOk            messageType = 0x41
	msgAuthContinue      messageType = 0x42
	msgReady             messageType = 0x43
	msgRowDescription    messageType = 0x44
	msgDataRow           messageType = 0x45
	msgCommandComplete   messageType = 0x46
	msgEmptyQuery        messageType = 0x47
	msgError             messageType = 0x48
	msgNotice            messageType = 0x49
	msgParseComplete     messageType = 0x4A
	msgBindComplete      messageType = 0x4B
	msgCloseComplete     messageType = 0x4C
	msgPortalSuspended   messageType = 0x4D
	msgNoData            messageType = 0x4E
	msgParameterStatus   messageType = 0x4F
	msgParameterDescription messageType = 0x50
	msgCopyInResponse    messageType = 0x51
	msgCopyOutResponse   messageType = 0x52
	msgCopyBothResponse  messageType = 0x53
	msgNotification      messageType = 0x54
	msgNegotiateVersion  messageType = 0x56
	msgStreamReady       messageType = 0x59
	msgStreamData        messageType = 0x5A
	msgStreamEnd         messageType = 0x5B
	msgTxnStatus         messageType = 0x5C
	msgPong              messageType = 0x5D
)

const (
	msgFlagCompressed = 0x01
	msgFlagContinued  = 0x02
	msgFlagFinal      = 0x04
	msgFlagUrgent     = 0x08
	msgFlagEncrypted  = 0x10
	msgFlagChecksum   = 0x20
)

const (
	featureCompression   uint64 = 1 << 0
	featureStreaming     uint64 = 1 << 1
	featureSBLR          uint64 = 1 << 2
	featureFederation    uint64 = 1 << 3
	featureNotifications uint64 = 1 << 4
	featureQueryPlan     uint64 = 1 << 5
	featureBatch         uint64 = 1 << 6
	featurePipeline      uint64 = 1 << 7
	featureBinaryCopy    uint64 = 1 << 8
	featureSavepoints    uint64 = 1 << 9
	feature2PC           uint64 = 1 << 10
	featureChecksums     uint64 = 1 << 11
)

type authMethod byte

const (
	authOK            authMethod = 0
	authPassword      authMethod = 1
	authMD5           authMethod = 2
	authScramSha256   authMethod = 3
	authCertificate   authMethod = 4
	authGSSAPI        authMethod = 5
	authSSPI          authMethod = 6
	authLDAP          authMethod = 7
	authSAML          authMethod = 8
	authOIDC          authMethod = 9
	authMFATOTP       authMethod = 10
	authClusterPKI    authMethod = 11
)

type messageHeader struct {
	typ          messageType
	flags        byte
	length       uint32
	sequence     uint32
	attachmentID [16]byte
	txnID        uint64
}

type protocolMessage struct {
	header messageHeader
	body   []byte
}

type columnInfo struct {
	name         string
	tableOID     uint32
	columnIndex  uint16
	typeOID      uint32
	typeSize     int16
	typeModifier int32
	format       uint8
	nullable     bool
}

type columnValue struct {
	data []byte
	null bool
}

func encodeMessage(header messageHeader, payload []byte) []byte {
	buf := make([]byte, headerSize+len(payload))
	binary.LittleEndian.PutUint32(buf[0:4], protocolMagic)
	buf[4] = protocolMajor
	buf[5] = protocolMinor
	buf[6] = byte(header.typ)
	buf[7] = header.flags
	binary.LittleEndian.PutUint32(buf[8:12], uint32(len(payload)))
	binary.LittleEndian.PutUint32(buf[12:16], header.sequence)
	copy(buf[16:32], header.attachmentID[:])
	binary.LittleEndian.PutUint64(buf[32:40], header.txnID)
	copy(buf[40:], payload)
	return buf
}

func decodeHeader(header []byte) (messageHeader, error) {
	if len(header) != headerSize {
		return messageHeader{}, errors.New("invalid header length")
	}
	magic := binary.LittleEndian.Uint32(header[0:4])
	if magic != protocolMagic {
		return messageHeader{}, errors.New("invalid protocol magic")
	}
	major := header[4]
	minor := header[5]
	if major != protocolMajor || minor != protocolMinor {
		return messageHeader{}, errors.New("unsupported protocol version")
	}
	length := binary.LittleEndian.Uint32(header[8:12])
	if length > maxMessageSize {
		return messageHeader{}, errors.New("payload too large")
	}
	var attachment [16]byte
	copy(attachment[:], header[16:32])
	return messageHeader{
		typ:          messageType(header[6]),
		flags:        header[7],
		length:       length,
		sequence:     binary.LittleEndian.Uint32(header[12:16]),
		attachmentID: attachment,
		txnID:        binary.LittleEndian.Uint64(header[32:40]),
	}, nil
}

func readMessage(r io.Reader) (protocolMessage, error) {
	headerBytes := make([]byte, headerSize)
	if _, err := io.ReadFull(r, headerBytes); err != nil {
		return protocolMessage{}, err
	}
	header, err := decodeHeader(headerBytes)
	if err != nil {
		return protocolMessage{}, err
	}
	body := make([]byte, header.length)
	if header.length > 0 {
		if _, err := io.ReadFull(r, body); err != nil {
			return protocolMessage{}, err
		}
	}
	return protocolMessage{header: header, body: body}, nil
}

func buildStartupPayload(features uint64, params map[string]string) []byte {
	paramBytes := buildParamList(params)
	payload := make([]byte, 2+2+8+len(paramBytes))
	payload[0] = protocolMajor
	payload[1] = protocolMinor
	binary.LittleEndian.PutUint16(payload[2:4], 0)
	binary.LittleEndian.PutUint64(payload[4:12], features)
	copy(payload[12:], paramBytes)
	return payload
}

func buildParamList(params map[string]string) []byte {
	buf := make([]byte, 0, 128)
	for key, value := range params {
		buf = append(buf, []byte(key)...)
		buf = append(buf, 0)
		buf = append(buf, []byte(value)...)
		buf = append(buf, 0)
	}
	buf = append(buf, 0)
	return buf
}

func parseAuthRequest(payload []byte) (authMethod, []byte, error) {
	if len(payload) < 4 {
		return 0, nil, errors.New("auth request truncated")
	}
	method := authMethod(payload[0])
	return method, append([]byte{}, payload[4:]...), nil
}

func parseAuthContinue(payload []byte) (authMethod, byte, []byte, error) {
	if len(payload) < 8 {
		return 0, 0, nil, errors.New("auth continue truncated")
	}
	method := authMethod(payload[0])
	stage := payload[1]
	dataLen := binary.LittleEndian.Uint32(payload[4:8])
	if int(8+dataLen) > len(payload) {
		return 0, 0, nil, errors.New("auth continue truncated")
	}
	data := append([]byte{}, payload[8:8+dataLen]...)
	return method, stage, data, nil
}

func parseAuthOk(payload []byte) ([]byte, []byte, error) {
	if len(payload) < 16+4 {
		return nil, nil, errors.New("auth ok truncated")
	}
	sessionID := append([]byte{}, payload[:16]...)
	infoLen := binary.LittleEndian.Uint32(payload[16:20])
	if int(20+infoLen) > len(payload) {
		return nil, nil, errors.New("auth ok truncated")
	}
	info := append([]byte{}, payload[20:20+infoLen]...)
	return sessionID, info, nil
}

func buildQueryPayload(query string, flags uint32, maxRows uint32, timeoutMs uint32) []byte {
	queryBytes := append([]byte(query), 0)
	payload := make([]byte, 4+4+4+len(queryBytes))
	binary.LittleEndian.PutUint32(payload[0:4], flags)
	binary.LittleEndian.PutUint32(payload[4:8], maxRows)
	binary.LittleEndian.PutUint32(payload[8:12], timeoutMs)
	copy(payload[12:], queryBytes)
	return payload
}

func buildParsePayload(statementName, query string, paramTypes []uint32) []byte {
	nameBytes := []byte(statementName)
	queryBytes := []byte(query)
	payloadLen := 4 + len(nameBytes) + 4 + len(queryBytes) + 2 + 2 + len(paramTypes)*4
	payload := make([]byte, payloadLen)
	offset := 0
	binary.LittleEndian.PutUint32(payload[offset:offset+4], uint32(len(nameBytes)))
	offset += 4
	copy(payload[offset:offset+len(nameBytes)], nameBytes)
	offset += len(nameBytes)
	binary.LittleEndian.PutUint32(payload[offset:offset+4], uint32(len(queryBytes)))
	offset += 4
	copy(payload[offset:offset+len(queryBytes)], queryBytes)
	offset += len(queryBytes)
	binary.LittleEndian.PutUint16(payload[offset:offset+2], uint16(len(paramTypes)))
	offset += 2
	binary.LittleEndian.PutUint16(payload[offset:offset+2], 0)
	offset += 2
	for _, oid := range paramTypes {
		binary.LittleEndian.PutUint32(payload[offset:offset+4], oid)
		offset += 4
	}
	return payload
}

type paramValue struct {
	format uint16
	data   []byte
	null   bool
}

func buildBindPayload(portalName, statementName string, params []paramValue, resultFormats []uint16) []byte {
	portalBytes := []byte(portalName)
	stmtBytes := []byte(statementName)
	paramFormats := make([]uint16, len(params))
	for i, param := range params {
		paramFormats[i] = param.format
	}
	payloadLen := 4 + len(portalBytes) + 4 + len(stmtBytes)
	payloadLen += 2 + len(paramFormats)*2
	payloadLen += 2 + 2
	for _, param := range params {
		payloadLen += 4
		if !param.null {
			payloadLen += len(param.data)
		}
	}
	payloadLen += 2 + len(resultFormats)*2

	payload := make([]byte, payloadLen)
	offset := 0
	binary.LittleEndian.PutUint32(payload[offset:offset+4], uint32(len(portalBytes)))
	offset += 4
	copy(payload[offset:offset+len(portalBytes)], portalBytes)
	offset += len(portalBytes)
	binary.LittleEndian.PutUint32(payload[offset:offset+4], uint32(len(stmtBytes)))
	offset += 4
	copy(payload[offset:offset+len(stmtBytes)], stmtBytes)
	offset += len(stmtBytes)
	binary.LittleEndian.PutUint16(payload[offset:offset+2], uint16(len(paramFormats)))
	offset += 2
	for _, fmtCode := range paramFormats {
		binary.LittleEndian.PutUint16(payload[offset:offset+2], fmtCode)
		offset += 2
	}
	binary.LittleEndian.PutUint16(payload[offset:offset+2], uint16(len(params)))
	offset += 2
	binary.LittleEndian.PutUint16(payload[offset:offset+2], 0)
	offset += 2
	for _, param := range params {
		if param.null {
			binary.LittleEndian.PutUint32(payload[offset:offset+4], ^uint32(0))
			offset += 4
			continue
		}
		binary.LittleEndian.PutUint32(payload[offset:offset+4], uint32(len(param.data)))
		offset += 4
		copy(payload[offset:offset+len(param.data)], param.data)
		offset += len(param.data)
	}
	binary.LittleEndian.PutUint16(payload[offset:offset+2], uint16(len(resultFormats)))
	offset += 2
	for _, fmtCode := range resultFormats {
		binary.LittleEndian.PutUint16(payload[offset:offset+2], fmtCode)
		offset += 2
	}
	return payload
}

func buildDescribePayload(describeType byte, name string) []byte {
	nameBytes := []byte(name)
	payload := make([]byte, 4+4+len(nameBytes))
	payload[0] = describeType
	binary.LittleEndian.PutUint32(payload[4:8], uint32(len(nameBytes)))
	copy(payload[8:], nameBytes)
	return payload
}

func buildExecutePayload(portalName string, maxRows uint32) []byte {
	portalBytes := []byte(portalName)
	payload := make([]byte, 4+len(portalBytes)+4)
	binary.LittleEndian.PutUint32(payload[0:4], uint32(len(portalBytes)))
	copy(payload[4:4+len(portalBytes)], portalBytes)
	binary.LittleEndian.PutUint32(payload[4+len(portalBytes):], maxRows)
	return payload
}

func buildClosePayload(closeType byte, name string) []byte {
	nameBytes := []byte(name)
	payload := make([]byte, 4+4+len(nameBytes))
	payload[0] = closeType
	binary.LittleEndian.PutUint32(payload[4:8], uint32(len(nameBytes)))
	copy(payload[8:], nameBytes)
	return payload
}

func buildCancelPayload(cancelType uint32, targetSeq uint32) []byte {
	payload := make([]byte, 8)
	binary.LittleEndian.PutUint32(payload[0:4], cancelType)
	binary.LittleEndian.PutUint32(payload[4:8], targetSeq)
	return payload
}

func parseReady(payload []byte) (byte, uint64, uint64, error) {
	if len(payload) < 1+3+8+8 {
		return 0, 0, 0, errors.New("ready truncated")
	}
	status := payload[0]
	txnID := binary.LittleEndian.Uint64(payload[4:12])
	epoch := binary.LittleEndian.Uint64(payload[12:20])
	return status, txnID, epoch, nil
}

func parseParameterStatus(payload []byte) (string, string, error) {
	if len(payload) < 8 {
		return "", "", errors.New("parameter status truncated")
	}
	offset := 0
	nameLen := int(binary.LittleEndian.Uint32(payload[offset : offset+4]))
	offset += 4
	if offset+nameLen+4 > len(payload) {
		return "", "", errors.New("parameter status truncated")
	}
	name := string(payload[offset : offset+nameLen])
	offset += nameLen
	valueLen := int(binary.LittleEndian.Uint32(payload[offset : offset+4]))
	offset += 4
	if offset+valueLen > len(payload) {
		return "", "", errors.New("parameter status truncated")
	}
	value := string(payload[offset : offset+valueLen])
	return name, value, nil
}

func parseParameterDescription(payload []byte) ([]uint32, error) {
	if len(payload) < 4 {
		return nil, errors.New("parameter description truncated")
	}
	num := int(binary.LittleEndian.Uint16(payload[:2]))
	pos := 4
	types := make([]uint32, 0, num)
	for i := 0; i < num; i++ {
		if len(payload) < pos+4 {
			return nil, errors.New("parameter description truncated")
		}
		types = append(types, binary.LittleEndian.Uint32(payload[pos:pos+4]))
		pos += 4
	}
	return types, nil
}

func parseRowDescription(payload []byte) ([]columnInfo, error) {
	if len(payload) < 4 {
		return nil, errors.New("row description truncated")
	}
	offset := 0
	count := int(binary.LittleEndian.Uint16(payload[offset : offset+2]))
	offset += 4
	cols := make([]columnInfo, 0, count)
	for i := 0; i < count; i++ {
		if offset+4 > len(payload) {
			return nil, errors.New("row description truncated")
		}
		nameLen := int(binary.LittleEndian.Uint32(payload[offset : offset+4]))
		offset += 4
		if offset+nameLen+4+2+4+2+4+1+1+2 > len(payload) {
			return nil, errors.New("row description truncated")
		}
		name := string(payload[offset : offset+nameLen])
		offset += nameLen
		tableOID := binary.LittleEndian.Uint32(payload[offset : offset+4])
		offset += 4
		columnIndex := binary.LittleEndian.Uint16(payload[offset : offset+2])
		offset += 2
		typeOID := binary.LittleEndian.Uint32(payload[offset : offset+4])
		offset += 4
		typeSize := int16(binary.LittleEndian.Uint16(payload[offset : offset+2]))
		offset += 2
		typeModifier := int32(binary.LittleEndian.Uint32(payload[offset : offset+4]))
		offset += 4
		format := payload[offset]
		offset++
		nullable := payload[offset] == 1
		offset++
		offset += 2
		cols = append(cols, columnInfo{
			name:         name,
			tableOID:     tableOID,
			columnIndex:  columnIndex,
			typeOID:      typeOID,
			typeSize:     typeSize,
			typeModifier: typeModifier,
			format:       format,
			nullable:     nullable,
		})
	}
	return cols, nil
}

func parseDataRow(payload []byte, columnCount int) ([]columnValue, error) {
	if len(payload) < 4 {
		return nil, errors.New("row data truncated")
	}
	offset := 0
	count := int(binary.LittleEndian.Uint16(payload[offset : offset+2]))
	offset += 2
	nullBytes := int(binary.LittleEndian.Uint16(payload[offset : offset+2]))
	offset += 2
	if count != columnCount {
		return nil, errors.New("row data column count mismatch")
	}
	if offset+nullBytes > len(payload) {
		return nil, errors.New("row data truncated")
	}
	nullBitmap := payload[offset : offset+nullBytes]
	offset += nullBytes
	values := make([]columnValue, 0, count)
	for i := 0; i < count; i++ {
		byteIndex := i / 8
		bitIndex := uint(i % 8)
		isNull := byteIndex < len(nullBitmap) && (nullBitmap[byteIndex]&(1<<bitIndex)) != 0
		if isNull {
			values = append(values, columnValue{null: true})
			continue
		}
		if offset+4 > len(payload) {
			return nil, errors.New("row data truncated")
		}
		length := int(int32(binary.LittleEndian.Uint32(payload[offset : offset+4])))
		offset += 4
		if length < 0 {
			values = append(values, columnValue{null: true})
			continue
		}
		if offset+length > len(payload) {
			return nil, errors.New("row data truncated")
		}
		data := append([]byte{}, payload[offset:offset+length]...)
		offset += length
		values = append(values, columnValue{data: data})
	}
	return values, nil
}

func parseCommandComplete(payload []byte) (byte, uint64, uint64, string, error) {
	if len(payload) < 4+8+8 {
		return 0, 0, 0, "", errors.New("command complete truncated")
	}
	commandType := payload[0]
	rows := binary.LittleEndian.Uint64(payload[4:12])
	lastID := binary.LittleEndian.Uint64(payload[12:20])
	tagBytes := payload[20:]
	tag := string(tagBytes)
	for i, ch := range tagBytes {
		if ch == 0 {
			tag = string(tagBytes[:i])
			break
		}
	}
	return commandType, rows, lastID, tag, nil
}

func parseErrorMessage(payload []byte) (string, string, string, string, string, error) {
	var severity, sqlState, msg, detail, hint string
	offset := 0
	for offset < len(payload) {
		field := payload[offset]
		offset++
		if field == 0 {
			break
		}
		start := offset
		for offset < len(payload) && payload[offset] != 0 {
			offset++
		}
		if offset >= len(payload) {
			return "", "", "", "", "", errors.New("error message truncated")
		}
		value := string(payload[start:offset])
		offset++
		switch field {
		case 'S':
			severity = value
		case 'C':
			sqlState = value
		case 'M':
			msg = value
		case 'D':
			detail = value
		case 'H':
			hint = value
		}
	}
	return severity, sqlState, msg, detail, hint, nil
}
