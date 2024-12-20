//
//  EpisodeDetailView.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/10.
//

import Core
import AudioPlayer
import SwiftUI

struct EpisodeDetailView: View {
    typealias EpisodeDetailStore = Store<ViewState, ViewAction>
    
    @State private(set) var store: EpisodeDetailStore
    private let reducer: ViewReducer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack {
                    EpisodeImageView(imageURL: store.state.imageURL)
                    
                    if let attributedString = store.state.scriptAttributedString {
                        Text(attributedString)
                            .padding(10)
                    }
                }
            }
            
            PlayPanelView(audioURL: .constant(store.state.audioURL))
                .padding(20)
                .background {
                    Color.white
                        .shadow(radius: 8)
                        .mask(Rectangle().padding(.top, -20))
                        .ignoresSafeArea()
                }
        }
        .navigationTitle(store.state.title ?? "")
        .errorAlert(
            isPresented: .constant(store.state.fetchDataError != nil),
            error: store.state.fetchDataError,
            actions: { error in
                Button(
                    action: {
                        Task { await store.send(.confirmErrorAlert) }
                    },
                    label: { Text("OK") }
                )
            },
            message: { error in Text(error.recoverySuggestion ?? "") }
        )
        .task { await store.send(.fetchData) }
    }
    
    init(
        htmlConvertable: HtmlConvertable,
        dataSource: DataSource,
        episode: Episode
    ) {
        self.reducer = ViewReducer(
            htmlConvertable: htmlConvertable,
            dataSource: dataSource,
            episodeID: episode.id,
            episodePath: episode.urlString
        )
        self.store = EpisodeDetailStore(
            initialState: .default(with: episode),
            reducer: reducer.process
        )
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let episode = Episode(
        id: "Episode 241205",
        title: "Can you trust ancestry DNA kits?",
        desc: "Are DNA ancestry tests a reliable way to trace your ancestry?",
        date: Date(),
        imageURLString: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg",
        urlString: "/learningenglish/english/features/6-minute-english_2024/ep-241205"
    )
    let episodeDetail = EpisodeDetail(
        id: "Episode 241205",
        audioLink: "https://downloads.bbc.co.uk/learningenglish/features/6min/241114_6_minute_english_the_bond_between_sisters_download.mp3",
        scriptHtml: "<p>Hello Swift</p>"
    )

    let mockHtmlConverter = MockHtmlConverter()
    Task { await mockHtmlConverter.setLoadEpisodeDetailResult(.success(episodeDetail)) }
    let dataSource = try! DataSource(with: .mock(isStoredInMemoryOnly: true))

    return EpisodeDetailView(
        htmlConvertable: mockHtmlConverter,
        dataSource: dataSource,
        episode: episode
    )
}
