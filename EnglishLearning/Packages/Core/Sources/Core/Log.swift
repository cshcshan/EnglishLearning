//
//  Log.swift
//  Core
//
//  Created by Han Chen on 2024/12/9.
//

import Foundation
import OSLog

public actor Log {
    private let logger: Logger
    
    private init(subsystem: String, category: String) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func add(level: OSLogType = .default, message: String) {
        logger.log(level: level, "\(message)")
    }
}

extension Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? ""
    
    public static let network = Log(subsystem: subsystem, category: "network")
    public static let data = Log(subsystem: subsystem, category: "data")
    public static let ui = Log(subsystem: subsystem, category: "UI")
}
