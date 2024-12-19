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
    
    @State private(set) var store: ViewStore
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
                    .frame(width: 80, alignment: .leading)
                
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
                        .frame(maxWidth: .infinity)
                }
                
                Text(store.state.totalTimeString)
                    .frame(width: 80, alignment: .trailing)
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
    
    public init(audioURL: Binding<URL?>, audioPlayable: AudioPlayable = AudioPlayer()) {
        self._audioURL = audioURL
        self.audioPlayerMiddleware = AudioPlayerMiddleware(
            audioPlayable: audioPlayable,
            forwardRewindSeconds: forwardRewindSeconds
        )
        self.store = ViewStore(
            initialState: ViewState(
                canPlay: false,
                isPlaying: false,
                currentSeconds: 0,
                totalSeconds: 0,
                currentTimeString: "--:--",
                totalTimeString: "--:--",
                speedRate: .normal,
                bufferRate: 0,
                playerError: nil
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

#Preview(traits: .sizeThatFitsLayout) {
    let audioURL = URL(
        string: "https://downloads.bbc.co.uk/learningenglish/features/6min/241114_6_minute_english_the_bond_between_sisters_download.mp3"
    )
    PlayPanelView(audioURL: .constant(audioURL))
}
