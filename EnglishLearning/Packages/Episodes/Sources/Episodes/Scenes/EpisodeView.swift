//
//  EpisodeView.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/9.
//

import SwiftUI

struct EpisodeView: View {
    let episode: Episode

    var body: some View {
        VStack(alignment: .leading) {
            AsyncImage(url: episode.imageURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Rectangle()
                    .fill(.gray.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1920 / 1080, contentMode: .fit)
            .padding(.bottom, 8)
            
            if let title = episode.title {
                Text(title)
                    .font(.title2)
                    .padding(.bottom, 4)
            }
            if let desc = episode.desc {
                Text(desc)
                    .font(.subheadline)
                    .padding(.bottom, 4)
            }
            if let displayDateString = episode.displayDateString {
                Text(displayDateString)
                    .font(.caption)
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let episode1 = Episode(
        id: nil,
        title: "Episode Title has multiple lines because it may important",
        desc: "Episode description may have multiple lines to describe what it is",
        date: Date(),
        imageURLString: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg",
        urlString: nil
    )
    let episode2 = Episode(
        id: nil,
        title: "Episode Title",
        desc: "Episode description may have multiple lines to describe what it is",
        date: Date(),
        imageURLString: nil,
        urlString: nil
    )
    let episode3 = Episode(
        id: nil,
        title: nil,
        desc: nil,
        date: Date(),
        imageURLString: nil,
        urlString: nil
    )
    let episode4 = Episode(
        id: nil,
        title: nil,
        desc: nil,
        date: nil,
        imageURLString: nil,
        urlString: nil
    )
    ScrollView {
        VStack(spacing: 10) {
            EpisodeView(episode: episode1)
            EpisodeView(episode: episode2)
            EpisodeView(episode: episode3)
            EpisodeView(episode: episode4)
        }
    }
}
