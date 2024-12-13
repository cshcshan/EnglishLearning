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

    public func add(error: Error) {
        logger.log(level: .error, "\(error)")
        #if DEBUG
        if !(error is DummyError) {
            assertionFailure(error.localizedDescription)
        }
        #endif
    }
}

extension Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? ""
    
    public static let network = Log(subsystem: subsystem, category: "network")
    public static let data = Log(subsystem: subsystem, category: "data")
    public static let ui = Log(subsystem: subsystem, category: "UI")
    public static let audio = Log(subsystem: subsystem, category: "audio")
}

