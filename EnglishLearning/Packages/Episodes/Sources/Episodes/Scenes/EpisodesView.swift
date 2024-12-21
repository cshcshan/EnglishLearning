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
    // Store `reducer` as a property of `EpisodesView` to prevent `[weak self]` from being null in
    // `ViewReducer.process`
    private let reducer: ViewReducer
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                makeSegmentedControl()
                    .padding()
                makeContent()
            }
            .refreshable { await store.send(.fetchData(isForce: true)) }
            .task { await store.send(.fetchData(isForce: false)) }
            .listStyle(.plain)
            .navigationDestination(for: Episode.self) { makeDetailView(episode: $0) }
            .errorAlert(
                isPresented: .constant(store.state.fetchDataError != nil),
                error: store.state.fetchDataError,
                actions: { _ in makeErrorAlertActions() },
                message: { Text($0.recoverySuggestion ?? "") }
            )
        }
    }
    
    public init(
        htmlConvertable: HtmlConvertable,
        dataSource: DataSource,
        userDefaultsManagerable: UserDefaultsManagerable
    ) {
        self.htmlConvertable = htmlConvertable
        self.dataSource = dataSource

        let serverNewEpisodesChecker = ServerEpisodesChecker(dataSource: dataSource)
        self.reducer = ViewReducer(
            htmlConvertable: htmlConvertable,
            dataProvideable: dataSource,
            userDefaultsManagerable: userDefaultsManagerable,
            hasServerNewEpisodes: serverNewEpisodesChecker.hasServerNewEpisodes(with: Date())
        )
        self.store = EpisodesStore(initialState: .default, reducer: reducer.process)
    }
    
    private func makeSegmentedControl() -> some View {
        Picker(
            "",
            selection: Binding(
                get: { store.state.selectedListType },
                set: { newValue in
                    Task { @MainActor in
                        await store.send(.listTypeTapped(newValue))
                    }
                }
            )
        ) {
            ForEach(ListType.allCases, id: \.self) {
                Text($0.title)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private func makeContent() -> some View {
        GeometryReader { geometry in
            ScrollView(.horizontal) {
                ScrollViewReader { proxy in
                    HStack {
                        makeList(episodes: store.state.allEpisodes)
                            .refreshable {
                                await store.send(.fetchData(isForce: true))
                            }
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .id(ListType.all)
                        
                        makeList(episodes: store.state.favoriteEpisodes)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .id(ListType.favorite)
                    }
                    .onChange(of: store.state.selectedListType) { _, newValue in
                        withAnimation {
                            proxy.scrollTo(newValue)
                        }
                    }
                }
            }
        }
    }
    
    private func makeList(episodes: [Episode]) -> some View {
        List(episodes) { episode in
            ZStack {
                // Since `NavigationLink` automatically adds a `>` symbol for each item,
                // use `EpisodeView` as an overlay on top of the `NavigationLink`
                // instead of placing `EpisodeView` directly inside the `NavigationLink`.
                NavigationLink(value: episode) { EmptyView() }.opacity(0)
                EpisodeView(
                    episode: episode,
                    heartTapped: {
                        guard let id = episode.id else { return }
                        Task {
                            if episode.isFavorite {
                                await self.store.send(.removeFavorite(episodeID: id))
                            } else {
                                await self.store.send(.addFavorite(episodeID: id))
                            }
                        }
                    }
                )
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
    }
    
    private func makeDetailView(episode: Episode) -> some View {
        EpisodeDetailView(
            htmlConvertable: htmlConvertable,
            dataSource: dataSource,
            episode: episode
        )
    }
    
    private func makeErrorAlertActions() -> some View {
        HStack {
            Button(
                action: {
                    Task { await store.send(.confirmErrorAlert) }
                },
                label: { Text("OK") }
            )
            Button(
                action: {
                    Task {
                        await store.send(.confirmErrorAlert)
                        await store.send(.fetchData(isForce: true))
                    }
                },
                label: { Text("Retry") }
            )
        }
    }
}

#Preview {
    let episodes = [Episode].dummy(withAmount: 10)

    let mockHtmlConverter = MockHtmlConverter()
    Task { await mockHtmlConverter.setLoadEpisodesResult(.success(episodes)) }
    let dataSource = try! DataSource(with: .mock(isStoredInMemoryOnly: true))
    
    let mockUserDefaultsManager = MockUserDefaultsManager()

    return EpisodesView(
        htmlConvertable: mockHtmlConverter,
        dataSource: dataSource,
        userDefaultsManagerable: mockUserDefaultsManager
    )
}
