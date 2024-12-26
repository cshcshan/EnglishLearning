//
//  MockAppGroupFileManager.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/26.
//

import Core
import Foundation

final class MockAppGroupFileManager: AppGroupFileManagerable {
    var saveRemoteURLCount = 0
    var removeFileItemCount = 0
    var loadFileCount = 0
    
    func save(remoteURL: URL, to filename: String) throws {
        saveRemoteURLCount += 1
    }
    
    func remove(filename: String) throws {
        removeFileItemCount += 1
    }
    
    func load(filename: String) throws -> Data {
        loadFileCount += 1
        return Data()
    }
}
