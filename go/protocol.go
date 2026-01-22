package scratchbird

import (
	"encoding/binary"
	"errors"
	"io"
)

const (
	protocolMagic  = 0x42444253
	protocolMajor  = 1
	protocolMinor  = 0
	protocolVer    = (protocolMajor << 8) | protocolMinor
	maxMessageSize = 16 * 1024 * 1024
)

type messageType byte

const (
	msgConnectRequest  messageType = 0x01
	msgConnectResponse messageType = 0x02
	msgDisconnect      messageType = 0x03
	msgAuthRequest     messageType = 0x10
	msgAuthResponse    messageType = 0x11
	msgQuery           messageType = 0x20
	msgQueryResult     messageType = 0x21
	msgQueryError      messageType = 0x22
	msgQueryCancel     messageType = 0x23
	msgPrepare         messageType = 0x30
	msgPrepareResp     messageType = 0x31
	msgExecute         messageType = 0x32
	msgCloseStatement  messageType = 0x33
	msgDescribe        messageType = 0x34
	msgDescribeResp    messageType = 0x35
	msgBegin           messageType = 0x40
	msgCommit          messageType = 0x41
	msgRollback        messageType = 0x42
	msgRowDescription  messageType = 0x50
	msgRowData         messageType = 0x51
	msgEndResults      messageType = 0x52
	msgCommandComplete messageType = 0x53
)

type authMethod byte

const (
	authPassword    authMethod = 0
	authMD5         authMethod = 1
	authScramSha256 authMethod = 2
	authScramSha512 authMethod = 3
)

type authStatus byte

const (
	authOK       authStatus = 0
	authError    authStatus = 1
	authContinue authStatus = 2
)

type wireType byte

const (
	wireNullType wireType = 0x00
	wireBool     wireType = 0x01
	wireInt16    wireType = 0x02
	wireInt32    wireType = 0x03
	wireInt64    wireType = 0x04
	wireFloat32  wireType = 0x05
	wireFloat64  wireType = 0x06
	wireDecimal  wireType = 0x07
	wireVarchar  wireType = 0x08
	wireChar     wireType = 0x09
	wireBytea    wireType = 0x0A
	wireDate     wireType = 0x0B
	wireTime     wireType = 0x0C
	wireTimestamp wireType = 0x0D
	wireTimestamptz wireType = 0x0E
	wireInterval wireType = 0x0F
	wireUUID     wireType = 0x10
	wireJSON     wireType = 0x11
	wireJSONB    wireType = 0x12
	wireArray    wireType = 0x13
	wireComposite wireType = 0x14
	wireGeometry wireType = 0x15
	wireVector   wireType = 0x16
	wireMoney    wireType = 0x17
	wireXML      wireType = 0x18
	wireInet     wireType = 0x19
	wireCidr     wireType = 0x1A
	wireMacaddr  wireType = 0x1B
	wireTsvector wireType = 0x1C
	wireTsquery  wireType = 0x1D
	wireRange    wireType = 0x1E
	wireUnknown  wireType = 0xFF
)

type columnInfo struct {
	name         string
	wireType     wireType
	typeModifier uint32
	formatCode   uint16
}

type columnValue struct {
	data []byte
	null bool
}

type protocolMessage struct {
	typ   messageType
	flags byte
	body  []byte
}

func encodeMessage(typ messageType, payload []byte, flags byte) []byte {
	buf := make([]byte, 12+len(payload))
	binary.LittleEndian.PutUint32(buf[0:4], protocolMagic)
	binary.LittleEndian.PutUint16(buf[4:6], uint16(protocolVer))
	buf[6] = byte(typ)
	buf[7] = flags
	binary.LittleEndian.PutUint32(buf[8:12], uint32(len(payload)))
	copy(buf[12:], payload)
	return buf
}

func decodeHeader(header []byte) (messageType, byte, int, error) {
	if len(header) != 12 {
		return 0, 0, 0, errors.New("invalid header length")
	}
	magic := binary.LittleEndian.Uint32(header[0:4])
	if magic != protocolMagic {
		return 0, 0, 0, errors.New("invalid protocol magic")
	}
	length := int(binary.LittleEndian.Uint32(header[8:12]))
	if length > maxMessageSize {
		return 0, 0, 0, errors.New("payload too large")
	}
	return messageType(header[6]), header[7], length, nil
}

func readMessage(r io.Reader) (protocolMessage, error) {
	header := make([]byte, 12)
	if _, err := io.ReadFull(r, header); err != nil {
		return protocolMessage{}, err
	}
	typ, flags, length, err := decodeHeader(header)
	if err != nil {
		return protocolMessage{}, err
	}
	body := make([]byte, length)
	if length > 0 {
		if _, err := io.ReadFull(r, body); err != nil {
			return protocolMessage{}, err
		}
	}
	return protocolMessage{typ: typ, flags: flags, body: body}, nil
}

func buildConnectRequest(database, clientName string, pid uint32) []byte {
	payload := make([]byte, 2+2+4+256+64+32)
	binary.LittleEndian.PutUint16(payload[0:2], uint16(protocolVer))
	binary.LittleEndian.PutUint16(payload[2:4], 0)
	binary.LittleEndian.PutUint32(payload[4:8], pid)
	writeNullTerminated(payload[8:8+256], database)
	writeNullTerminated(payload[8+256:8+256+64], clientName)
	writeNullTerminated(payload[8+256+64:8+256+64+32], "1.0.0")
	return encodeMessage(msgConnectRequest, payload, 0)
}

func parseConnectResponse(payload []byte) (ok bool, sessionID []byte, version uint16, serverName, serverVersion, errMsg string, err error) {
	if len(payload) < 1+2+2+16+64+32 {
		return false, nil, 0, "", "", "", errors.New("connect response truncated")
	}
	offset := 0
	status := payload[offset]
	offset++
	version = binary.LittleEndian.Uint16(payload[offset : offset+2])
	offset += 2
	offset += 2
	sessionID = append([]byte{}, payload[offset:offset+16]...)
	offset += 16
	serverName = readNullTerminated(payload[offset : offset+64])
	offset += 64
	serverVersion = readNullTerminated(payload[offset : offset+32])
	offset += 32
	if status != 0 && offset+2 <= len(payload) {
		msgLen := int(binary.LittleEndian.Uint16(payload[offset : offset+2]))
		offset += 2
		if offset+msgLen <= len(payload) {
			errMsg = string(payload[offset : offset+msgLen])
		}
	}
	return status == 0, sessionID, version, serverName, serverVersion, errMsg, nil
}

func buildAuthRequest(sessionID []byte, username string, method authMethod, payload []byte) ([]byte, error) {
	if len(sessionID) != 16 {
		return nil, errors.New("sessionId must be 16 bytes")
	}
	buf := make([]byte, 16+64+1+2+len(payload))
	copy(buf[0:16], sessionID)
	writeNullTerminated(buf[16:16+64], username)
	buf[16+64] = byte(method)
	binary.LittleEndian.PutUint16(buf[16+64+1:16+64+3], uint16(len(payload)))
	copy(buf[16+64+3:], payload)
	return encodeMessage(msgAuthRequest, buf, 0), nil
}

func parseAuthResponse(payload []byte) (authStatus, uint32, string, []byte, error) {
	if len(payload) < 1+4+256 {
		return 0, 0, "", nil, errors.New("auth response truncated")
	}
	status := authStatus(payload[0])
	userID := binary.LittleEndian.Uint32(payload[1:5])
	errMsg := readNullTerminated(payload[5 : 5+256])
	extra := append([]byte{}, payload[5+256:]...)
	return status, userID, errMsg, extra, nil
}

func buildQuery(sessionID []byte, sql string, flags byte) ([]byte, error) {
	if len(sessionID) != 16 {
		return nil, errors.New("sessionId must be 16 bytes")
	}
	sqlBytes := []byte(sql)
	payload := make([]byte, 16+4+1+len(sqlBytes))
	copy(payload[0:16], sessionID)
	binary.LittleEndian.PutUint32(payload[16:20], uint32(len(sqlBytes)))
	payload[20] = flags
	copy(payload[21:], sqlBytes)
	return encodeMessage(msgQuery, payload, 0), nil
}

func parseRowDescription(payload []byte) ([]columnInfo, error) {
	if len(payload) < 2 {
		return nil, errors.New("row description truncated")
	}
	offset := 0
	count := int(binary.LittleEndian.Uint16(payload[offset : offset+2]))
	offset += 2
	cols := make([]columnInfo, 0, count)
	for i := 0; i < count; i++ {
		if offset+2 > len(payload) {
			return nil, errors.New("row description truncated")
		}
		nameLen := int(binary.LittleEndian.Uint16(payload[offset : offset+2]))
		offset += 2
		if offset+nameLen+1+4+2 > len(payload) {
			return nil, errors.New("row description truncated")
		}
		name := string(payload[offset : offset+nameLen])
		offset += nameLen
		typ := wireType(payload[offset])
		offset++
		mod := binary.LittleEndian.Uint32(payload[offset : offset+4])
		offset += 4
		format := binary.LittleEndian.Uint16(payload[offset : offset+2])
		offset += 2
		cols = append(cols, columnInfo{
			name:         name,
			wireType:     typ,
			typeModifier: mod,
			formatCode:   format,
		})
	}
	return cols, nil
}

func parseRowData(payload []byte) ([]columnValue, error) {
	if len(payload) < 2 {
		return nil, errors.New("row data truncated")
	}
	offset := 0
	count := int(binary.LittleEndian.Uint16(payload[offset : offset+2]))
	offset += 2
	values := make([]columnValue, 0, count)
	for i := 0; i < count; i++ {
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

func parseCommandComplete(payload []byte) (string, int64, error) {
	if len(payload) < 64+8 {
		return "", 0, errors.New("command complete truncated")
	}
	tag := readNullTerminated(payload[:64])
	rows := int64(binary.LittleEndian.Uint64(payload[64 : 64+8]))
	return tag, rows, nil
}

func parseQueryResult(payload []byte) (byte, uint32, int64, error) {
	if len(payload) < 1+4+8 {
		return 0, 0, 0, errors.New("query result truncated")
	}
	status := payload[0]
	count := binary.LittleEndian.Uint32(payload[1:5])
	rows := int64(binary.LittleEndian.Uint64(payload[5:13]))
	return status, count, rows, nil
}

func parseQueryError(payload []byte) (uint32, string, string, string, string, error) {
	if len(payload) < 4+6+2+2+2 {
		return 0, "", "", "", "", errors.New("query error truncated")
	}
	offset := 0
	code := binary.LittleEndian.Uint32(payload[offset : offset+4])
	offset += 4
	sqlState := readNullTerminated(payload[offset : offset+6])
	offset += 6
	msgLen := int(binary.LittleEndian.Uint16(payload[offset : offset+2]))
	offset += 2
	detailLen := int(binary.LittleEndian.Uint16(payload[offset : offset+2]))
	offset += 2
	hintLen := int(binary.LittleEndian.Uint16(payload[offset : offset+2]))
	offset += 2
	msg := string(payload[offset : offset+msgLen])
	offset += msgLen
	detail := string(payload[offset : offset+detailLen])
	offset += detailLen
	hint := string(payload[offset : offset+hintLen])
	return code, sqlState, msg, detail, hint, nil
}

func buildBegin(sessionID []byte, isolation byte, readOnly bool) ([]byte, error) {
	if len(sessionID) != 16 {
		return nil, errors.New("sessionId must be 16 bytes")
	}
	payload := make([]byte, 16+1+1)
	copy(payload[0:16], sessionID)
	payload[16] = isolation
	if readOnly {
		payload[17] = 1
	}
	return encodeMessage(msgBegin, payload, 0), nil
}

func buildCommit(sessionID []byte) ([]byte, error) {
	if len(sessionID) != 16 {
		return nil, errors.New("sessionId must be 16 bytes")
	}
	return encodeMessage(msgCommit, append([]byte{}, sessionID...), 0), nil
}

func buildRollback(sessionID []byte) ([]byte, error) {
	if len(sessionID) != 16 {
		return nil, errors.New("sessionId must be 16 bytes")
	}
	return encodeMessage(msgRollback, append([]byte{}, sessionID...), 0), nil
}

func buildDisconnect(sessionID []byte) ([]byte, error) {
	if len(sessionID) != 16 {
		return nil, errors.New("sessionId must be 16 bytes")
	}
	return encodeMessage(msgDisconnect, append([]byte{}, sessionID...), 0), nil
}

func writeNullTerminated(dst []byte, value string) {
	copy(dst, []byte(value))
	if len(dst) > len(value) {
		for i := len(value); i < len(dst); i++ {
			dst[i] = 0
		}
	}
}

func readNullTerminated(src []byte) string {
	for i, b := range src {
		if b == 0 {
			return string(src[:i])
		}
	}
	return string(src)
}
