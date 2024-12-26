//
//  FavoriteEpisodesEntry.swift
//  FavoriteEpisodesWidgetExtension
//
//  Created by Han Chen on 2024/12/26.
//

import Episodes
import Foundation
import WidgetKit

struct FavoriteEpisodesEntry: TimelineEntry {
    let date: Date = .now
    let episodes: [Episode]
}

extension FavoriteEpisodesEntry {
    static var placeholder: FavoriteEpisodesEntry {
        FavoriteEpisodesEntry(
            episodes: [
                Episode(
                    id: "Episode 241226",
                    title: "Embarrassed to go to the doctor?",
                    desc: nil,
                    date: Date.build(year: 2024, month: 12, day: 26),
                    imageURLString: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k7vh9q.jpg",
                    urlString: nil
                ),
                Episode(
                    id: "Episode 241219",
                    title: "Call centres: Are you talking to AI?",
                    desc: nil,
                    date: Date.build(year: 2024, month: 12, day: 19),
                    imageURLString: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k641hr.jpg",
                    urlString: nil
                )
            ]
        )
    }
}

extension Date {
    fileprivate static func build(year: Int, month: Int, day: Int) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        let dateComponent = DateComponents(
            calendar: calendar,
            year: year,
            month: month,
            day: day
        )
        return dateComponent.date
    }
}
