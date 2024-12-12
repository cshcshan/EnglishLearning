//
//  EpisodeDetailView.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/10.
//

import Core
import SwiftData
import SwiftUI

struct EpisodeDetailView: View {
    typealias EpisodeDetailStore = Store<ViewState, ViewAction>
    
    @State private(set) var store: EpisodeDetailStore

    private let fetchDetailMiddleware: FetchDetailMiddleware

    var body: some View {
        ScrollView {
            VStack {
                EpisodeImageView(imageURL: store.state.imageURL)
                
                if let attributedString = store.state.scriptAttributedString {
                    Text(attributedString)
                        .padding(10)
                }
            }
            .task {
                await store.send(.fetchData)
            }
        }
        .navigationTitle(store.state.title ?? "")
    }
    
    init(
        htmlConvertable: HtmlConvertable,
        episodeDetailDataSource: DataSource<EpisodeDetail>?,
        episode: Episode
    ) {
        let reducer = ViewReducer()
        self.fetchDetailMiddleware = FetchDetailMiddleware(
            htmlConvertable: htmlConvertable,
            episodeDetailDataSource: episodeDetailDataSource,
            episodeID: episode.id,
            episodePath: episode.urlString
        )
        self.store = EpisodeDetailStore(
            initialState: ViewState(title: episode.title, imageURL: episode.imageURL),
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
        let fetchDataError: Error?
        
        init(
            title: String?,
            imageURL: URL?,
            scriptAttributedString: AttributedString? = nil,
            fetchDataError: Error? = nil
        ) {
            self.title = title
            self.imageURL = imageURL
            self.scriptAttributedString = scriptAttributedString
            self.fetchDataError = fetchDataError
        }
    }
    
    enum ViewAction {
        case fetchData
        case fetchedData(Result<EpisodeDetail, Error>)
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
                        scriptAttributedString: attributedString ?? state.scriptAttributedString
                    )
                case let .failure(error):
                    return ViewState(
                        title: state.title,
                        imageURL: state.imageURL,
                        scriptAttributedString: state.scriptAttributedString,
                        fetchDataError: error
                    )
                }
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
            case .fetchedData:
                return AsyncStream { $0.finish() }
            }
        }
        
        private let htmlConvertable: HtmlConvertable
        private let episodeDetailDataSource: DataSource<EpisodeDetail>?
        private let episodeID: String?
        private let episodePath: String?
        
        init(
            htmlConvertable: HtmlConvertable,
            episodeDetailDataSource: DataSource<EpisodeDetail>?,
            episodeID: String?,
            episodePath: String?
        ) {
            self.htmlConvertable = htmlConvertable
            self.episodeDetailDataSource = episodeDetailDataSource
            self.episodeID = episodeID
            self.episodePath = episodePath
        }
        
        private func fetchData(withEpisodeID episodeID: String) -> AsyncStream<ViewAction> {
            guard let episodeDetailDataSource else {
                return fetchDataFromServer()
            }

            let predicate = #Predicate<EpisodeDetail> { $0.id == episodeID }
            let fetchDescriptor = FetchDescriptor(predicate: predicate)

            do {
                let episodeDetail = try episodeDetailDataSource.fetch(fetchDescriptor).first
                if let episodeDetail {
                    return AsyncStream {
                        $0.yield(.fetchedData(.success(episodeDetail)))
                        $0.finish()
                    }
                } else {
                    return fetchDataFromServer()
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
                            try episodeDetailDataSource?.add([episodeDetail])
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
        scriptHtml: "<p>Hello Swift</p>"
    )

    let mockHtmlConverter = MockHtmlConverter()
    Task { await mockHtmlConverter.setLoadEpisodeDetailResult(.success(episodeDetail)) }
    let episodeDetailDataSource = try! DataSource(for: EpisodeDetail.self, isStoredInMemoryOnly: true)

    return EpisodeDetailView(
        htmlConvertable: mockHtmlConverter,
        episodeDetailDataSource: episodeDetailDataSource,
        episode: episode
    )
}
