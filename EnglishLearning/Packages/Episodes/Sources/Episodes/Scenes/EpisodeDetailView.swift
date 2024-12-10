//
//  EpisodeDetailView.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/10.
//

import SwiftUI

struct EpisodeDetailView: View {
    let episode: Episode
    
    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    let episode = Episode(
        id: nil,
        title: "Episode Title has multiple lines because it may important",
        desc: "Episode description may have multiple lines to describe what it is",
        date: Date(),
        imageURLString: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg",
        urlString: nil
    )
    EpisodeDetailView(episode: episode)
}
