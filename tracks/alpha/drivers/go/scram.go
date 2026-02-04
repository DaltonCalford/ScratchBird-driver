// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/
package scratchbird

import (
	"crypto/hmac"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"
)

type scramClient struct {
	username        string
	clientNonce     string
	clientFirstBare string
	serverSignature []byte
}

func newScramClient(username string) (*scramClient, error) {
	nonce := make([]byte, 18)
	if _, err := rand.Read(nonce); err != nil {
		return nil, err
	}
	return &scramClient{
		username:    username,
		clientNonce: base64.StdEncoding.EncodeToString(nonce),
	}, nil
}

func (s *scramClient) clientFirstMessage() string {
	s.clientFirstBare = fmt.Sprintf("n=%s,r=%s", escapeScram(s.username), s.clientNonce)
	return "n,," + s.clientFirstBare
}

func (s *scramClient) handleServerFirst(password, serverFirst string) (string, error) {
	attrs := parseScramAttrs(serverFirst)
	nonce := attrs["r"]
	saltB64 := attrs["s"]
	iterStr := attrs["i"]
	if nonce == "" || !strings.HasPrefix(nonce, s.clientNonce) {
		return "", errors.New("SCRAM server nonce mismatch")
	}
	if saltB64 == "" || iterStr == "" {
		return "", errors.New("SCRAM server-first missing fields")
	}
	iterations, err := parseInt(iterStr)
	if err != nil {
		return "", err
	}
	salt, err := base64.StdEncoding.DecodeString(saltB64)
	if err != nil {
		return "", err
	}
	salted := pbkdf2SHA256([]byte(password), salt, iterations, 32)
	clientKey := hmacSHA256(salted, []byte("Client Key"))
	storedKey := sha256Sum(clientKey)
	clientFinalWithoutProof := "c=biws,r=" + nonce
	authMessage := s.clientFirstBare + "," + serverFirst + "," + clientFinalWithoutProof
	clientSignature := hmacSHA256(storedKey, []byte(authMessage))
	clientProof := xorBytes(clientKey, clientSignature)
	serverKey := hmacSHA256(salted, []byte("Server Key"))
	s.serverSignature = hmacSHA256(serverKey, []byte(authMessage))
	return clientFinalWithoutProof + ",p=" + base64.StdEncoding.EncodeToString(clientProof), nil
}

func (s *scramClient) verifyServerFinal(serverFinal string) error {
	attrs := parseScramAttrs(serverFinal)
	verifier := attrs["v"]
	if verifier == "" || len(s.serverSignature) == 0 {
		return errors.New("SCRAM server-final missing verifier")
	}
	expected := base64.StdEncoding.EncodeToString(s.serverSignature)
	if verifier != expected {
		return errors.New("SCRAM server signature mismatch")
	}
	return nil
}

func escapeScram(input string) string {
	replacer := strings.NewReplacer("=", "=3D", ",", "=2C")
	return replacer.Replace(input)
}

func parseScramAttrs(message string) map[string]string {
	attrs := map[string]string{}
	if message == "" {
		return attrs
	}
	parts := strings.Split(message, ",")
	for _, part := range parts {
		if len(part) < 3 {
			continue
		}
		if idx := strings.Index(part, "="); idx > 0 {
			attrs[part[:idx]] = part[idx+1:]
		}
	}
	return attrs
}

func hmacSHA256(key, data []byte) []byte {
	mac := hmac.New(sha256.New, key)
	mac.Write(data)
	return mac.Sum(nil)
}

func sha256Sum(data []byte) []byte {
	sum := sha256.Sum256(data)
	return sum[:]
}

func xorBytes(left, right []byte) []byte {
	out := make([]byte, len(left))
	for i := range left {
		out[i] = left[i] ^ right[i]
	}
	return out
}

func parseInt(text string) (int, error) {
	var value int
	for _, ch := range text {
		if ch < '0' || ch > '9' {
			return 0, errors.New("invalid SCRAM iteration count")
		}
		value = value*10 + int(ch-'0')
	}
	return value, nil
}

func pbkdf2SHA256(password, salt []byte, iterations, keyLen int) []byte {
	blockCount := (keyLen + sha256.Size - 1) / sha256.Size
	var out []byte
	for i := 1; i <= blockCount; i++ {
		t := pbkdf2F(password, salt, iterations, i)
		out = append(out, t...)
	}
	return out[:keyLen]
}

func pbkdf2F(password, salt []byte, iterations, blockIndex int) []byte {
	block := make([]byte, len(salt)+4)
	copy(block, salt)
	block[len(block)-4] = byte(blockIndex >> 24)
	block[len(block)-3] = byte(blockIndex >> 16)
	block[len(block)-2] = byte(blockIndex >> 8)
	block[len(block)-1] = byte(blockIndex)
	u := hmacSHA256(password, block)
	out := make([]byte, len(u))
	copy(out, u)
	for i := 1; i < iterations; i++ {
		u = hmacSHA256(password, u)
		for j := range out {
			out[j] ^= u[j]
		}
	}
	return out
}
