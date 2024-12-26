//
//  FavoriteEpisodesWidget.swift
//  FavoriteEpisodesWidget
//
//  Created by Han Chen on 2024/12/26.
//

import Episodes
import SwiftUI
import WidgetKit

struct FavoriteEpisodesWidget: Widget {
    let kind = "FavoriteEpisodesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: FavoriteEpisodesProvider()
        ) { entry in
            FavoriteEpisodesView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Favorite Episodes")
        .description("Display your favorite episodes")
    }
}

#Preview(as: .systemSmall) {
    FavoriteEpisodesWidget()
} timeline: {
    FavoriteEpisodesEntry(
        episodes: [
            Episode(
                id: "Episode ID",
                title: "Episode Title",
                desc: "Episode Desc",
                date: nil,
                imageURLString: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg",
                urlString: nil
            )
        ]
    )
}
