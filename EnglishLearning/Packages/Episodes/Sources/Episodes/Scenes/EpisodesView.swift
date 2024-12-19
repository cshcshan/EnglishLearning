//
//  EpisodesView.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/27.
//

import Core
import SwiftUI

public struct EpisodesView: View {
    typealias EpisodesStore = Store<ViewState, ViewAction>

    @State private(set) var store: EpisodesStore
    private let htmlConvertable: HtmlConvertable
    private let dataSource: DataSource
    // Store `fetchEpisodeMiddleware` as a property of `EpisodesView` to prevent `[weak self]` from
    // being null in `FetchEpisodeMiddleware.process`
    private let fetchEpisodeMiddleware: FetchEpisodeMiddleware
    
    public var body: some View {
        NavigationStack {
            List(store.state.episodes) { episode in
                ZStack {
                    // Since `NavigationLink` automatically adds a `>` symbol for each item,
                    // use `EpisodeView` as an overlay on top of the `NavigationLink`
                    // instead of placing `EpisodeView` directly inside the `NavigationLink`.
                    NavigationLink(value: episode) { EmptyView() }.opacity(0)
                    EpisodeView(episode: episode)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .task {
                await store.send(.fetchData(isForce: false))
            }
            .listStyle(.plain)
            // Add the smallest positive integer to avoid the content in the scrollView overlay with
            // status bar when scrolling up
            .padding(.top, 1)
            .navigationDestination(for: Episode.self) { episode in
                EpisodeDetailView(
                    htmlConvertable: htmlConvertable,
                    dataSource: dataSource,
                    episode: episode
                )
            }
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
        }
    }
    
    public init(htmlConvertable: HtmlConvertable, dataSource: DataSource) {
        self.htmlConvertable = htmlConvertable
        self.dataSource = dataSource

        let reducer = ViewReducer()
        let serverNewEpisodesChecker = ServerEpisodesChecker(dataSource: dataSource)
        self.fetchEpisodeMiddleware = FetchEpisodeMiddleware(
            htmlConvertable: htmlConvertable,
            dataProvideable: dataSource,
            hasServerNewEpisodes: serverNewEpisodesChecker.hasServerNewEpisodes(with: Date())
        )
        self.store = EpisodesStore(
            initialState: ViewState(),
            reducer: reducer.process,
            middlewares: [fetchEpisodeMiddleware.process]
        )
    }
}

#Preview {
    let episodes = [Episode].dummy(withAmount: 10)

    let mockHtmlConverter = MockHtmlConverter()
    Task { await mockHtmlConverter.setLoadEpisodesResult(.success(episodes)) }
    let dataSource = try! DataSource(with: .mock(isStoredInMemoryOnly: true))

    return EpisodesView(htmlConvertable: mockHtmlConverter, dataSource: dataSource)
}
