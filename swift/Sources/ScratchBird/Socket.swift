// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import Foundation

#if canImport(Network)
import Network
#endif

#if canImport(Glibc)
import Glibc
private func systemConnect(_ fd: Int32, _ addr: UnsafePointer<sockaddr>, _ len: socklen_t) -> Int32 {
    Glibc.connect(fd, addr, len)
}
private func systemClose(_ fd: Int32) -> Int32 { Glibc.close(fd) }
private let socketStream: Int32 = Int32(SOCK_STREAM.rawValue)
#else
import Darwin
private func systemConnect(_ fd: Int32, _ addr: UnsafePointer<sockaddr>, _ len: socklen_t) -> Int32 {
    Darwin.connect(fd, addr, len)
}
private func systemClose(_ fd: Int32) -> Int32 { Darwin.close(fd) }
private let socketStream: Int32 = Int32(SOCK_STREAM)
#endif

final class ScratchBirdSocket {
    private var fd: Int32 = -1
    #if canImport(Network)
    private var nwConnection: NWConnection?
    private var nwBuffer = Data()
    private let nwQueue = DispatchQueue(label: "scratchbird.tls")
    #endif

    func connect(host: String, port: Int, useTls: Bool) throws {
        if useTls {
            try connectTls(host: host, port: port)
            return
        }
        var hints = addrinfo(
            ai_flags: 0,
            ai_family: AF_UNSPEC,
            ai_socktype: socketStream,
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
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { systemConnect(fd, $0, addr.ai_addrlen) }
                }
                if result == 0 {
                    return
                }
                _ = systemClose(fd)
            }
            ptr = addr.ai_next
        }
        throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to connect"])
    }

    func write(_ data: Data) throws {
        #if canImport(Network)
        if let connection = nwConnection {
            let sema = DispatchSemaphore(value: 0)
            var writeError: Error?
            connection.send(content: data, completion: .contentProcessed { error in
                writeError = error
                sema.signal()
            })
            sema.wait()
            if let err = writeError {
                throw err
            }
            return
        }
        #endif
        let count = data.count
        let written = data.withUnsafeBytes { ptr -> Int in
            return send(fd, ptr.baseAddress, count, 0)
        }
        if written != count {
            throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Socket write failed"])
        }
    }

    func readExact(_ length: Int) throws -> Data {
        #if canImport(Network)
        if let connection = nwConnection {
            while nwBuffer.count < length {
                let sema = DispatchSemaphore(value: 0)
                var recvError: Error?
                connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { data, _, _, error in
                    if let data = data, !data.isEmpty {
                        self.nwBuffer.append(data)
                    }
                    recvError = error
                    sema.signal()
                }
                sema.wait()
                if let err = recvError {
                    throw err
                }
                if nwBuffer.isEmpty && length > 0 {
                    throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "Socket closed"])
                }
            }
            let out = nwBuffer.prefix(length)
            nwBuffer.removeFirst(length)
            return Data(out)
        }
        #endif
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
        #if canImport(Network)
        if let connection = nwConnection {
            connection.cancel()
            nwConnection = nil
            nwBuffer.removeAll(keepingCapacity: true)
            return
        }
        #endif
        if fd >= 0 {
            _ = systemClose(fd)
            fd = -1
        }
    }

    private func connectTls(host: String, port: Int) throws {
        #if canImport(Network)
        let parameters = NWParameters.tls
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port)))
        let connection = NWConnection(to: endpoint, using: parameters)
        let sema = DispatchSemaphore(value: 0)
        var connectError: Error?
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                sema.signal()
            case .failed(let error):
                connectError = error
                sema.signal()
            default:
                break
            }
        }
        connection.start(queue: nwQueue)
        sema.wait()
        if let err = connectError {
            throw err
        }
        nwConnection = connection
        return
        #else
        throw NSError(domain: "ScratchBird", code: -1, userInfo: [NSLocalizedDescriptionKey: "TLS transport is not available on this platform"])
        #endif
    }
}
