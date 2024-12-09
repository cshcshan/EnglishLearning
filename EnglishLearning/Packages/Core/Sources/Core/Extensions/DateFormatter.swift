//
//  DateFormatter.swift
//  Core
//
//  Created by Han Chen on 2024/12/9.
//

import Foundation

extension DateFormatter {
    public static let displayDate = DateFormatter(dateFormat: "yyyy/M/d")

    convenience init(dateFormat: String) {
        self.init()
        self.calendar = .current
        self.isLenient = true
        self.dateFormat = dateFormat
    }
}
