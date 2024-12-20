//
//  ServerEpisodesCheckerTests.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/3.
//

import Core
import Foundation
import Testing
@testable import Episodes

@MainActor
struct ServerEpisodesCheckerTests {
    
    struct Arguments {
        let today: Date
        let localEpisodes: [Episode]
        let expectedResult: Bool
    }

    @Test(
        arguments: [
            Arguments(today: .build(year: 2024, month: 12, day: 4)!, localEpisodes: [], expectedResult: true),
            Arguments(
                today: .build(year: 2024, month: 12, day: 4)!,
                localEpisodes: [.dummy(id: "1", date: .build(year: 2024, month: 11, day: 28)!)],
                expectedResult: false
            ),
            Arguments(today: .build(year: 2024, month: 12, day: 5)!, localEpisodes: [], expectedResult: true),
            Arguments(
                today: .build(year: 2024, month: 12, day: 5)!,
                localEpisodes: [.dummy(id: "1", date: .build(year: 2024, month: 11, day: 28)!)],
                expectedResult: true
            ),
            Arguments(
                today: .build(year: 2024, month: 12, day: 5)!,
                localEpisodes: [.dummy(id: "1", date: .build(year: 2024, month: 12, day: 5)!)],
                expectedResult: false
            ),
            Arguments(today: .build(year: 2024, month: 12, day: 6)!, localEpisodes: [], expectedResult: true),
            Arguments(
                today: .build(year: 2024, month: 12, day: 6)!,
                localEpisodes: [.dummy(id: "1", date: .build(year: 2024, month: 11, day: 28)!)],
                expectedResult: true
            ),
            Arguments(
                today: .build(year: 2024, month: 12, day: 6)!,
                localEpisodes: [.dummy(id: "1", date: .build(year: 2024, month: 12, day: 5)!)],
                expectedResult: false
            )
        ]
    )
    func hasServerNewEpisodes(arguments: Arguments) async throws {
        let dataSource = try DataSource(with: .mock(isStoredInMemoryOnly: true))
        if !arguments.localEpisodes.isEmpty {
            try dataSource.add(arguments.localEpisodes)
        }
        let sut = ServerEpisodesChecker(dataSource: dataSource)
        #expect(sut.hasServerNewEpisodes(with: arguments.today) == arguments.expectedResult)
    }

}

extension Date {
    fileprivate static func build(year: Int, month: Int, day: Int) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day
        )
        return dateComponents.date
    }
}
