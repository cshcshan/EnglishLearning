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
    
    public init(subsystem: String, category: String) {
        logger = Logger(subsystem: subsystem, category: category)
    }

    public func add(level: OSLogType = .default, message: String) {
        logger.log(level: level, "\(message)")
    }
}
