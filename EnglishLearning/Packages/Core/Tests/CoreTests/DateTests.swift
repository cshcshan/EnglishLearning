//
//  DateTests.swift
//  Core
//
//  Created by Han Chen on 2024/12/1.
//

import Foundation
import Testing
@testable import Core

struct DateTests {
    
    @Test(
        arguments: zip(
            // day
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
            // expectedWeekday
            [
                Weekday.sunday, // 2024/12/1
                Weekday.monday, // 2024/12/2
                Weekday.tuesday, // 2024/12/3
                Weekday.wednesday, // 2024/12/4
                Weekday.thursday, // 2024/12/5
                Weekday.friday, // 2024/12/6
                Weekday.saturday, // 2024/12/7
                Weekday.sunday, // 2024/12/8
                Weekday.monday, // 2024/12/9
                Weekday.tuesday, // 2024/12/10
                Weekday.wednesday, // 2024/12/11
                Weekday.thursday, // 2024/12/12
                Weekday.friday, // 2024/12/13
                Weekday.saturday, // 2024/12/14
            ]
        )
    )
    func weekday(day: Int, expectedWeekday: Weekday) async throws {
        let date = Date.build(year: 2024, month: 12, day: day)
        #expect(date?.weekday == expectedWeekday)
    }
    
}

// MARK: - lastWeekday(_:)

extension DateTests {
    
    @Test(
        arguments: zip(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
            [
                Date.build(year: 2024, month: 12, day: 29)!, // 2025/1/1
                Date.build(year: 2024, month: 12, day: 29)!, // 2025/1/2
                Date.build(year: 2024, month: 12, day: 29)!, // 2025/1/3
                Date.build(year: 2024, month: 12, day: 29)!, // 2025/1/4
                Date.build(year: 2025, month: 1, day: 5)!, // 2025/1/5
                Date.build(year: 2025, month: 1, day: 5)!, // 2025/1/6
                Date.build(year: 2025, month: 1, day: 5)!, // 2025/1/7
                Date.build(year: 2025, month: 1, day: 5)!, // 2025/1/8
                Date.build(year: 2025, month: 1, day: 5)!, // 2025/1/9
                Date.build(year: 2025, month: 1, day: 5)!, // 2025/1/10
                Date.build(year: 2025, month: 1, day: 5)!, // 2025/1/11
                Date.build(year: 2025, month: 1, day: 12)!, // 2025/1/12
                Date.build(year: 2025, month: 1, day: 12)!, // 2025/1/13
                Date.build(year: 2025, month: 1, day: 12)!, // 2025/1/14
            ]
        )
    )
    func lastSunday(day: Int, expectedLastSunday: Date) async throws {
        let date = Date.build(year: 2025, month: 1, day: day)!
        #expect(date.lastWeekday(.sunday) == expectedLastSunday)
    }
    
    @Test(
        arguments: zip(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
            [
                Date.build(year: 2024, month: 12, day: 30)!, // 2025/1/1
                Date.build(year: 2024, month: 12, day: 30)!, // 2025/1/2
                Date.build(year: 2024, month: 12, day: 30)!, // 2025/1/3
                Date.build(year: 2024, month: 12, day: 30)!, // 2025/1/4
                Date.build(year: 2024, month: 12, day: 30)!, // 2025/1/5
                Date.build(year: 2025, month: 1, day: 6)!, // 2025/1/6
                Date.build(year: 2025, month: 1, day: 6)!, // 2025/1/7
                Date.build(year: 2025, month: 1, day: 6)!, // 2025/1/8
                Date.build(year: 2025, month: 1, day: 6)!, // 2025/1/9
                Date.build(year: 2025, month: 1, day: 6)!, // 2025/1/10
                Date.build(year: 2025, month: 1, day: 6)!, // 2025/1/11
                Date.build(year: 2025, month: 1, day: 6)!, // 2025/1/12
                Date.build(year: 2025, month: 1, day: 13)!, // 2025/1/13
                Date.build(year: 2025, month: 1, day: 13)!, // 2025/1/14
            ]
        )
    )
    func lastMonday(day: Int, expectedLastMonday: Date) async throws {
        let date = Date.build(year: 2025, month: 1, day: day)!
        #expect(date.lastWeekday(.monday) == expectedLastMonday)
    }
    
    @Test(
        arguments: zip(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
            [
                Date.build(year: 2024, month: 12, day: 31)!, // 2025/1/1
                Date.build(year: 2024, month: 12, day: 31)!, // 2025/1/2
                Date.build(year: 2024, month: 12, day: 31)!, // 2025/1/3
                Date.build(year: 2024, month: 12, day: 31)!, // 2025/1/4
                Date.build(year: 2024, month: 12, day: 31)!, // 2025/1/5
                Date.build(year: 2024, month: 12, day: 31)!, // 2025/1/6
                Date.build(year: 2025, month: 1, day: 7)!, // 2025/1/7
                Date.build(year: 2025, month: 1, day: 7)!, // 2025/1/8
                Date.build(year: 2025, month: 1, day: 7)!, // 2025/1/9
                Date.build(year: 2025, month: 1, day: 7)!, // 2025/1/10
                Date.build(year: 2025, month: 1, day: 7)!, // 2025/1/11
                Date.build(year: 2025, month: 1, day: 7)!, // 2025/1/12
                Date.build(year: 2025, month: 1, day: 7)!, // 2025/1/13
                Date.build(year: 2025, month: 1, day: 14)!, // 2025/1/14
            ]
        )
    )
    func lastTuesday(day: Int, expectedLastTuesday: Date) async throws {
        let date = Date.build(year: 2025, month: 1, day: day)!
        #expect(date.lastWeekday(.tuesday) == expectedLastTuesday)
    }
    
    @Test(
        arguments: zip(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
            [
                Date.build(year: 2025, month: 1, day: 1)!, // 2025/1/1
                Date.build(year: 2025, month: 1, day: 1)!, // 2025/1/2
                Date.build(year: 2025, month: 1, day: 1)!, // 2025/1/3
                Date.build(year: 2025, month: 1, day: 1)!, // 2025/1/4
                Date.build(year: 2025, month: 1, day: 1)!, // 2025/1/5
                Date.build(year: 2025, month: 1, day: 1)!, // 2025/1/6
                Date.build(year: 2025, month: 1, day: 1)!, // 2025/1/7
                Date.build(year: 2025, month: 1, day: 8)!, // 2025/1/8
                Date.build(year: 2025, month: 1, day: 8)!, // 2025/1/9
                Date.build(year: 2025, month: 1, day: 8)!, // 2025/1/10
                Date.build(year: 2025, month: 1, day: 8)!, // 2025/1/11
                Date.build(year: 2025, month: 1, day: 8)!, // 2025/1/12
                Date.build(year: 2025, month: 1, day: 8)!, // 2025/1/13
                Date.build(year: 2025, month: 1, day: 8)!, // 2025/1/14
            ]
        )
    )
    func lastWednesday(day: Int, expectedLastWednesday: Date) async throws {
        let date = Date.build(year: 2025, month: 1, day: day)!
        #expect(date.lastWeekday(.wednesday) == expectedLastWednesday)
    }
    
    @Test(
        arguments: zip(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
            [
                Date.build(year: 2024, month: 12, day: 26)!, // 2025/1/1
                Date.build(year: 2025, month: 1, day: 2)!, // 2025/1/2
                Date.build(year: 2025, month: 1, day: 2)!, // 2025/1/3
                Date.build(year: 2025, month: 1, day: 2)!, // 2025/1/4
                Date.build(year: 2025, month: 1, day: 2)!, // 2025/1/5
                Date.build(year: 2025, month: 1, day: 2)!, // 2025/1/6
                Date.build(year: 2025, month: 1, day: 2)!, // 2025/1/7
                Date.build(year: 2025, month: 1, day: 2)!, // 2025/1/8
                Date.build(year: 2025, month: 1, day: 9)!, // 2025/1/9
                Date.build(year: 2025, month: 1, day: 9)!, // 2025/1/10
                Date.build(year: 2025, month: 1, day: 9)!, // 2025/1/11
                Date.build(year: 2025, month: 1, day: 9)!, // 2025/1/12
                Date.build(year: 2025, month: 1, day: 9)!, // 2025/1/13
                Date.build(year: 2025, month: 1, day: 9)!, // 2025/1/14
            ]
        )
    )
    func lastThursday(day: Int, expectedLastThursday: Date) async throws {
        let date = Date.build(year: 2025, month: 1, day: day)!
        #expect(date.lastWeekday(.thursday) == expectedLastThursday)
    }
    
    @Test(
        arguments: zip(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
            [
                Date.build(year: 2024, month: 12, day: 27)!, // 2025/1/1
                Date.build(year: 2024, month: 12, day: 27)!, // 2025/1/2
                Date.build(year: 2025, month: 1, day: 3)!, // 2025/1/3
                Date.build(year: 2025, month: 1, day: 3)!, // 2025/1/4
                Date.build(year: 2025, month: 1, day: 3)!, // 2025/1/5
                Date.build(year: 2025, month: 1, day: 3)!, // 2025/1/6
                Date.build(year: 2025, month: 1, day: 3)!, // 2025/1/7
                Date.build(year: 2025, month: 1, day: 3)!, // 2025/1/8
                Date.build(year: 2025, month: 1, day: 3)!, // 2025/1/9
                Date.build(year: 2025, month: 1, day: 10)!, // 2025/1/10
                Date.build(year: 2025, month: 1, day: 10)!, // 2025/1/11
                Date.build(year: 2025, month: 1, day: 10)!, // 2025/1/12
                Date.build(year: 2025, month: 1, day: 10)!, // 2025/1/13
                Date.build(year: 2025, month: 1, day: 10)!, // 2025/1/14
            ]
        )
    )
    func lastFriday(day: Int, expectedLastFriday: Date) async throws {
        let date = Date.build(year: 2025, month: 1, day: day)!
        #expect(date.lastWeekday(.friday) == expectedLastFriday)
    }
    
    @Test(
        arguments: zip(
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
            [
                Date.build(year: 2024, month: 12, day: 28)!, // 2025/1/1
                Date.build(year: 2024, month: 12, day: 28)!, // 2025/1/2
                Date.build(year: 2024, month: 12, day: 28)!, // 2025/1/3
                Date.build(year: 2025, month: 1, day: 4)!, // 2025/1/4
                Date.build(year: 2025, month: 1, day: 4)!, // 2025/1/5
                Date.build(year: 2025, month: 1, day: 4)!, // 2025/1/6
                Date.build(year: 2025, month: 1, day: 4)!, // 2025/1/7
                Date.build(year: 2025, month: 1, day: 4)!, // 2025/1/8
                Date.build(year: 2025, month: 1, day: 4)!, // 2025/1/9
                Date.build(year: 2025, month: 1, day: 4)!, // 2025/1/10
                Date.build(year: 2025, month: 1, day: 11)!, // 2025/1/11
                Date.build(year: 2025, month: 1, day: 11)!, // 2025/1/12
                Date.build(year: 2025, month: 1, day: 11)!, // 2025/1/13
                Date.build(year: 2025, month: 1, day: 11)!, // 2025/1/14
            ]
        )
    )
    func lastSaturday(day: Int, expectedLastSaturday: Date) async throws {
        let date = Date.build(year: 2025, month: 1, day: day)!
        #expect(date.lastWeekday(.saturday) == expectedLastSaturday)
    }

}

// MARK: - compare(with:,toGranularity:)

extension DateTests {
    @Test func compare() async throws {
        func buildDate(year: Int, month: Int, day: Int, hour: Int, minute: Int) -> Date {
            DateComponents(
                calendar: .current, year: year, month: month, day: day, hour: hour, minute: minute
            ).date!
        }
        
        let date2_0_0 = buildDate(year: 2024, month: 12, day: 2, hour: 0, minute: 0)
        let date2_23_59 = buildDate(year: 2024, month: 12, day: 2, hour: 23, minute: 59)
        let date3_0_0 = buildDate(year: 2024, month: 12, day: 3, hour: 0, minute: 0)
        let date3_0_1 = buildDate(year: 2024, month: 12, day: 3, hour: 0, minute: 1)
        let date3_1_1 = buildDate(year: 2024, month: 12, day: 3, hour: 1, minute: 1)
        let date4_0_0 = buildDate(year: 2024, month: 12, day: 4, hour: 0, minute: 0)

        #expect(date3_0_0.compare(with: date2_0_0, toGranularity: .day) == .orderedDescending)
        #expect(date3_0_0.compare(with: date2_23_59, toGranularity: .day) == .orderedDescending)
        #expect(date3_0_0.compare(with: date3_0_1, toGranularity: .day) == .orderedSame)
        #expect(date3_0_0.compare(with: date3_1_1, toGranularity: .day) == .orderedSame)
        #expect(date3_0_0.compare(with: date4_0_0, toGranularity: .day) == .orderedAscending)

        #expect(date3_0_0.compare(with: date2_0_0, toGranularity: .hour) == .orderedDescending)
        #expect(date3_0_0.compare(with: date2_23_59, toGranularity: .hour) == .orderedDescending)
        #expect(date3_0_0.compare(with: date3_0_1, toGranularity: .hour) == .orderedSame)
        #expect(date3_0_0.compare(with: date3_1_1, toGranularity: .hour) == .orderedAscending)
        #expect(date3_0_0.compare(with: date4_0_0, toGranularity: .hour) == .orderedAscending)
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
