//
//  ArrayTests.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/26.
//

import Testing
@testable import Core

struct ArrayTests {
    struct Arguments {
        let array: [String]
        let index: Int
        let expectedElement: String?
    }
    
    @Test(arguments: [
        Arguments(array: [], index: 0, expectedElement: nil),
        Arguments(array: ["A", "B"], index: 0, expectedElement: "A"),
        Arguments(array: ["A", "B"], index: 2, expectedElement: nil)
    ])
    func safeSubscript(arguments: Arguments) async throws {
        #expect(arguments.array[safe: arguments.index] == arguments.expectedElement)
    }
}
