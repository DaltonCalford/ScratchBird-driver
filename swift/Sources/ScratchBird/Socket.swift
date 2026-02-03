// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import Foundation

#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif

final class ScratchBirdSocket {
    private var fd: Int32 = -1

    func connect(host: String, port: Int) throws {
        var hints = addrinfo(
            ai_flags: 0,
            ai_family: AF_UNSPEC,
            ai_socktype: SOCK_STREAM,
            ai_protocol: 0,
            ai_addrlen: 0,
            ai_addr: nil,
            ai_canonname: nil,
            ai_next: nil
        )

        var res: UnsafeMutablePointer<addrinfo>?
        let portStr = String(port)
        let err = getaddrinfo(host, portStr, &hints, &res)
        if err != 0 {
            throw NSError(domain: "ScratchBird", code: Int(err), userInfo: [NSLocalizedDescriptionKey: String(cString: gai_strerror(err))])
        }
        defer { freeaddrinfo(res) }

        var ptr = res
        while ptr != nil {
            let addr = ptr!.pointee
            fd = socket(addr.ai_family, addr.ai_socktype, addr.ai_protocol)
            if fd >= 0 {
                let result = withUnsafePointer(to: addr.ai_addr!.pointee) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, addr.ai_addrlen) }
                }
                if result == 0 {
                    return
                }
                close(fd)
            }
            ptr = addr.ai_next
        }
        throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to connect"])
    }

    func write(_ data: Data) throws {
        let count = data.count
        let written = data.withUnsafeBytes { ptr -> Int in
            return send(fd, ptr.baseAddress, count, 0)
        }
        if written != count {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Socket write failed"])
        }
    }

    func readExact(_ length: Int) throws -> Data {
        var buffer = Data(count: length)
        var offset = 0
        while offset < length {
            let readCount = buffer.withUnsafeMutableBytes { ptr -> Int in
                return recv(fd, ptr.baseAddress!.advanced(by: offset), length - offset, 0)
            }
            if readCount <= 0 {
                throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Socket closed"])
            }
            offset += readCount
        }
        return buffer
    }

    func close() {
        if fd >= 0 {
            _ = Darwin.close(fd)
            fd = -1
        }
    }
}
