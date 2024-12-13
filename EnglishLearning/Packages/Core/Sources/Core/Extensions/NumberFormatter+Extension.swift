//
//  NumberFormatter+Extension.swift
//  Core
//
//  Created by Han Chen on 2024/12/14.
//

import Foundation

extension NumberFormatter {
    public static let `default`: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
}
