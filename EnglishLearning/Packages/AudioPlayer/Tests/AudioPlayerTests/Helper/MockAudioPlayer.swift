//
//  MockAudioPlayer.swift
//  AudioPlayer
//
//  Created by Han Chen on 2024/12/15.
//

import Foundation
@testable import AudioPlayer

final class MockAudioPlayer: AudioPlayable {
    private(set) lazy public var audioSeconds: AsyncStream<AudioSeconds> = {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.audioSecondsContinuation = continuation
        }
    }()
    private(set) var audioSecondsContinuation: AsyncStream<AudioSeconds>.Continuation?
    
    private(set) lazy public var audioStatus: AsyncStream<AudioStatus> = {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.audioStatusContinuation = continuation
        }
    }()
    private(set) var audioStatusContinuation: AsyncStream<AudioStatus>.Continuation?
    
    private(set) lazy public var audioBufferRate: AsyncStream<Double> = {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            self.audioBufferRateContinuation = continuation
        }
    }()
    private(set) var audioBufferRateContinuation: AsyncStream<Double>.Continuation?
    
    private(set) var setupAudioCount = 0
    private(set) var playCount = 0
    private(set) var pauseCount = 0
    private(set) var forwardCount = 0
    private(set) var rewindCount = 0
    private(set) var seekCount = 0
    private(set) var speedRateCount = 0
    
    deinit {
        audioSecondsContinuation?.finish()
        audioStatusContinuation?.finish()
        audioBufferRateContinuation?.finish()
    }
    
    init() {
        // To instance Continuations by call its lazy `AsyncStream`
        _ = self.audioSeconds
        _ = self.audioStatus
        _ = self.audioBufferRate
    }
    
    func setupAudio(url: URL?) throws {
        setupAudioCount += 1
    }
    
    func play(withRate rate: Float?) throws {
        playCount += 1
    }
    
    func pause() throws {
        pauseCount += 1
    }
    
    func forward(seconds: Double) throws {
        forwardCount += 1
    }
    
    func rewind(seconds: Double) throws {
        rewindCount += 1
    }
    
    func seek(toSeconds seconds: Double) throws {
        seekCount += 1
    }
    
    func speedRate(_ rate: Float) throws {
        speedRateCount += 1
    }
}
