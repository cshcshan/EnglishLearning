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
        
        static func `default`(with episode: Episode) -> ViewState {
            ViewState(
                title: episode.title,
                imageURL: episode.imageURL,
                scriptAttributedString: nil,
                audioURL: nil,
                fetchDataError: nil
            )
        }
        
        static func build(
            with state: ViewState,
            scriptAttributedString: AttributedString? = nil,
            audioURL: URL? = nil
        ) -> ViewState {
            build(
                with: state,
                scriptAttributedString: scriptAttributedString,
                audioURL: audioURL,
                fetchDataError: state.fetchDataError
            )
        }
        
        static func build(
            with state: ViewState,
            scriptAttributedString: AttributedString? = nil,
            audioURL: URL? = nil,
            fetchDataError: Error?
        ) -> ViewState {
            ViewState(
                title: state.title,
                imageURL: state.imageURL,
                scriptAttributedString: scriptAttributedString ?? state.scriptAttributedString,
                audioURL: audioURL ?? state.audioURL,
                fetchDataError: fetchDataError
            )
        }
    }
    
    enum ViewAction {
        case fetchData
        case confirmErrorAlert
    }
    
    @MainActor
    final class ViewReducer {
        lazy var process: EpisodeDetailStore.Reducer = { [weak self] state, action in
            AsyncStream { continuation in
                Task {
                    defer { continuation.finish() }
                    
                    guard let self else {
                        continuation.yield(.build(with: state, fetchDataError: ViewError.selfIsNull))
                        return
                    }
                    
                    let newState: ViewState
                    
                    switch action {
                    case .fetchData:
                        guard let episodeID = self.episodeID else {
                            continuation.yield(
                                .build(with: state, fetchDataError: ViewError.episodeIDIsNull)
                            )
                            return
                        }
                        
                        do {
                            let episodeDetail = try await self.fetchData(withEpisodeID: episodeID)
                            
                            let attributedString: AttributedString?
                            if let scriptHtml = episodeDetail.scriptHtml {
                                attributedString = try AttributedString.html(scriptHtml, fontSize: "17.0")
                            } else {
                                attributedString = nil
                            }
                            
                            newState = .build(
                                with: state,
                                scriptAttributedString: attributedString,
                                audioURL: episodeDetail.audioURL
                            )
                        } catch {
                            newState = .build(with: state, fetchDataError: error)
                        }
                    case .confirmErrorAlert:
                        newState = .build(with: state, fetchDataError: nil)
                    }
                    
                    continuation.yield(newState)
                }
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
        
        private func fetchData(withEpisodeID episodeID: String) async throws -> EpisodeDetail {
            let predicate = #Predicate<EpisodeDetail> { $0.id == episodeID }
            let fetchDescriptor = FetchDescriptor(predicate: predicate)
            let episodeDetail = try dataSource.fetch(fetchDescriptor).first
            
            if let episodeDetail {
                return episodeDetail
            } else {
                do {
                    return try await fetchDataFromServer()
                } catch {
                    await Log.data.add(error: error)
                    throw error
                }
            }
        }
        
        private func fetchDataFromServer() async throws -> EpisodeDetail {
            do {
                let episodeDetail = try await htmlConvertable.loadEpisodeDetail(
                    withID: episodeID, path: episodePath
                )
                try dataSource.add([episodeDetail])
                return episodeDetail
            } catch {
                await Log.network.add(error: error)
                throw error
            }
        }
    }
    
    enum ViewError: Error {
        case selfIsNull
        case episodeIDIsNull
    }
}

extension EpisodeDetailView.ViewState: CustomStringConvertible {
    var description: String {
        """
        [EpisodeDetailView.ViewState]
        title: \(title ?? "nil")
        imageURL: \(imageURL?.absoluteString ?? "nil")
        scriptAttributedString: \(String(describing: scriptAttributedString))
        audioURL: \(audioURL?.absoluteString ?? "nil")
        fetchDataError: \(fetchDataError.map { $0.localizedDescription } ?? "nil")
        """
    }
}
