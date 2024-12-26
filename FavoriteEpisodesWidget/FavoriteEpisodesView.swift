//
//  FavoriteEpisodesView.swift
//  EnglishLearning
//
//  Created by Han Chen on 2024/12/26.
//

import Core
import Episodes
import SwiftUI
import WidgetKit

struct FavoriteEpisodesView : View {
    @Environment(\.widgetFamily)
    var widgetFamily
    let entry: FavoriteEpisodesEntry
    let appGroupFileManager = AppGroupFileManager(appGroupURL: FileManager.default.appGroup!)

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            makeVerticalEpisodeView(episode: entry.episodes[safe: 0])
        case .systemMedium:
            HStack(spacing: 16) {
                ForEach(entry.episodes.prefix(2), id: \.id) { episode in
                    makeVerticalEpisodeView(episode: episode)
                }
            }
        case .systemLarge:
            ZStack(alignment: .top) {
                Color.clear

                LazyVGrid(columns: [GridItem()], spacing: 16) {
                    ForEach(entry.episodes.prefix(3), id: \.id) { episode in
                        makeHorizontalEpisodeView(episode: episode)
                    }
                }
            }
        case .systemExtraLarge:
            ZStack(alignment: .top) {
                Color.clear
                
                LazyVGrid(columns: [GridItem(), GridItem()], spacing: 16) {
                    ForEach(entry.episodes.prefix(6), id: \.id) { episode in
                        makeHorizontalEpisodeView(episode: episode)
                    }
                }
            }
        case .accessoryCircular:
            makeAccessoryCircularView(episode: entry.episodes[safe: 0])
        case .accessoryRectangular:
            makeAccessoryRectangularView(episode: entry.episodes[safe: 0])
        case .accessoryInline:
            Text(entry.episodes[safe: 100]?.title ?? "Title is empty")
        @unknown default:
            EmptyView()
        }
    }
    
    private func makeVerticalEpisodeView(episode: Episode?) -> some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                Color.clear

                makeImage(episode: episode, contentMode: .fit)
            }
            
            Text(episode?.title ?? " ")
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.horizontal, 2)
        }
    }
    
    private func makeHorizontalEpisodeView(episode: Episode?) -> some View {
        guard let episode else { return EmptyView() }

        return HStack(spacing: 0) {
            makeImage(episode: episode, contentMode: .fit)
                .frame(maxWidth: 140)
                .padding(.trailing, 12)
            Text(episode.title ?? " ")
                .lineLimit(3)
            
            Spacer()
        }
    }
    
    private func makeAccessoryCircularView(episode: Episode?) -> some View {
        makeImage(episode: episode, contentMode: .fill)
    }
    
    private func makeAccessoryRectangularView(episode: Episode?) -> some View {
        ZStack {
            makeImage(episode: episode, contentMode: .fill)
            
            Text(episode?.title ?? "Title is empty")
                .lineLimit(4)
        }
    }
    
    @ViewBuilder
    private func makeImage(episode: Episode?, contentMode: ContentMode) -> some View {
        // `AsyncImage` in Widget Extension won't download images from the network, so using `Image`
        // instead
        Group {
            if let image = loadEpisodeImage(episode: episode) {
                Image(uiImage: image)
                    .resizable()
            } else {
                Rectangle()
                    .fill(.gray.opacity(0.2))
                    .redacted(reason: .placeholder)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1920 / 1280, contentMode: contentMode)
        .clipShape(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
    
    private func loadEpisodeImage(episode: Episode?) -> UIImage? {
        guard let id = episode?.id else { return nil }
        let imagePath = String(format: Configuration.episodeImagePathFormat, id)
        
        do {
            let data = try appGroupFileManager.load(filename: imagePath)
            return UIImage(data: data)
        } catch {
            Task { await Log.file.add(error: error) }
            return nil
        }
    }
}
