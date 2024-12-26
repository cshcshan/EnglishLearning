//
//  FavoriteEpisodesView.swift
//  EnglishLearning
//
//  Created by Han Chen on 2024/12/26.
//

import Episodes
import SwiftUI
import WidgetKit

struct FavoriteEpisodesView : View {
    @Environment(\.widgetFamily)
    var widgetFamily
    let entry: FavoriteEpisodesEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            makeVerticalEpisodeView(episode: entry.episodes[safe: 0])
        case .systemMedium:
            HStack(spacing: 16) {
                ForEach((0..<2)) { index in
                    makeVerticalEpisodeView(episode: entry.episodes[safe: index])
                }
            }
        case .systemLarge:
            VStack(alignment: .leading, spacing: 16) {
                ForEach((0..<4)) { index in
                    makeHorizontalEpisodeView(episode: entry.episodes[safe: index])
                }

                Spacer()
            }
        case .systemExtraLarge:
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach((0..<4)) { index in
                        makeHorizontalEpisodeView(episode: entry.episodes[safe: index])
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach((4..<8)) { index in
                        makeHorizontalEpisodeView(episode: entry.episodes[safe: index])
                    }
                    
                    Spacer()
                }
            }
        case .accessoryCircular:
            makeAccessoryCircularView(episode: entry.episodes[safe: 100])
        case .accessoryRectangular:
            makeAccessoryRectangularView(episode: entry.episodes[safe: 100])
        case .accessoryInline:
            Text(entry.episodes[safe: 100]?.title ?? "Title is empty")
        @unknown default:
            EmptyView()
        }
    }
    
    private func makeVerticalEpisodeView(episode: Episode?) -> some View {
        let imageURL = URL(string: episode?.imageURLString ?? "")
        
        return ZStack(alignment: imageURL == nil ? .center : .bottom) {
            if let imageURL {
                VStack {
                    makeImage(imageURL: imageURL, contentMode: .fit)
                    
                    Spacer()
                }
            }
            
            Text(episode?.title ?? " ")
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 2)
        }
    }
    
    private func makeHorizontalEpisodeView(episode: Episode?) -> some View {
        guard let episode else { return EmptyView() }

        let imageWidth: CGFloat = 120
        let height: CGFloat = (1080 / 1920) * imageWidth
        let imageURL = URL(string: episode.imageURLString ?? "")
        
        return HStack(spacing: 16) {
            makeImage(imageURL: imageURL, contentMode: .fit)
                .frame(width: imageWidth)
            
            Text(episode.title ?? " ")
        }
        .frame(height: height)
    }
    
    private func makeAccessoryCircularView(episode: Episode?) -> some View {
        let imageURL = URL(string: episode?.imageURLString ?? "")
        return makeImage(imageURL: imageURL, contentMode: .fill)
    }
    
    private func makeAccessoryRectangularView(episode: Episode?) -> some View {
        let imageURL = URL(string: episode?.imageURLString ?? "")

        return ZStack {
            makeImage(imageURL: imageURL, contentMode: .fill)
            
            Text(episode?.title ?? "Title is empty")
                .lineLimit(4)
        }
    }
    
    private func makeImage(imageURL: URL?, contentMode: ContentMode) -> some View {
        AsyncImage(url: imageURL) { image in
            image.resizable()
        } placeholder: {
            Rectangle()
                .fill(.gray.opacity(0.2))
                .redacted(reason: .placeholder)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1920 / 1280, contentMode: contentMode)
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }
}
