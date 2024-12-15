//
//  PlayPanelViewTests.swift
//  AudioPlayer
//
//  Created by Han Chen on 2024/12/15.
//

import SwiftUI
import Testing
@testable import AudioPlayer

@MainActor
struct PlayPanelViewTests {
    typealias ViewStore = PlayPanelView.ViewStore
    typealias ViewState = PlayPanelView.ViewState
    typealias ViewReducer = PlayPanelView.ViewReducer
    
    @Test func initPlayPanelView() async throws {
        let sut = PlayPanelView(
            audioURL: Binding(get: { nil }, set: { _ in })
        )
        
        #expect(!sut.store.state.canPlay)
        #expect(!sut.store.state.isPlaying)
        #expect(sut.store.state.currentSeconds == 0)
        #expect(sut.store.state.totalSeconds == 0)
        #expect(sut.store.state.currentTimeString == "--:--")
        #expect(sut.store.state.totalTimeString == "--:--")
        #expect(sut.store.state.speedRate == .normal)
        #expect(sut.store.state.bufferRate == 0)
        #expect(sut.store.state.playerError == nil)
    }
}

extension PlayPanelViewTests {
    @Test func setupAudio() async throws {
        let mockAudioPlayer = MockAudioPlayer()
        let audioPlayerMiddleware = PlayPanelView.AudioPlayerMiddleware(
            audioPlayable: mockAudioPlayer,
            forwardRewindSeconds: 10
        )

        let initialState = ViewState.default(canPlay: true)
        let sut = ViewStore(
            initialState: initialState,
            reducer: ViewReducer().process,
            middlewares: [audioPlayerMiddleware.process]
        )
        
        #expect(sut.state.canPlay)
        #expect(mockAudioPlayer.setupAudioCount == 0)
        
        let audioURL = URL(string: "https://english-learning.co/6min/241114.mp3")
        await sut.send(.setupAudio(audioURL))
        
        #expect(!sut.state.canPlay)
        #expect(mockAudioPlayer.setupAudioCount == 1)
    }

    @Test(arguments: [false, true])
    func play(isDefaultPlaying: Bool) async throws {
        let mockAudioPlayer = MockAudioPlayer()
        let audioPlayerMiddleware = PlayPanelView.AudioPlayerMiddleware(
            audioPlayable: mockAudioPlayer,
            forwardRewindSeconds: 10
        )

        let initialState = ViewState.default(isPlaying: isDefaultPlaying)
        let sut = ViewStore(
            initialState: initialState,
            reducer: ViewReducer().process,
            middlewares: [audioPlayerMiddleware.process]
        )
        
        #expect(sut.state.isPlaying == isDefaultPlaying)
        #expect(mockAudioPlayer.playCount == 0)
        
        await sut.send(.play)
        
        #expect(sut.state.isPlaying == true)
        #expect(mockAudioPlayer.playCount == 1)
    }

    @Test(arguments: [false, true])
    func pause(isDefaultPlaying: Bool) async throws {
        let mockAudioPlayer = MockAudioPlayer()
        let audioPlayerMiddleware = PlayPanelView.AudioPlayerMiddleware(
            audioPlayable: mockAudioPlayer,
            forwardRewindSeconds: 10
        )

        let initialState = ViewState.default(isPlaying: isDefaultPlaying)
        let sut = ViewStore(
            initialState: initialState,
            reducer: ViewReducer().process,
            middlewares: [audioPlayerMiddleware.process]
        )
        
        #expect(sut.state.isPlaying == isDefaultPlaying)
        #expect(mockAudioPlayer.pauseCount == 0)
        
        await sut.send(.pause)
        
        #expect(!sut.state.isPlaying)
        #expect(mockAudioPlayer.pauseCount == 1)
    }
    
    @Test(arguments: [false, true])
    func forward(isDefaultPlaying: Bool) async throws {
        let mockAudioPlayer = MockAudioPlayer()
        let audioPlayerMiddleware = PlayPanelView.AudioPlayerMiddleware(
            audioPlayable: mockAudioPlayer,
            forwardRewindSeconds: 10
        )

        let initialState = ViewState.default(isPlaying: isDefaultPlaying)
        let sut = PlayPanelView.ViewStore(
            initialState: initialState,
            reducer: ViewReducer().process,
            middlewares: [audioPlayerMiddleware.process]
        )
        
        #expect(sut.state.isPlaying == isDefaultPlaying)
        #expect(mockAudioPlayer.forwardCount == 0)
        
        await sut.send(.forward)
        
        #expect(sut.state.isPlaying == isDefaultPlaying)
        #expect(mockAudioPlayer.forwardCount == 1)
    }
    
    @Test(arguments: [false, true])
    func rewind(isDefaultPlaying: Bool) async throws {
        let mockAudioPlayer = MockAudioPlayer()
        let audioPlayerMiddleware = PlayPanelView.AudioPlayerMiddleware(
            audioPlayable: mockAudioPlayer,
            forwardRewindSeconds: 10
        )

        let initialState = ViewState.default(isPlaying: isDefaultPlaying)
        let sut = PlayPanelView.ViewStore(
            initialState: initialState,
            reducer: ViewReducer().process,
            middlewares: [audioPlayerMiddleware.process]
        )
        
        #expect(sut.state.isPlaying == isDefaultPlaying)
        #expect(mockAudioPlayer.rewindCount == 0)
        
        await sut.send(.rewind)
        
        #expect(sut.state.isPlaying == isDefaultPlaying)
        #expect(mockAudioPlayer.rewindCount == 1)
    }
    
    @Test(arguments: [false, true])
    func seek(isDefaultPlaying: Bool) async throws {
        let mockAudioPlayer = MockAudioPlayer()
        let audioPlayerMiddleware = PlayPanelView.AudioPlayerMiddleware(
            audioPlayable: mockAudioPlayer,
            forwardRewindSeconds: 10
        )

        let initialState = ViewState.default(isPlaying: isDefaultPlaying)
        let sut = PlayPanelView.ViewStore(
            initialState: initialState,
            reducer: ViewReducer().process,
            middlewares: [audioPlayerMiddleware.process]
        )
        
        #expect(sut.state.isPlaying == isDefaultPlaying)
        #expect(mockAudioPlayer.seekCount == 0)
        
        await sut.send(.seek(toSeconds: 0))
        
        #expect(sut.state.isPlaying == isDefaultPlaying)
        #expect(mockAudioPlayer.seekCount == 1)
    }
    
    @Test(arguments: [false, true])
    func speedRate(isDefaultPlaying: Bool) async throws {
        let mockAudioPlayer = MockAudioPlayer()
        let audioPlayerMiddleware = PlayPanelView.AudioPlayerMiddleware(
            audioPlayable: mockAudioPlayer,
            forwardRewindSeconds: 10
        )

        let initialState = ViewState.default(isPlaying: isDefaultPlaying)
        let sut = PlayPanelView.ViewStore(
            initialState: initialState,
            reducer: ViewReducer().process,
            middlewares: [audioPlayerMiddleware.process]
        )
        
        #expect(sut.state.isPlaying == isDefaultPlaying)
        #expect(mockAudioPlayer.speedRateCount == 0)
        
        await sut.send(.speedRate(.double))
        
        #expect(sut.state.isPlaying == isDefaultPlaying)
        let expectedSpeedRateCount = isDefaultPlaying ? 1 : 0
        #expect(mockAudioPlayer.speedRateCount == expectedSpeedRateCount)
    }
    
    @Test func observeAudioStatus() async throws {
        let mockAudioPlayer = MockAudioPlayer()
        let audioPlayerMiddleware = PlayPanelView.AudioPlayerMiddleware(
            audioPlayable: mockAudioPlayer,
            forwardRewindSeconds: 10
        )

        let initialState = ViewState.default(canPlay: true)
        let sut = PlayPanelView.ViewStore(
            initialState: initialState,
            reducer: ViewReducer().process,
            middlewares: [audioPlayerMiddleware.process]
        )
        
        var audioStatusCount = 0
        for await audioStatus in mockAudioPlayer.audioStatus {
            audioStatusCount += 1
        }
        
        await sut.send(.observeAudioStatus)
        mockAudioPlayer.yieldAudioStatus(.failed)
        
        #expect(audioStatusCount == 1)
        #expect(!sut.state.canPlay)
    }
}

extension PlayPanelView.ViewState {
    static func `default`(
        canPlay: Bool? = nil,
        isPlaying: Bool? = nil,
        currentSeconds: Double? = nil,
        totalSeconds: Double? = nil,
        currentTimeString: String? = nil,
        totalTimeString: String? = nil,
        speedRate: PlayPanelView.SpeedRate? = nil,
        bufferRate: Double? = nil
    ) -> Self {
        PlayPanelView.ViewState(
            canPlay: canPlay ?? false,
            isPlaying: isPlaying ?? false,
            currentSeconds: currentSeconds ?? 0,
            totalSeconds: totalSeconds ?? 0,
            currentTimeString: currentTimeString ?? "--:--",
            totalTimeString: totalTimeString ?? "--:--",
            speedRate: speedRate ?? .normal,
            bufferRate: bufferRate ?? 0,
            playerError: nil
        )
    }
}

extension PlayPanelView.ViewState: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        let hasLHSError = lhs.playerError != nil
        let hasRHSError = rhs.playerError != nil
        
        return lhs.canPlay == rhs.canPlay
            && lhs.isPlaying == rhs.isPlaying
            && lhs.currentSeconds == rhs.currentSeconds
            && lhs.totalSeconds == rhs.totalSeconds
            && lhs.currentTimeString == rhs.currentTimeString
            && lhs.totalTimeString == rhs.totalTimeString
            && lhs.speedRate == rhs.speedRate
            && lhs.bufferRate == rhs.bufferRate
            && hasLHSError == hasRHSError
    }
}
