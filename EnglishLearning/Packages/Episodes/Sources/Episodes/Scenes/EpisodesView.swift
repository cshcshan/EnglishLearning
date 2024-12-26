//
//  EpisodesView.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/27.
//

import AudioPlayer
import Core
import SwiftUI

public struct EpisodesView: View {
    typealias EpisodesStore = Store<ViewState, ViewAction>

    @State private(set) var store: EpisodesStore
    @State private var playPanelOffsetY: CGFloat = 200
    
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
            .navigationDestination(for: Episode.self) { episode in
                Task { await store.send(.episodeTapped(episode)) }
                return makeDetailView(episode: episode)
            }
        }
        .overlay(alignment: .bottom) {
            if store.state.needsShowPlayPanel {
                makePlayPanelView()
                    // Add `zIndex` for transition animation
                    .zIndex(0)
                    .offset(y: playPanelOffsetY)
                    .onAppear { playPanelOffsetY = .zero }
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                guard gesture.translation.height > 0 else { return }
                                playPanelOffsetY = gesture.translation.height
                            }
                            .onEnded { gesture in
                                if playPanelOffsetY > 100 {
                                    Task { await store.send(.hidePlayPanelView) }
                                } else {
                                    playPanelOffsetY = .zero
                                }
                            }
                    )
                    .animation(.easeInOut, value: playPanelOffsetY)
                    .transition(.move(edge: .bottom))
            }
        }
        .errorAlert(
            isPresented: .constant(store.state.fetchDataError != nil),
            error: store.state.fetchDataError,
            actions: { _ in makeErrorAlertActions() },
            message: { Text($0.recoverySuggestion ?? "") }
        )
        .task {
            NotificationCenter.default.addObserver(
                forName: .episodeDetailLoaded,
                object: nil,
                queue: .main
            ) { notification in
                guard let userInfo = notification.userInfo,
                      let episodeDetail = userInfo["info"] as? EpisodeDetail
                else { return }
                
                Task {
                    await store.send(.episodeDetailLoaded(episodeDetail))
                }
            }
        }
    }
    
    public init(
        htmlConvertable: HtmlConvertable,
        dataSource: DataSource,
        userDefaultsManagerable: UserDefaultsManagerable,
        appGroupFileManagerable: AppGroupFileManagerable,
        widgetManagerable: WidgetManagerable,
        episodeImagePathFormat: String
    ) {
        self.htmlConvertable = htmlConvertable
        self.dataSource = dataSource

        let serverNewEpisodesChecker = ServerEpisodesChecker(dataSource: dataSource)
        self.reducer = ViewReducer(
            htmlConvertable: htmlConvertable,
            dataProvideable: dataSource,
            userDefaultsManagerable: userDefaultsManagerable,
            appGroupFileManagerable: appGroupFileManagerable,
            widgetManagerable: widgetManagerable,
            episodeImagePathFormat: episodeImagePathFormat,
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
                        Task { await self.store.send(.favoriteTapped(episode)) }
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
    
    private func makePlayPanelView() -> some View {
        VStack(spacing: 16) {
            // Add a space to prevent the height of `VStack` from shrunk
            Text(store.state.selectedEpisode?.title ?? " ")
                .font(.title2)
            PlayPanelView(audioURL: .constant(store.state.audioURL))
        }
        .padding(20)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                topTrailingRadius: 16,
                style: .continuous
            )
            .foregroundStyle(.white)
            .shadow(radius: 8)
            .mask(Rectangle().padding(.top, -20))
            .ignoresSafeArea()
        }
    }
}

#Preview("Normal") {
    let episodes = [Episode].dummy(withAmount: 10)

    let mockHtmlConverter = MockHtmlConverter()
    Task { await mockHtmlConverter.setLoadEpisodesResult(.success(episodes)) }
    let dataSource = try! DataSource(with: .mock(isStoredInMemoryOnly: true))

    return EpisodesView(
        htmlConvertable: mockHtmlConverter,
        dataSource: dataSource,
        userDefaultsManagerable: MockUserDefaultsManager(),
        appGroupFileManagerable: MockAppGroupFileManager(),
        widgetManagerable: MockWidgetManager(),
        episodeImagePathFormat: "Images/Episode/%@.png"
    )
}

#Preview("Error") {
    let mockHtmlConverter = MockHtmlConverter()
    Task { await mockHtmlConverter.setLoadEpisodesResult(.failure(DummyError.fetchServerDataError)) }
    let dataSource = try! DataSource(with: .mock(isStoredInMemoryOnly: true))

    return EpisodesView(
        htmlConvertable: mockHtmlConverter,
        dataSource: dataSource,
        userDefaultsManagerable: MockUserDefaultsManager(),
        appGroupFileManagerable: MockAppGroupFileManager(),
        widgetManagerable: MockWidgetManager(),
        episodeImagePathFormat: "Images/Episode/%@.png"
    )
}
