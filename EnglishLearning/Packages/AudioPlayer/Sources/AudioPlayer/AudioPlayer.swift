//
//  AudioPlayer.swift
//  AudioPlayer
//
//  Created by Han Chen on 2024/12/13.
//

import Core
import AVFoundation
import Foundation

public protocol AudioPlayable {
    var audioSeconds: AsyncStream<AudioSeconds> { get }
    var audioStatus: AsyncStream<AudioStatus> { get }
    var audioBufferRate: AsyncStream<Double> { get }

    func setupAudio(url: URL?) throws
    func play(withRate rate: Float?) throws
    func pause() throws
    func forward(seconds: Double) throws
    func rewind(seconds: Double) throws
    func seek(toSeconds seconds: Double) throws
    func speedRate(_ rate: Float) throws
}

public enum AudioStatus: Sendable {
    case unknown
    case readyToPlay
    case waitingToPlayAtSpecifiedRate
    case playing
    case paused
    case failed
    
    public var canPlay: Bool {
        switch self {
        case .readyToPlay, .waitingToPlayAtSpecifiedRate, .playing, .paused:
            return true
        case .unknown, .failed:
            return false
        }
    }
    
    init(audioStatus: AVPlayer.Status) {
        switch audioStatus {
        case .unknown: self = .unknown
        case .readyToPlay: self = .readyToPlay
        case .failed: self = .failed
        @unknown default: self = .unknown
        }
    }
    
    init(timeControlStatus: AVPlayer.TimeControlStatus) {
        switch timeControlStatus {
        case .paused: self = .paused
        case .waitingToPlayAtSpecifiedRate: self = .waitingToPlayAtSpecifiedRate
        case .playing: self = .playing
        @unknown default: self = .unknown
        }
    }
}

public struct AudioSeconds: Sendable {
    let current: Double
    let total: Double
}

// Conforms to `NSObject` for observe `status`
public final class AudioPlayer: NSObject, AudioPlayable {
    
    enum KeyPathName: String {
        case status
        case timeControlStatus
        case loadedTimeRanges
    }

    public let audioSeconds: AsyncStream<AudioSeconds>
    private let audioSecondsContinuation: AsyncStream<AudioSeconds>.Continuation

    public let audioStatus: AsyncStream<AudioStatus>
    private let audioStatusContinuation: AsyncStream<AudioStatus>.Continuation

    public let audioBufferRate: AsyncStream<Double>
    private let audioBufferRateContinuation: AsyncStream<Double>.Continuation
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    deinit {
        print("deinit \(URL(string: #filePath)!.lastPathComponent)")
        
        audioSecondsContinuation.finish()
        audioStatusContinuation.finish()
        audioBufferRateContinuation.finish()
        
        player?.removeObserver(self, forKeyPath: KeyPathName.timeControlStatus.rawValue)
        playerItem?.removeObserver(self, forKeyPath: KeyPathName.status.rawValue)
        playerItem?.removeObserver(self, forKeyPath: KeyPathName.loadedTimeRanges.rawValue)
    }

    public override init() {
        let (audioSeconds, audioSecondsContinuation) = AsyncStream<AudioSeconds>.makeStream()
        self.audioSeconds = audioSeconds
        self.audioSecondsContinuation = audioSecondsContinuation
        
        let (audioStatus, audioStatusContinuation) = AsyncStream<AudioStatus>.makeStream()
        self.audioStatus = audioStatus
        self.audioStatusContinuation = audioStatusContinuation
        
        let (audioBufferRate, audioBufferRateContinuation) = AsyncStream<Double>.makeStream()
        self.audioBufferRate = audioBufferRate
        self.audioBufferRateContinuation = audioBufferRateContinuation

        super.init()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback, options: [.allowBluetooth, .allowAirPlay]
            )
        } catch {
            Task { await Log.audio.add(error: error) }
        }
    }
    
    public func setupAudio(url: URL?) throws {
        player?.pause()

        guard let url else { throw PlayerError.urlIsWrong }
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        addObservers()
    }
    
    public func play(withRate rate: Float? = nil) throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }

        player.rate = rate ?? 1
    }
    
    public func pause() throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }
        player.pause()
    }
    
    public func forward(seconds: Double = 10) throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }
        
        let newSeconds = CMTimeGetSeconds(player.currentTime()) + seconds
        try seek(toSeconds: newSeconds)
    }
    
    public func rewind(seconds: Double = 10) throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }
        
        let newSeconds = CMTimeGetSeconds(player.currentTime()) - seconds
        try seek(toSeconds: newSeconds)
    }
    
    public func seek(toSeconds seconds: Double) throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }

        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        player.seek(to: time)
    }
    
    public func speedRate(_ rate: Float) throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }
        
        // If the audio is not playing but its player rate is set above 0, the audio will start
        // playing immediately.
        player.rate = rate
    }
    
    private func addObservers() {
        player?.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 1),
            queue: .main
        ) { [weak playerItem, audioSecondsContinuation] time in
            let audioSeconds = AudioSeconds(
                current: CMTimeGetSeconds(time),
                total: CMTimeGetSeconds(playerItem?.duration ?? .zero)
            )
            audioSecondsContinuation.yield(audioSeconds)
        }
        
        player?.addObserver(
            self,
            forKeyPath: KeyPathName.timeControlStatus.rawValue,
            options: [.old, .new],
            context: nil
        )
        
        playerItem?.addObserver(
            self,
            forKeyPath: KeyPathName.status.rawValue,
            options: [.old, .new],
            context: nil
        )
        
        playerItem?.addObserver(
            self,
            forKeyPath: KeyPathName.loadedTimeRanges.rawValue,
            options: [.old, .new],
            context: nil
        )
    }
    
    // For observing `KeyPathName`
    nonisolated override public func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let keyPath, let keyPathName = KeyPathName(rawValue: keyPath) else { return }

        switch keyPathName {
        case .status:
            guard let player else { return }

            let status = AudioStatus(audioStatus: player.status)
            audioStatusContinuation.yield(status)
        case .timeControlStatus:
            guard let player else { return }

            let status = AudioStatus(timeControlStatus: player.timeControlStatus)
            audioStatusContinuation.yield(status)
        case .loadedTimeRanges:
            guard let playerItem = playerItem,
                  let timeRangeValue = playerItem.loadedTimeRanges.first?.timeRangeValue
            else { return }

            let bufferSeconds = CMTimeGetSeconds(timeRangeValue.start + timeRangeValue.duration)
            let duration = CMTimeGetSeconds(playerItem.duration)
            let rate = bufferSeconds / duration
            audioBufferRateContinuation.yield(rate)
        }
    }
}

extension AudioPlayer {
    enum PlayerError: Error {
        case urlIsWrong
        case playerNotFound
    }
}
