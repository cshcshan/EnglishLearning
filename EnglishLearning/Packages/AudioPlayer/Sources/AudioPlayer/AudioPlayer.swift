//
//  AudioPlayer.swift
//  Core
//
//  Created by Han Chen on 2024/12/13.
//

import Core
import AVFoundation
import Foundation

// Conforms to `NSObject` for observe `status`
public final actor AudioPlayer: NSObject {
    struct AudioSeconds {
        let current: Double
        let total: Double
    }
    
    enum Status {
        case unknown
        case readyToPlay
        case waitingToPlayAtSpecifiedRate
        case playing
        case paused
        case failed
        
        var canPlay: Bool {
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
    
    enum KeyPathName: String {
        case status
        case timeControlStatus
    }

    private(set) lazy var audioSeconds: AsyncStream<AudioSeconds>? = {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.audioSecondsContinuation = continuation
        }
    }()
    private var audioSecondsContinuation: AsyncStream<AudioSeconds>.Continuation?

    private(set) lazy var audioStatus: AsyncStream<Status>? = {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.audioStatusContinuation = continuation
        }
    }()
    private var audioStatusContinuation: AsyncStream<Status>.Continuation?
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    deinit {
        audioSecondsContinuation?.finish()
        audioStatusContinuation?.finish()
        
        player?.removeObserver(self, forKeyPath: KeyPathName.timeControlStatus.rawValue)
        playerItem?.removeObserver(self, forKeyPath: KeyPathName.status.rawValue)
    }

    public override init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback, options: [.allowBluetooth, .allowAirPlay]
            )
        } catch {
            Task { await Log.audio.add(error: error) }
        }
    }
    
    func setupAudio(url: URL?) throws {
        player?.pause()

        guard let url else { throw PlayerError.urlIsWrong }
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        addObservers()
    }
    
    func play(withRate rate: Float? = nil) throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }

        player.rate = rate ?? 1
    }
    
    func pause() throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }
        player.pause()
    }
    
    func forward(seconds: Double = 10) throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }
        
        let newSeconds = CMTimeGetSeconds(player.currentTime()) + seconds
        try seek(toSeconds: newSeconds)
    }
    
    func rewind(seconds: Double = 10) throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }
        
        let newSeconds = CMTimeGetSeconds(player.currentTime()) - seconds
        try seek(toSeconds: newSeconds)
    }
    
    func seek(toSeconds seconds: Double) throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }

        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        player.seek(to: time)
    }
    
    func speedRate(_ rate: Float) throws {
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
        ) { [weak self] time in
            Task {
                let audioSeconds = await AudioSeconds(
                    current: CMTimeGetSeconds(time),
                    total: CMTimeGetSeconds(self?.playerItem?.duration ?? .zero)
                )
                await self?.audioSecondsContinuation?.yield(audioSeconds)
            }
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
            Task { [weak self] in
                guard let player = await self?.player else { return }

                let status = Status(audioStatus: player.status)
                await self?.audioStatusContinuation?.yield(status)
            }
        case .timeControlStatus:
            Task { [weak self] in
                guard let player = await self?.player else { return }

                let status = Status(timeControlStatus: player.timeControlStatus)
                await self?.audioStatusContinuation?.yield(status)
            }
        }
    }
}

extension AudioPlayer {
    enum PlayerError: Error {
        case urlIsWrong
        case playerNotFound
    }
}
