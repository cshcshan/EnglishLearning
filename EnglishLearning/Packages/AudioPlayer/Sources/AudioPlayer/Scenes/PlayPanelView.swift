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
    
    enum SpeedRate: Float, CaseIterable {
        case half = 0.5
        case threeQuarters = 0.75
        case normal = 1.0
        case oneAndAHalf = 1.5
        case double = 2.0
        
        var title: String? {
            guard let str = NumberFormatter.default.string(from: NSNumber(value: rawValue)) else {
                return nil
            }
            return "\(str)x"
        }
    }
    
    @State private var store: ViewStore
    private let audioURL: URL?
    private let audioPlayerMiddleware: AudioPlayerMiddleware
    private let forwardRewindSeconds: Int = 10
    
    public var body: some View {
        VStack {
            HStack {
                Button {
                    Task { await store.send(.rewind) }
                } label: {
                    Image(systemName: "gobackward.\(forwardRewindSeconds)")
                }
                Button {
                    Task { await store.send(store.state.isPlaying ? .pause : .play) }
                } label: {
                    Image(systemName: store.state.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                }
                Button {
                    Task { await store.send(.forward) }
                } label: {
                    Image(systemName: "goforward.\(forwardRewindSeconds)")
                }
            }
            
            Picker(
                "",
                selection: Binding(
                    get: { store.state.speedRate },
                    set: { newValue in
                        Task { await store.send(.speedRate(newValue)) }
                    }
                )
            ) {
                ForEach(SpeedRate.allCases, id: \.self) { rate in
                    Text(rate.title ?? "")
                }
            }
            .pickerStyle(.segmented)
            
            Slider(
                value: Binding(
                    get: { store.state.currentSeconds },
                    set: { newValue in
                        Task { await store.send(.seek(toSeconds: newValue)) }
                    }
                ),
                in: 0...store.state.totalSeconds
            )
            
            HStack {
                Text(store.state.currentTimeString)
                Spacer()
                Text(store.state.totalTimeString)
            }
        }
        .disabled(!store.state.canPlay)
        .task { await self.store.send(.observeAudioStatus) }
        .task { await self.store.send(.observeAudioTime) }
        .task { await self.store.send(.setupAudio(audioURL)) }
    }
    
    public init(audioURL: URL?, audioPlayer: AudioPlayer = .init()) {
        self.audioURL = audioURL
        self.audioPlayerMiddleware = AudioPlayerMiddleware(
            audioPlayer: audioPlayer,
            forwardRewindSeconds: forwardRewindSeconds
        )
        self.store = ViewStore(
            initialState: ViewState(
                canPlay: false,
                isPlaying: false,
                currentSeconds: 0,
                totalSeconds: 0,
                currentTime: "--:--",
                totalTime: "--:--",
                speedRate: .normal
            ),
            reducer: ViewReducer().process,
            middlewares: [audioPlayerMiddleware.process]
        )
    }
}

extension PlayPanelView {
    struct ViewState {
        let canPlay: Bool
        let isPlaying: Bool
        let currentSeconds: Double
        let totalSeconds: Double
        let currentTimeString: String
        let totalTimeString: String
        let speedRate: SpeedRate
        let playerError: Error?
        
        init(
            canPlay: Bool,
            isPlaying: Bool,
            currentSeconds: Double,
            totalSeconds: Double,
            currentTime: String,
            totalTime: String,
            speedRate: SpeedRate,
            playerError: Error? = nil
        ) {
            self.canPlay = canPlay
            self.isPlaying = isPlaying
            self.currentSeconds = currentSeconds
            self.totalSeconds = totalSeconds
            self.currentTimeString = currentTime
            self.totalTimeString = totalTime
            self.speedRate = speedRate
            self.playerError = playerError
        }
    }
    
    enum ViewAction {
        case setupAudio(URL?)
        case play
        case pause
        case forward
        case rewind
        case seek(toSeconds: Double)
        case speedRate(SpeedRate)
        case controlError(Error)
        case observeAudioStatus
        case observeAudioTime
        case updateAudioStatus(AudioPlayer.Status)
        case updateTime(currentSeconds: Double, totalSeconds: Double)
    }
    
    struct ViewReducer {
        let process: ViewStore.Reducer = { state, action in
            let convertTime: (Double) -> String = { seconds in
                guard !(seconds.isNaN || seconds.isInfinite) else { return "" }
                let minute = Int(seconds / 60)
                let second = Int(seconds.truncatingRemainder(dividingBy: 60))
                let minuteStr = String(format: "%02d", minute)
                let secondStr = String(format: "%02d", second)
                return "\(minuteStr):\(secondStr)"
            }
            
            switch action {
            case .setupAudio:
                return ViewState(
                    canPlay: false,
                    isPlaying: false,
                    currentSeconds: state.currentSeconds,
                    totalSeconds: state.totalSeconds,
                    currentTime: state.currentTimeString,
                    totalTime: state.totalTimeString,
                    speedRate: state.speedRate
                )
            case .play:
                return ViewState(
                    canPlay: state.canPlay,
                    isPlaying: true,
                    currentSeconds: state.currentSeconds,
                    totalSeconds: state.totalSeconds,
                    currentTime: state.currentTimeString,
                    totalTime: state.totalTimeString,
                    speedRate: state.speedRate
                )
            case .pause:
                return ViewState(
                    canPlay: state.canPlay,
                    isPlaying: false,
                    currentSeconds: state.currentSeconds,
                    totalSeconds: state.totalSeconds,
                    currentTime: state.currentTimeString,
                    totalTime: state.totalTimeString,
                    speedRate: state.speedRate
                )
            case .forward, .rewind, .seek, .observeAudioStatus, .observeAudioTime:
                return state
            case let .speedRate(rate):
                return ViewState(
                    canPlay: state.canPlay,
                    isPlaying: state.isPlaying,
                    currentSeconds: state.currentSeconds,
                    totalSeconds: state.totalSeconds,
                    currentTime: state.currentTimeString,
                    totalTime: state.totalTimeString,
                    speedRate: rate
                )
            case let .controlError(error):
                return ViewState(
                    canPlay: state.canPlay,
                    isPlaying: state.isPlaying,
                    currentSeconds: state.currentSeconds,
                    totalSeconds: state.totalSeconds,
                    currentTime: state.currentTimeString,
                    totalTime: state.totalTimeString,
                    speedRate: state.speedRate,
                    playerError: error
                )
            case let .updateAudioStatus(status):
                return ViewState(
                    canPlay: status.canPlay,
                    isPlaying: [.waitingToPlayAtSpecifiedRate, .playing].contains { $0 == status },
                    currentSeconds: state.currentSeconds,
                    totalSeconds: state.totalSeconds,
                    currentTime: state.currentTimeString,
                    totalTime: state.totalTimeString,
                    speedRate: state.speedRate,
                    playerError: state.playerError
                )
            case let .updateTime(currentSeconds, totalSeconds):
                return ViewState(
                    canPlay: state.canPlay,
                    isPlaying: state.isPlaying,
                    currentSeconds: currentSeconds,
                    totalSeconds: totalSeconds,
                    currentTime: convertTime(currentSeconds),
                    totalTime: convertTime(totalSeconds),
                    speedRate: state.speedRate,
                    playerError: state.playerError
                )
            }
        }
    }
    
    @MainActor
    final class AudioPlayerMiddleware {
        private let audioPlayer: AudioPlayer
        private let forwardRewindSeconds: Int

        lazy var process: ViewStore.Middleware = { [weak self] state, action in
            var selfNullAsyncStream: AsyncStream<ViewAction> {
                AsyncStream {
                    $0.yield(.controlError(ViewError.selfIsNull))
                    $0.finish()
                }
            }

            guard let self else { return selfNullAsyncStream }

            switch action {
            case let .setupAudio(url):
                return self.run { try self.audioPlayer.setupAudio(url: url) }
            case .play:
                return self.run { try self.audioPlayer.play() }
            case .pause:
                return self.run { try self.audioPlayer.pause() }
            case .forward:
                return self.run { try self.audioPlayer.forward(seconds: Double(self.forwardRewindSeconds)) }
            case .rewind:
                return self.run { try self.audioPlayer.rewind(seconds: Double(self.forwardRewindSeconds)) }
            case let .seek(seconds):
                return self.run { try self.audioPlayer.seek(toSeconds: seconds) }
            case let .speedRate(rate):
                return self.run { try self.audioPlayer.speedRate(rate.rawValue) }
            case .observeAudioStatus:
                return self.observeAudioStatus()
            case .observeAudioTime:
                return self.observeAudioTime()
            case .controlError, .updateAudioStatus, .updateTime:
                return AsyncStream { $0.finish() }
            }
        }
        
        init(audioPlayer: AudioPlayer, forwardRewindSeconds: Int) {
            self.audioPlayer = audioPlayer
            self.forwardRewindSeconds = forwardRewindSeconds
        }
        
        private func observeAudioStatus() -> AsyncStream<ViewAction> {
            AsyncStream { continuation in
                Task {
                    guard let status = await audioPlayer.audioStatus else {
                        continuation.finish()
                        return
                    }
                    for await status in status {
                        continuation.yield(.updateAudioStatus(status))
                    }
                }
            }
        }
        
        private func observeAudioTime() -> AsyncStream<ViewAction> {
            AsyncStream { continuation in
                Task {
                    guard let audioSeconds = await audioPlayer.audioSeconds else {
                        continuation.finish()
                        return
                    }
                    for await seconds in audioSeconds {
                        continuation.yield(
                            .updateTime(currentSeconds: seconds.current, totalSeconds: seconds.total)
                        )
                    }
                }
            }
        }
        
        private func run(_ action: @escaping () async throws -> Void) -> AsyncStream<ViewAction> {
            AsyncStream { continuation in
                Task {
                    do {
                        try await action()
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
