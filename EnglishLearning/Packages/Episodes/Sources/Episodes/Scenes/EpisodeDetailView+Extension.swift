//
//  EpisodeDetailView+Extension.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/19.
//

import Core
import Foundation
import SwiftData

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
