//
//  Date+Extensions.swift
//  Core
//
//  Created by Han Chen on 2024/12/1.
//

import Foundation

extension Date {
    /// 1 means Sunday, 2 means Monday and so on
    public var weekday: Weekday? {
        // Use the standard calendar in case users update their preferences of the start of day
        let calendar = Calendar(identifier: .gregorian)
        let dateComponents = calendar.dateComponents(in: TimeZone.current, from: self)
        guard let weekday = dateComponents.weekday else { return nil }
        return Weekday(rawValue: weekday)
    }
    
    public func addingDays(_ days: Int) -> Date? {
        Calendar(identifier: .gregorian).date(byAdding: Calendar.Component.day, value: days, to: self)
    }

    public func addingMonths(_ months: Int) -> Date? {
        Calendar(identifier: .gregorian).date(byAdding: Calendar.Component.month, value: months, to: self)
    }

    public func addingYears(_ years: Int) -> Date? {
        Calendar(identifier: .gregorian).date(byAdding: Calendar.Component.year, value: years, to: self)
    }
    
    public func lastWeekday(_ lastWeekday: Weekday) -> Date? {
        guard let weekday else { return nil }
        
        var differDays = lastWeekday.rawValue - weekday.rawValue
        if differDays > 0 {
            differDays -= 7
        }
        return addingDays(differDays)
    }
    
    public func compare(with anotherDate: Date, toGranularity component: Calendar.Component) -> ComparisonResult {
        Calendar.current.compare(self, to: anotherDate, toGranularity: component)
    }
}

public enum Weekday: Int, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}
