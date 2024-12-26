//
//  AppGroupFileManager.swift
//  Core
//
//  Created by Han Chen on 2024/12/26.
//

import UIKit
import Foundation

public protocol AppGroupFileManagerable {
    func save(remoteURL: URL, to filename: String) throws
    func remove(filename: String) throws
    func load(filename: String) throws -> Data
}

public struct AppGroupFileManager: AppGroupFileManagerable {
    private let appGroupURL: URL
    
    public init(appGroupURL: URL) {
        self.appGroupURL = appGroupURL
    }
    
    public func save(remoteURL: URL, to filename: String) throws {
        // TODO: to check the disk size before save it
        let filename = filename.replacingOccurrences(of: " ", with: "")
        let fileURL = appGroupURL.appending(path: filename, directoryHint: .notDirectory)
        
        Task {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            await Log.file.add(level: .debug, message: "Save \(fileURL.absoluteString)")

            var folderPath = fileURL
            folderPath.deleteLastPathComponent()
            // Using `path()` instead of `absoluteString` for `fileExists()`, otherwise, the result
            // always **false**
            if !FileManager.default.fileExists(atPath: folderPath.path()) {
                try FileManager.default.createDirectory(at: folderPath, withIntermediateDirectories: true)
            }
            
            // Using `path()` instead of `absoluteString` for `fileExists()`, otherwise, the result
            // always **false**
            if FileManager.default.fileExists(atPath: fileURL.path()) {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            try data.write(to: fileURL)
        }
    }
    
    public func remove(filename: String) throws {
        let filename = filename.replacingOccurrences(of: " ", with: "")
        let fileURL = appGroupURL.appending(path: filename, directoryHint: .notDirectory)
        // Using `path()` instead of `absoluteString` for `fileExists()`, otherwise, the result
        // always **false**
        guard FileManager.default.fileExists(atPath: fileURL.path()) else { return }
        Task { await Log.file.add(level: .debug, message: "Remove \(fileURL.absoluteString)") }
        try FileManager.default.removeItem(at: fileURL)
    }
    
    public func load(filename: String) throws -> Data {
        let filename = filename.replacingOccurrences(of: " ", with: "")
        let fileURL = appGroupURL.appending(path: filename, directoryHint: .notDirectory)
        
        return try Data(contentsOf: fileURL)
    }
}
