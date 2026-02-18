// ScratchBird-driver
// Copyright (c) 2025-2026 Dalton Calford
//
// Licensed under the Initial Developer's Public License Version 1.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at:
// https://www.firebirdsql.org/en/initial-developer-s-public-license-version-1-0/

import Foundation

public struct ScratchBirdConfig {
    public var host: String
    public var port: Int
    public var protocolName: String
    public var database: String
    public var user: String
    public var password: String?
    public var sslmode: String
    public var applicationName: String?
    public var searchPath: String?
    public var role: String?
    public var binaryTransfer: Bool
    public var compression: String
    public var fetchSize: Int

    public init(
        host: String = "localhost",
        port: Int = 3092,
        protocolName: String = "native",
        database: String,
        user: String,
        password: String? = nil,
        sslmode: String = "require",
        applicationName: String? = nil,
        searchPath: String? = nil,
        role: String? = nil,
        binaryTransfer: Bool = true,
        compression: String = "off",
        fetchSize: Int = 0
    ) {
        self.host = host
        self.port = port
        self.protocolName = protocolName
        self.database = database
        self.user = user
        self.password = password
        self.sslmode = sslmode
        self.applicationName = applicationName
        self.searchPath = searchPath
        self.role = role
        self.binaryTransfer = binaryTransfer
        self.compression = compression
        self.fetchSize = fetchSize
    }

    public init(dsn: String) {
        if dsn.contains("://"), let url = URLComponents(string: dsn) {
            let userInfo = url.user
            let passInfo = url.password
            let query = url.queryItems ?? []
            let params = Dictionary(uniqueKeysWithValues: query.map { ($0.name.lowercased(), $0.value ?? "") })
            self.host = url.host ?? "localhost"
            self.port = url.port ?? 3092
            self.protocolName = params["protocol"] ?? params["parser"] ?? params["dialect"] ?? "native"
            self.database = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            self.user = params["user"] ?? userInfo ?? ""
            self.password = params["password"] ?? passInfo
            self.sslmode = params["sslmode"] ?? "require"
            self.applicationName = params["application_name"]
            self.searchPath = params["search_path"]
            self.role = params["role"]
            self.binaryTransfer = params["binary_transfer"]?.lowercased() != "false"
            self.compression = params["compression"] ?? "off"
            self.fetchSize = Int(params["fetch_size"] ?? "0") ?? 0
        } else {
            var params: [String: String] = [:]
            for part in dsn.split(separator: " ") {
                let pieces = part.split(separator: "=", maxSplits: 1)
                if pieces.count == 2 {
                    params[String(pieces[0]).lowercased()] = String(pieces[1])
                }
            }
            self.host = params["host"] ?? "localhost"
            self.port = Int(params["port"] ?? "3092") ?? 3092
            self.protocolName = params["protocol"] ?? params["parser"] ?? params["dialect"] ?? "native"
            self.database = params["database"] ?? params["dbname"] ?? ""
            self.user = params["user"] ?? params["username"] ?? ""
            self.password = params["password"]
            self.sslmode = params["sslmode"] ?? "require"
            self.applicationName = params["application_name"]
            self.searchPath = params["search_path"]
            self.role = params["role"]
            self.binaryTransfer = params["binary_transfer"]?.lowercased() != "false"
            self.compression = params["compression"] ?? "off"
            self.fetchSize = Int(params["fetch_size"] ?? "0") ?? 0
        }
    }
}
