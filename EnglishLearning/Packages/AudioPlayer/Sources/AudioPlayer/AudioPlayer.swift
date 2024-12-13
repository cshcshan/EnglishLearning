//
//  AudioPlayer.swift
//  Core
//
//  Created by Han Chen on 2024/12/13.
//

import Core
import AVFoundation
import Foundation

public final actor AudioPlayer {
    struct AudioSeconds {
        let current: Double
        let total: Double
    }

    private(set) lazy var audioSeconds: AsyncStream<AudioSeconds>? = {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.audioSecondsContinuation = continuation
        }
    }()
    private var audioSecondsContinuation: AsyncStream<AudioSeconds>.Continuation?
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    
    deinit {
        audioSecondsContinuation?.finish()
    }

    public init() {
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
        
        addTimeObserver()
    }
    
    func play() throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }
        player.play()
    }
    
    func pause() throws {
        guard let player else {
            let error = PlayerError.playerNotFound
            Task { await Log.audio.add(error: error) }
            throw error
        }
        player.pause()
    }
    
    private func addTimeObserver() {
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
    }
}

extension AudioPlayer {
    enum PlayerError: Error {
        case urlIsWrong
        case playerNotFound
    }
}
