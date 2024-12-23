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
        case updateAudioStatus(AudioStatus)
        case observeAudioTime
        case updateAudioTime(AudioSeconds)
        case observeBufferRate
        case updateBufferRate(Double)
    }
    
    @MainActor
    final class ViewReducer {
        lazy var process: ViewStore.Reducer = { [weak self] state, action in
            AsyncStream { continuation in
                Task {
                    defer { continuation.finish() }
                    
                    guard let self else {
                        continuation.yield(
                            .state(.build(with: state, playerError: ViewError.selfIsNull))
                        )
                        return
                    }
                    
                    switch action {
                    case let .setupAudio(url):
                        let newState = ViewState.build(with: state, canPlay: false)
                        continuation.yield(.state(newState))
                        
                        do {
                            try self.audioPlayable.setupAudio(url: url)
                        } catch {
                            let newState = ViewState.build(with: state, playerError: error)
                            continuation.yield(.state(newState))
                        }
                    case .play:
                        let newState = ViewState.build(with: state, isPlaying: true)
                        continuation.yield(.state(newState))
                        
                        do {
                            try self.audioPlayable.play(withRate: state.speedRate.rawValue)
                        } catch {
                            let newState = ViewState.build(with: state, playerError: error)
                            continuation.yield(.state(newState))
                        }
                    case .pause:
                        let newState = ViewState.build(with: state, isPlaying: false)
                        continuation.yield(.state(newState))
                        
                        do {
                            try self.audioPlayable.pause()
                        } catch {
                            let newState = ViewState.build(with: state, playerError: error)
                            continuation.yield(.state(newState))
                        }
                    case .forward:
                        do {
                            try self.audioPlayable.forward(seconds: Double(self.forwardRewindSeconds))
                        } catch {
                            let newState = ViewState.build(with: state, playerError: error)
                            continuation.yield(.state(newState))
                        }
                    case .rewind:
                        do {
                            try self.audioPlayable.rewind(seconds: Double(self.forwardRewindSeconds))
                        } catch {
                            let newState = ViewState.build(with: state, playerError: error)
                            continuation.yield(.state(newState))
                        }
                    case let .seek(seconds):
                        do {
                            try self.audioPlayable.seek(toSeconds: seconds)
                        } catch {
                            let newState = ViewState.build(with: state, playerError: error)
                            continuation.yield(.state(newState))
                        }
                    case let .speedRate(rate):
                        let newState = ViewState.build(with: state, speedRate: rate)
                        continuation.yield(.state(newState))
                        
                        guard state.isPlaying else { return }
                        do {
                            try self.audioPlayable.speedRate(rate.rawValue)
                        } catch {
                            let newState = ViewState.build(with: state, playerError: error)
                            continuation.yield(.state(newState))
                        }
                    case let .controlError(error):
                        let newState = ViewState.build(with: state, playerError: error)
                        continuation.yield(.state(newState))
                    case .observeAudioStatus:
                        for await status in self.audioPlayable.audioStatus {
                            continuation.yield(.action(.updateAudioStatus(status)))
                        }
                    case let .updateAudioStatus(status):
                        let isPlaying = [.waitingToPlayAtSpecifiedRate, .playing].contains {
                            $0 == status
                        }
                        let newState = ViewState.build(
                            with: state, canPlay: status.canPlay, isPlaying: isPlaying
                        )
                        continuation.yield(.state(newState))
                    case .observeAudioTime:
                        for await seconds in self.audioPlayable.audioSeconds {
                            continuation.yield(.action(.updateAudioTime(seconds)))
                        }
                    case let .updateAudioTime(seconds):
                        let newState = ViewState.build(
                            with: state,
                            currentSeconds: seconds.current,
                            totalSeconds: seconds.total,
                            currentTimeString: self.convertTime(seconds: seconds.current),
                            totalTimeString: self.convertTime(seconds: seconds.total)
                        )
                        continuation.yield(.state(newState))
                    case .observeBufferRate:
                        for await rate in self.audioPlayable.audioBufferRate {
                            continuation.yield(.action(.updateBufferRate(rate)))
                        }
                    case let .updateBufferRate(rate):
                        let newState = ViewState.build(with: state, bufferRate: rate)
                        continuation.yield(.state(newState))
                    }
                }
            }
        }
        
        private let audioPlayable: AudioPlayable
        private let forwardRewindSeconds: Int
        
        deinit {
            print("deinit \(URL(string: #filePath)!.lastPathComponent)")
        }
        
        init(audioPlayable: AudioPlayable, forwardRewindSeconds: Int) {
            self.audioPlayable = audioPlayable
            self.forwardRewindSeconds = forwardRewindSeconds
        }
        
        private func convertTime(seconds: Double) -> String {
            guard !(seconds.isNaN || seconds.isInfinite) else { return "" }
            
            let minute = Int(seconds / 60)
            let second = Int(seconds.truncatingRemainder(dividingBy: 60))
            return String(format: "%02d:%02d", minute, second)
        }
    }
    
    enum ViewError: Error {
        case selfIsNull
    }
}
