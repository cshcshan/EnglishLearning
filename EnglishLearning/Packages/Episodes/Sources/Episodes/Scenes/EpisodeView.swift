//
//  EpisodeView.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/9.
//

import SwiftUI

struct EpisodeView: View {
    let episode: Episode
    let heartTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            EpisodeImageView(imageURL: episode.imageURL)
                .padding(.bottom, 8)    
            
            HStack(alignment: .top) {
                if let title = episode.title {
                    Text(title)
                        .font(.title2)
                        .padding(.bottom, 4)
                }
                
                Spacer()
                
                HeartView(isFavorite: episode.isFavorite)
                    .padding([.horizontal, .bottom], 8)
                    .onTapGesture { heartTapped() }
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
        id: "1",
        title: "Episode Title has multiple lines because it may important",
        desc: "Episode description may have multiple lines to describe what it is",
        date: Date(),
        imageURLString: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg",
        urlString: nil
    )
    let episode2 = Episode(
        id: "2",
        title: "Episode Title",
        desc: "Episode description may have multiple lines to describe what it is",
        date: Date(),
        imageURLString: nil,
        urlString: nil
    )
    let episode3 = Episode(
        id: "3",
        title: nil,
        desc: nil,
        date: Date(),
        imageURLString: nil,
        urlString: nil
    )
    let episode4 = Episode(
        id: "4",
        title: nil,
        desc: nil,
        date: nil,
        imageURLString: nil,
        urlString: nil
    )
    var episodes1 = [episode1, episode2, episode3, episode4]
    var episodes2 = [episode1, episode2, episode3, episode4].map { episode in
        let newEpisode = Episode(
            id: episode.id! + episode.id!,
            title: episode.title,
            desc: episode.desc,
            date: episode.date,
            imageURLString: episode.imageURLString,
            urlString: episode.urlString
        )
        newEpisode.isFavorite = true
        return newEpisode
    }
    
    ScrollView {
        VStack(spacing: 10) {
            ForEach(episodes1, id: \.id) { episode in
                EpisodeView(
                    episode: episode,
                    heartTapped: { print("Heart tapped: \(episode.id)") }
                )
            }
            
            ForEach(episodes2, id: \.id) { episode in
                EpisodeView(
                    episode: episode,
                    heartTapped: { print("Heart tapped: \(episode.id)") }
                )
            }
        }
    }
}
