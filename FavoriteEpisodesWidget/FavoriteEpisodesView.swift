//
//  FavoriteEpisodesView.swift
//  EnglishLearning
//
//  Created by Han Chen on 2024/12/26.
//

import SwiftUI
import WidgetKit

struct FavoriteEpisodesView : View {
    @Environment(\.widgetFamily)
    var widgetFamily
    let entry: FavoriteEpisodesEntry

    var body: some View {
        makeSystemSmallView()
    }
    
    private func makeSystemSmallView() -> some View {
        guard let imageURLString = entry.episodes.first?.imageURLString else { return EmptyView() }
        let imageURL = URL(string: imageURLString)

        return VStack {
            AsyncImage(url: imageURL) { image in
                image.resizable()
            } placeholder: {
                Rectangle()
                    .fill(.gray.opacity(0.4))
                    .redacted(reason: .placeholder)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1920 / 1280, contentMode: .fit)
        }
    }
}
