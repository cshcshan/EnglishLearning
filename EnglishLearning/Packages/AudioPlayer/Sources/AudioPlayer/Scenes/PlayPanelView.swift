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
    @Binding private var audioURL: URL?
    private let audioPlayerMiddleware: AudioPlayerMiddleware
    private let forwardRewindSeconds: Int = 10
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                buildButton(
                    withSystemName: "gobackward.\(forwardRewindSeconds)",
                    action: .rewind
                )
                .frame(width: 44, height: 44)

                buildButton(
                    withSystemName: store.state.isPlaying ? "pause.circle.fill" : "play.circle.fill",
                    action: store.state.isPlaying ? .pause : .play
                )
                .frame(width: 52, height: 52)
                
                buildButton(
                    withSystemName: "goforward.\(forwardRewindSeconds)",
                    action: .forward
                )
                .frame(width: 44, height: 44)
            }

            Slider(
                value: Binding(
                    get: { store.state.currentSeconds },
                    set: { newValue in
                        Task { await store.send(.seek(toSeconds: newValue)) }
                    }
                ),
                in: 0...store.state.totalSeconds
            )
            .background {
                ProgressView(value: store.state.bufferRate, total: 1)
                    .tint(.gray)
            }
            
            HStack {
                Text(store.state.currentTimeString)
                
                Menu {
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
                } label: {
                    Text(store.state.speedRate.title ?? "")
                        .font(.title2)
                }
                .frame(maxWidth: .infinity)
                
                Text(store.state.totalTimeString)
            }
        }
        .disabled(!store.state.canPlay)
        .task { await self.store.send(.observeAudioStatus) }
        .task { await self.store.send(.observeAudioTime) }
        .task { await self.store.send(.observeBufferRate) }
        .task { await self.store.send(.setupAudio(audioURL)) }
        .onChange(of: audioURL) {
            Task { await self.store.send(.setupAudio(audioURL)) }
        }
    }
    
    public init(audioURL: Binding<URL?>, audioPlayer: AudioPlayer = .init()) {
        self._audioURL = audioURL
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
                speedRate: .normal,
                bufferRate: 0
            ),
            reducer: ViewReducer().process,
            middlewares: [audioPlayerMiddleware.process]
        )
    }
    
    private func buildButton(
        withSystemName systemName: String,
        action: ViewAction
    ) -> some View {
        Button {
            Task { await store.send(action) }
        } label: {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
        }
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
        let bufferRate: Double
        let playerError: Error?
        
        init(
            canPlay: Bool,
            isPlaying: Bool,
            currentSeconds: Double,
            totalSeconds: Double,
            currentTime: String,
            totalTime: String,
            speedRate: SpeedRate,
            bufferRate: Double,
            playerError: Error? = nil
        ) {
            self.canPlay = canPlay
            self.isPlaying = isPlaying
            self.currentSeconds = currentSeconds
            self.totalSeconds = totalSeconds
            self.currentTimeString = currentTime
            self.totalTimeString = totalTime
            self.speedRate = speedRate
            self.bufferRate = bufferRate
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
        case observeBufferRate
        case updateAudioStatus(AudioPlayer.Status)
        case updateTime(currentSeconds: Double, totalSeconds: Double)
        case updateBufferRate(Double)
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
                    speedRate: state.speedRate,
                    bufferRate: state.bufferRate
                )
            case .play:
                return ViewState(
                    canPlay: state.canPlay,
                    isPlaying: true,
                    currentSeconds: state.currentSeconds,
                    totalSeconds: state.totalSeconds,
                    currentTime: state.currentTimeString,
                    totalTime: state.totalTimeString,
                    speedRate: state.speedRate,
                    bufferRate: state.bufferRate
                )
            case .pause:
                return ViewState(
                    canPlay: state.canPlay,
                    isPlaying: false,
                    currentSeconds: state.currentSeconds,
                    totalSeconds: state.totalSeconds,
                    currentTime: state.currentTimeString,
                    totalTime: state.totalTimeString,
                    speedRate: state.speedRate,
                    bufferRate: state.bufferRate
                )
            case .forward, .rewind, .seek, .observeAudioStatus, .observeAudioTime, .observeBufferRate:
                return state
            case let .speedRate(rate):
                return ViewState(
                    canPlay: state.canPlay,
                    isPlaying: state.isPlaying,
                    currentSeconds: state.currentSeconds,
                    totalSeconds: state.totalSeconds,
                    currentTime: state.currentTimeString,
                    totalTime: state.totalTimeString,
                    speedRate: rate,
                    bufferRate: state.bufferRate
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
                    bufferRate: state.bufferRate,
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
                    bufferRate: state.bufferRate,
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
                    bufferRate: state.bufferRate,
                    playerError: state.playerError
                )
            case let .updateBufferRate(rate):
                return ViewState(
                    canPlay: state.canPlay,
                    isPlaying: state.isPlaying,
                    currentSeconds: state.currentSeconds,
                    totalSeconds: state.totalSeconds,
                    currentTime: state.currentTimeString,
                    totalTime: state.totalTimeString,
                    speedRate: state.speedRate,
                    bufferRate: rate,
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
                return self.run { try self.audioPlayer.play(withRate: state.speedRate.rawValue) }
            case .pause:
                return self.run { try self.audioPlayer.pause() }
            case .forward:
                return self.run { try self.audioPlayer.forward(seconds: Double(self.forwardRewindSeconds)) }
            case .rewind:
                return self.run { try self.audioPlayer.rewind(seconds: Double(self.forwardRewindSeconds)) }
            case let .seek(seconds):
                return self.run { try self.audioPlayer.seek(toSeconds: seconds) }
            case let .speedRate(rate):
                return self.run {
                    guard state.isPlaying else { return }
                    try self.audioPlayer.speedRate(rate.rawValue)
                }
            case .observeAudioStatus:
                return self.observeAudioStatus()
            case .observeAudioTime:
                return self.observeAudioTime()
            case .observeBufferRate:
                return self.observeBufferRate()
            case .controlError, .updateAudioStatus, .updateTime, .updateBufferRate:
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
        
        private func observeBufferRate() -> AsyncStream<ViewAction> {
            AsyncStream { continuation in
                Task {
                    guard let bufferRate = await audioPlayer.audioBufferRate else {
                        continuation.finish()
                        return
                    }
                    for await bufferRate in bufferRate {
                        continuation.yield(.updateBufferRate(bufferRate))
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
    PlayPanelView(audioURL: Binding(get: { audioURL }, set: { _ in }))
}
