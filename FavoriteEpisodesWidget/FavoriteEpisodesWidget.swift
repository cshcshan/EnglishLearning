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
                id: "Episode 1",
                title: "The first episode title and it should be loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooong",
                desc: nil,
                date: nil,
                imageURLString: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg",
                urlString: nil
            ),
            Episode(
                id: "Episode 2",
                title: "My second episode",
                desc: nil,
                date: nil,
                imageURLString: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg",
                urlString: nil
            ),
            Episode(
                id: "Episode 3",
                title: "The third but may not be the last if I add others to this array later",
                desc: nil,
                date: nil,
                imageURLString: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg",
                urlString: nil
            ),
            Episode(
                id: "Episode 4",
                title: "The fourth episode doesn't have the image URL",
                desc: nil,
                date: nil,
                imageURLString: "",
                urlString: nil
            ),
            Episode(
                id: "Episode 5",
                title: "The fifth episode doesn't have the image URL",
                desc: nil,
                date: nil,
                imageURLString: "",
                urlString: nil
            )
        ]
    )
}

#Preview("Empty Episodes", as: .systemSmall) {
    FavoriteEpisodesWidget()
} timeline: {
    FavoriteEpisodesEntry(episodes: [])
}
