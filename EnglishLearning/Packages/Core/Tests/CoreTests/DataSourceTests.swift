//
//  DataSourceTests.swift
//  Core
//
//  Created by Han Chen on 2024/11/26.
//

import SwiftData
import Testing
@testable import Core

struct DataSourceTests {

    @MainActor
    @Test func access() throws {
        // TODO: to extract `sut` as a `struct` variable
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)
        let modelContainer = try! ModelContainer(
            for: Dummy.self,
            configurations: modelConfiguration
        )
        let sut = DataSource<Dummy>(modelContext: modelContainer.mainContext)
        
        var fetchDummies = try sut.fetch(FetchDescriptor<Dummy>())
        #expect(fetchDummies.isEmpty)

        let insertDummies = [Dummy].dummies
        try sut.add(insertDummies)
        fetchDummies = try sut.fetch(FetchDescriptor<Dummy>())
        #expect(fetchDummies.count == 3)
    }

}

extension DataSourceTests {
    @Model
    final class Dummy {
        var name: String
        var phone: String
        var email: String
        
        init(name: String, phone: String, email: String) {
            self.name = name
            self.phone = phone
            self.email = email
        }
    }
}

extension [DataSourceTests.Dummy] {
    static var dummies: [DataSourceTests.Dummy] {
        [
            DataSourceTests.Dummy(
                name: "Apple Red", phone: "0912345678", email: "apple.red@gmail.com"
            ),
            DataSourceTests.Dummy(
                name: "Banana Yellow", phone: "0987654321", email: "banana.yellow@gmail.com"
            ),
            DataSourceTests.Dummy(
                name: "Blue Berry", phone: "0988888888", email: "blue.berry@gmail.com"
            )
        ]
    }
}
