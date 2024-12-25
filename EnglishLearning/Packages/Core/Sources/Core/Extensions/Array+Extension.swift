//
//  Array+Extension.swift
//  Core
//
//  Created by Han Chen on 2024/12/26.
//

import Foundation

extension Array {
    public subscript(safe index: Int) -> Element? {
        guard (0..<count).contains(index) else { return nil }
        return self[index]
    }
}
