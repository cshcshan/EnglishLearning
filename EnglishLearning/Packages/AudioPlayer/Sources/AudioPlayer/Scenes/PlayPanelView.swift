//
//  PlayPanelView.swift
//  AudioPlayer
//
//  Created by Han Chen on 2024/12/13.
//

import Core
import SwiftUI

public struct PlayPanelView: View {
    typealias ViewStore = Store<ViewState, ViewAction>
    
    @State private var store: ViewStore
    private let audioURL: URL?
    private let audioPlayerMiddleware: AudioPlayerMiddleware
    
    public var body: some View {
        Button {
            Task { await store.send(store.state.isPlaying ? .pause : .play) }
        } label: {
            Image(systemName: store.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
        }
        .task {
            await self.store.send(.setupAudio(audioURL))
        }
    }
    
    public init(audioURL: URL?, audioPlayer: AudioPlayer = .init()) {
        self.audioURL = audioURL
        self.audioPlayerMiddleware = AudioPlayerMiddleware(audioPlayer: audioPlayer)
        self.store = ViewStore(
            initialState: ViewState(isPlaying: false),
            reducer: ViewReducer().process,
            middlewares: [audioPlayerMiddleware.process]
        )
    }
}

extension PlayPanelView {
    struct ViewState {
        let isPlaying: Bool
        let playerError: Error?
        
        init(isPlaying: Bool, playerError: Error? = nil) {
            self.isPlaying = isPlaying
            self.playerError = playerError
        }
    }
    
    enum ViewAction {
        case setupAudio(URL?)
        case play
        case pause
        case forward
        case rewind
        case changeCurrentTime(seconds: CGFloat)
        case speedUp
        case speedDown
        case controlError(Error)
    }
    
    struct ViewReducer {
        let process: ViewStore.Reducer = { state, action in
            // TODO: to complete it
            switch action {
            case .setupAudio:
                return ViewState(isPlaying: false)
            case .play:
                return ViewState(isPlaying: true)
            case .pause:
                return ViewState(isPlaying: false)
            case .forward:
                return state
            case .rewind:
                return state
            case .changeCurrentTime:
                return state
            case .speedUp:
                return state
            case .speedDown:
                return state
            case let .controlError(error):
                return ViewState(isPlaying: state.isPlaying, playerError: error)
            }
        }
    }
    
    @MainActor
    final class AudioPlayerMiddleware {
        private let audioPlayer: AudioPlayer

        lazy var process: ViewStore.Middleware = { [weak self] state, action in
            var selfNullAsyncStream: AsyncStream<ViewAction> {
                AsyncStream {
                    $0.yield(.controlError(ViewError.selfIsNull))
                    $0.finish()
                }
            }

            guard let self else { return selfNullAsyncStream }

            // TODO: to complete it
            switch action {
            case let .setupAudio(url):
                return self.setupAudio(with: url)
            case .play:
                return self.play()
            case .pause:
                return self.pause()
            case .forward:
                return AsyncStream { $0.finish() }
            case .rewind:
                return AsyncStream { $0.finish() }
            case let .changeCurrentTime(seconds):
                return AsyncStream { $0.finish() }
            case .speedUp:
                return AsyncStream { $0.finish() }
            case .speedDown:
                return AsyncStream { $0.finish() }
            case .controlError:
                return AsyncStream { $0.finish() }
            }
        }
        
        init(audioPlayer: AudioPlayer) {
            self.audioPlayer = audioPlayer
        }
        
        private func setupAudio(with url: URL?) -> AsyncStream<ViewAction> {
            AsyncStream { continuation in
                Task {
                    do {
                        try await audioPlayer.setupAudio(url: url)
                    } catch {
                        continuation.yield(.controlError(error))
                    }
                    continuation.finish()
                }
            }
        }
        
        private func play() -> AsyncStream<ViewAction> {
            AsyncStream { continuation in
                Task {
                    do {
                        try await audioPlayer.play()
                    } catch {
                        continuation.yield(.controlError(error))
                    }
                    continuation.finish()
                }
            }
        }
        
        private func pause() -> AsyncStream<ViewAction> {
            AsyncStream { continuation in
                Task {
                    do {
                        try await audioPlayer.pause()
                    } catch {
                        continuation.yield(.controlError(error))
                    }
                    continuation.finish()
                }
            }
        }
    }
    
    enum ViewError: Error {
        case selfIsNull
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    let audioURL = URL(
        string: "https://downloads.bbc.co.uk/learningenglish/features/6min/241114_6_minute_english_the_bond_between_sisters_download.mp3"
    )
    PlayPanelView(audioURL: audioURL)
}
