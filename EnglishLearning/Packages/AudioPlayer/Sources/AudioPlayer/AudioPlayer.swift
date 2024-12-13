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
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?

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
}

extension AudioPlayer {
    enum PlayerError: Error {
        case urlIsWrong
        case playerNotFound
    }
}
