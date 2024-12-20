//
//  PlayPanelView+Extension.swift
//  AudioPlayer
//
//  Created by Han Chen on 2024/12/19.
//

import Foundation

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
        
        static func build(
            with state: ViewState,
            canPlay: Bool? = nil,
            isPlaying: Bool? = nil,
            currentSeconds: Double? = nil,
            totalSeconds: Double? = nil,
            currentTimeString: String? = nil,
            totalTimeString: String? = nil,
            speedRate: SpeedRate? = nil,
            bufferRate: Double? = nil
        ) -> ViewState {
            build(
                with: state,
                canPlay: canPlay,
                isPlaying: isPlaying,
                currentSeconds: currentSeconds,
                totalSeconds: totalSeconds,
                currentTimeString: currentTimeString,
                totalTimeString: totalTimeString,
                speedRate: speedRate,
                bufferRate: bufferRate,
                playerError: state.playerError
            )
        }
        
        static func build(
            with state: ViewState,
            canPlay: Bool? = nil,
            isPlaying: Bool? = nil,
            currentSeconds: Double? = nil,
            totalSeconds: Double? = nil,
            currentTimeString: String? = nil,
            totalTimeString: String? = nil,
            speedRate: SpeedRate? = nil,
            bufferRate: Double? = nil,
            playerError: Error?
        ) -> ViewState {
            ViewState(
                canPlay: canPlay ?? state.canPlay,
                isPlaying: isPlaying ?? state.isPlaying,
                currentSeconds: currentSeconds ?? state.currentSeconds,
                totalSeconds: totalSeconds ?? state.totalSeconds,
                currentTimeString: currentTimeString ?? state.currentTimeString,
                totalTimeString: totalTimeString ?? state.totalTimeString,
                speedRate: speedRate ?? state.speedRate,
                bufferRate: bufferRate ?? state.bufferRate,
                playerError: playerError
            )
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
        case updateAudioStatus(AudioStatus)
        case updateTime(currentSeconds: Double, totalSeconds: Double)
        case updateBufferRate(Double)
    }
    
    struct ViewReducer {
        let process: ViewStore.Reducer = {
            state,
            action in
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
                return .build(with: state, canPlay: false)
            case .play:
                return .build(with: state, isPlaying: true)
            case .pause:
                return .build(with: state, isPlaying: false)
            case let .speedRate(rate):
                return .build(with: state, speedRate: rate)
            case let .controlError(error):
                return .build(with: state, playerError: error)
            case let .updateAudioStatus(status):
                let isPlaying = [.waitingToPlayAtSpecifiedRate, .playing].contains { $0 == status }
                return .build(with: state, canPlay: status.canPlay, isPlaying: isPlaying)
            case let .updateTime(currentSeconds, totalSeconds):
                return .build(
                    with: state,
                    currentSeconds: currentSeconds,
                    totalSeconds: totalSeconds,
                    currentTimeString: convertTime(currentSeconds),
                    totalTimeString: convertTime(totalSeconds)
                )
            case let .updateBufferRate(rate):
                return .build(with: state, bufferRate: rate)
            case .forward, .rewind, .seek, .observeAudioStatus, .observeAudioTime, .observeBufferRate:
                return state
            }
        }
    }
    
    @MainActor
    final class AudioPlayerMiddleware {
        private let audioPlayable: AudioPlayable
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
                return self.run { try self.audioPlayable.setupAudio(url: url) }
            case .play:
                return self.run { try self.audioPlayable.play(withRate: state.speedRate.rawValue) }
            case .pause:
                return self.run { try self.audioPlayable.pause() }
            case .forward:
                return self.run {
                    try self.audioPlayable.forward(seconds: Double(self.forwardRewindSeconds))
                }
            case .rewind:
                return self.run {
                    try self.audioPlayable.rewind(seconds: Double(self.forwardRewindSeconds))
                }
            case let .seek(seconds):
                return self.run { try self.audioPlayable.seek(toSeconds: seconds) }
            case let .speedRate(rate):
                return self.run {
                    guard state.isPlaying else { return }
                    try self.audioPlayable.speedRate(rate.rawValue)
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
        
        init(audioPlayable: AudioPlayable, forwardRewindSeconds: Int) {
            self.audioPlayable = audioPlayable
            self.forwardRewindSeconds = forwardRewindSeconds
        }
        
        private func observeAudioStatus() -> AsyncStream<ViewAction> {
            AsyncStream { continuation in
                Task {
                    for await status in audioPlayable.audioStatus {
                        continuation.yield(.updateAudioStatus(status))
                    }
                    continuation.finish()
                }
            }
        }
        
        private func observeAudioTime() -> AsyncStream<ViewAction> {
            AsyncStream { continuation in
                Task {
                    for await seconds in audioPlayable.audioSeconds {
                        continuation.yield(
                            .updateTime(currentSeconds: seconds.current, totalSeconds: seconds.total)
                        )
                    }
                    continuation.finish()
                }
            }
        }
        
        private func observeBufferRate() -> AsyncStream<ViewAction> {
            AsyncStream { continuation in
                Task {
                    for await bufferRate in audioPlayable.audioBufferRate {
                        continuation.yield(.updateBufferRate(bufferRate))
                    }
                    continuation.finish()
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
