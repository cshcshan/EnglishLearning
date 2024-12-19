//
//  EpisodeDetailView.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/10.
//

import Core
import AudioPlayer
import SwiftData
import SwiftUI

struct EpisodeDetailView: View {
    typealias EpisodeDetailStore = Store<ViewState, ViewAction>
    
    @State private(set) var store: EpisodeDetailStore
    @State private var playPanelHeight: CGFloat = 0

    private let fetchDetailMiddleware: FetchDetailMiddleware

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
        let reducer = ViewReducer()
        self.fetchDetailMiddleware = FetchDetailMiddleware(
            htmlConvertable: htmlConvertable,
            dataSource: dataSource,
            episodeID: episode.id,
            episodePath: episode.urlString
        )
        self.store = EpisodeDetailStore(
            initialState: ViewState(
                title: episode.title,
                imageURL: episode.imageURL,
                scriptAttributedString: nil,
                audioURL: nil
            ),
            reducer: reducer.process,
            middlewares: [fetchDetailMiddleware.process]
        )
    }
}

extension EpisodeDetailView {
    struct ViewState {
        let title: String?
        let imageURL: URL?
        let scriptAttributedString: AttributedString?
        let audioURL: URL?
        let fetchDataError: Error?
        
        init(
            title: String?,
            imageURL: URL?,
            scriptAttributedString: AttributedString?,
            audioURL: URL?,
            fetchDataError: Error? = nil
        ) {
            self.title = title
            self.imageURL = imageURL
            self.scriptAttributedString = scriptAttributedString
            self.audioURL = audioURL
            self.fetchDataError = fetchDataError
        }
    }
    
    enum ViewAction {
        case fetchData
        case fetchedData(Result<EpisodeDetail, Error>)
        case confirmErrorAlert
    }
    
    struct ViewReducer {
        let process: EpisodeDetailStore.Reducer = { state, action in
            switch action {
            case .fetchData:
                return state
            case let .fetchedData(result):
                switch result {
                case let .success(episodeDetail):
                    let attributedString: AttributedString?
                    if let scriptHtml = episodeDetail.scriptHtml {
                        attributedString = try? AttributedString.html(scriptHtml, fontSize: "17.0")
                    } else {
                        attributedString = nil
                    }
                    
                    return ViewState(
                        title: state.title,
                        imageURL: state.imageURL,
                        scriptAttributedString: attributedString ?? state.scriptAttributedString,
                        audioURL: episodeDetail.audioURL
                    )
                case let .failure(error):
                    return ViewState(
                        title: state.title,
                        imageURL: state.imageURL,
                        scriptAttributedString: state.scriptAttributedString,
                        audioURL: state.audioURL,
                        fetchDataError: error
                    )
                }
            case .confirmErrorAlert:
                return ViewState(
                    title: state.title,
                    imageURL: state.imageURL,
                    scriptAttributedString: state.scriptAttributedString,
                    audioURL: state.audioURL,
                    fetchDataError: nil
                )
            }
        }
    }
    
    @MainActor
    final class FetchDetailMiddleware {
        lazy var process: EpisodeDetailStore.Middleware = { [weak self] state, action in
            switch action {
            case .fetchData:
                guard let self else {
                    return AsyncStream {
                        $0.yield(.fetchedData(.failure(ViewError.selfIsNull)))
                        $0.finish()
                    }
                }
                guard let episodeID else {
                    return AsyncStream {
                        $0.yield(.fetchedData(.failure(ViewError.episodeIDIsNull)))
                        $0.finish()
                    }
                }
                return self.fetchData(withEpisodeID: episodeID)
            case .fetchedData, .confirmErrorAlert:
                return AsyncStream { $0.finish() }
            }
        }
        
        private let htmlConvertable: HtmlConvertable
        private let dataSource: DataSource
        private let episodeID: String?
        private let episodePath: String?
        
        init(
            htmlConvertable: HtmlConvertable,
            dataSource: DataSource,
            episodeID: String?,
            episodePath: String?
        ) {
            self.htmlConvertable = htmlConvertable
            self.dataSource = dataSource
            self.episodeID = episodeID
            self.episodePath = episodePath
        }
        
        private func fetchData(withEpisodeID episodeID: String) -> AsyncStream<ViewAction> {
            let predicate = #Predicate<EpisodeDetail> { $0.id == episodeID }
            let fetchDescriptor = FetchDescriptor(predicate: predicate)

            do {
                guard let episodeDetail = try dataSource.fetch(fetchDescriptor).first else {
                    return fetchDataFromServer()
                }
                return AsyncStream {
                    $0.yield(.fetchedData(.success(episodeDetail)))
                    $0.finish()
                }
            } catch {
                return AsyncStream { continuation in
                    Task {
                        await Log.data.add(error: error)
                        continuation.yield(.fetchedData(.failure(error)))
                        continuation.finish()
                    }
                }
            }
        }
        
        private func fetchDataFromServer() -> AsyncStream<ViewAction> {
            AsyncStream { continuation in
                Task {
                    do {
                        let episodeDetail = try await htmlConvertable.loadEpisodeDetail(
                            withID: episodeID, path: episodePath
                        )
                        
                        if let episodeDetail {
                            try dataSource.add([episodeDetail])
                            continuation.yield(.fetchedData(.success(episodeDetail)))
                        } else {
                            let episodeDetail = EpisodeDetail(id: episodeID)
                            continuation.yield(.fetchedData(.success(episodeDetail)))
                        }
                    } catch {
                        await Log.network.add(error: error)
                        continuation.yield(.fetchedData(.failure(error)))
                    }
                    continuation.finish()
                }
            }
        }
    }
    
    enum ViewError: Error {
        case selfIsNull
        case episodeIDIsNull
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
