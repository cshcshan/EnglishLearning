//
//  EpisodesViewTests.swift
//  Episodes
//
//  Created by Han Chen on 2024/11/29.
//

import Core
import Foundation
import SwiftData
import Testing
@testable import Episodes

@MainActor
struct EpisodesViewTests {
    typealias ViewStore = EpisodesView.EpisodesStore
    typealias ViewState = EpisodesView.ViewState
    typealias ViewReducer = EpisodesView.ViewReducer
    
    struct Arguments {
        let isFetching: Bool
        let isForceFetch: Bool
        let hasServerNewEpisodes: Bool
        let expectedStates: [ViewState]
        let expectedLoadEpisodesCount: Int
    }
    
    struct FetchDataFavoriteArguments {
        let localAllEpisodes: [Episode]
        let favoriteEpisodeIDs: Set<String>
        let expectedAllEpisodes: [Episode]
        let expectedFavoriteEpisodes: [Episode]
    }

    struct ErrorArguments {
        let isFetching: Bool
        let isForceFetch: Bool
        let expectedStates: [ViewState]
        let expectedLoadLocalEpisodesCount: Int
        let expectedLoadServerEpisodesCount: Int
    }

    struct ConfirmErrorArguments {
        let isFetching: Bool
        let hasEpisodes: Bool
    }
    
    struct AddFavorite {
        let initialEpisodes: [Episode]
        let initialFavoriteEpisodes: [Episode]
        let addEpisodeID: String
        let expectedAllEpisodes: [Episode]
        let expectedFavoriteEpisodes: [Episode]
    }
    
    struct RemoveFavorite {
        let initialEpisodes: [Episode]
        let initialFavoriteEpisodes: [Episode]
        let removeEpisodeID: String
        let expectedAllEpisodes: [Episode]
        let expectedFavoriteEpisodes: [Episode]
    }
    
    struct EpisodeDetailLoaded {
        let episodeDetail: EpisodeDetail
        let expectedNeedsPlayPanel: Bool
        let expectedAudioURL: URL?
    }
    
    @Test(
        arguments: [
            Arguments(
                isFetching: false,
                isForceFetch: true,
                hasServerNewEpisodes: true,
                expectedStates: [
                    .build(with: .default, isFetchingData: true),
                    .build(with: .default, allEpisodes: .serverEpisodes)
                ],
                expectedLoadEpisodesCount: 1
            ),
            Arguments(
                isFetching: false,
                isForceFetch: false,
                hasServerNewEpisodes: true,
                expectedStates: [
                    .build(with: .default, isFetchingData: true),
                    .build(with: .default, allEpisodes: .serverEpisodes)
                ],
                expectedLoadEpisodesCount: 1
            ),
            Arguments(
                isFetching: false,
                isForceFetch: false,
                hasServerNewEpisodes: false,
                expectedStates: [.build(with: .default, allEpisodes: .localEpisodes)],
                expectedLoadEpisodesCount: 0
            ),
            Arguments(
                isFetching: true,
                isForceFetch: true,
                hasServerNewEpisodes: true,
                expectedStates: [.build(with: .default, isFetchingData: true)],
                expectedLoadEpisodesCount: 0
            ),
            // Others
            Arguments(
                isFetching: false,
                isForceFetch: true,
                hasServerNewEpisodes: false,
                expectedStates: [
                    .build(with: .default, isFetchingData: true),
                    .build(with: .default, allEpisodes: .serverEpisodes)
                ],
                expectedLoadEpisodesCount: 1
            )
        ]
    )
    func fetchData(arguments: Arguments) async throws {
        let isFetching = arguments.isFetching
        let isForceFetch = arguments.isForceFetch
        let localEpisodes: [Episode] = .localEpisodes
        let serverEpisodes: [Episode] = .serverEpisodes
        let hasServerNewEpisodes = arguments.hasServerNewEpisodes

        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = try DataSource.mock(with: localEpisodes)

        let reducer = EpisodesView.ViewReducer(
            htmlConvertable: mockHtmlConverter,
            dataProvideable: mockDataSource,
            userDefaultsManagerable: MockUserDefaultsManager(),
            widgetManagerable: MockWidgetManager(),
            hasServerNewEpisodes: hasServerNewEpisodes
        )
        
        let sut = ViewStore(
            initialState: .build(with: .default, isFetchingData: isFetching),
            reducer: reducer.process
        )
        
        var actualStates: [ViewState] = []
        startObserving(sut) {
            Task { @MainActor in
                actualStates.append(sut.state)
            }
        }
        
        Task { await mockHtmlConverter.setLoadEpisodesResult(.success(serverEpisodes)) }
        await sut.send(.fetchData(isForce: isForceFetch))
        
        #expect(actualStates == arguments.expectedStates)
        #expect(await mockHtmlConverter.loadEpisodesCount == arguments.expectedLoadEpisodesCount)
    }
    
    @Test(arguments: [
        FetchDataFavoriteArguments(
            localAllEpisodes: [],
            favoriteEpisodeIDs: [],
            expectedAllEpisodes: [],
            expectedFavoriteEpisodes: []
        ),
        FetchDataFavoriteArguments(
            localAllEpisodes: [.dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3")],
            favoriteEpisodeIDs: ["2"],
            expectedAllEpisodes: [
                .dummy(id: "1"), .dummyFav(id: "2"), .dummy(id: "3")
            ],
            expectedFavoriteEpisodes: [.dummyFav(id: "2")]
        ),
        FetchDataFavoriteArguments(
            localAllEpisodes: [],
            favoriteEpisodeIDs: ["10"],
            expectedAllEpisodes: [],
            expectedFavoriteEpisodes: []
        ),
        FetchDataFavoriteArguments(
            localAllEpisodes: [.dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3")],
            favoriteEpisodeIDs: ["2", "3"],
            expectedAllEpisodes: [
                .dummy(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3")
            ],
            expectedFavoriteEpisodes: [.dummyFav(id: "2"), .dummyFav(id: "3")]
        ),
        FetchDataFavoriteArguments(
            localAllEpisodes: [.dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3")],
            favoriteEpisodeIDs: ["2", "4"],
            expectedAllEpisodes: [
                .dummy(id: "1"), .dummyFav(id: "2"), .dummy(id: "3")
            ],
            expectedFavoriteEpisodes: [.dummyFav(id: "2")]
        )
    ])
    func fetchData_favEpisodes(arguments: FetchDataFavoriteArguments) async throws {
        let mockDataSource = try DataSource.mock(with: arguments.localAllEpisodes)
        let mockUserDefaultsManager = MockUserDefaultsManager(
            favoriteEpisodeIDs: arguments.favoriteEpisodeIDs
        )
        let reducer = EpisodesView.ViewReducer(
            htmlConvertable: MockHtmlConverter(),
            dataProvideable: mockDataSource,
            userDefaultsManagerable: mockUserDefaultsManager,
            widgetManagerable: MockWidgetManager(),
            hasServerNewEpisodes: false
        )
        
        let sut = ViewStore(
            initialState: .default,
            reducer: reducer.process
        )
        
        await sut.send(.fetchData(isForce: false))
        
        let expectedViewState = ViewState(
            isFetchingData: false,
            allEpisodes: arguments.expectedAllEpisodes,
            favoriteEpisodes: arguments.expectedFavoriteEpisodes,
            selectedListType: .all,
            selectedEpisode: nil,
            needsShowPlayPanel: false,
            audioURL: nil,
            fetchDataError: nil
        )
        #expect(sut.state == expectedViewState)
    }
    
    @Test(
        arguments: [
            ErrorArguments(
                isFetching: false,
                isForceFetch: true,
                expectedStates: [
                    .build(with: .default, isFetchingData: true),
                    .build(with: .default, fetchDataError: DummyError.fetchServerDataError)
                ],
                expectedLoadLocalEpisodesCount: 0,
                expectedLoadServerEpisodesCount: 1
            ),
            ErrorArguments(
                isFetching: false,
                isForceFetch: false,
                expectedStates: [.build(with: .default, fetchDataError: DummyError.fetchLocalDataError)],
                expectedLoadLocalEpisodesCount: 1,
                expectedLoadServerEpisodesCount: 0
            )
        ]
    )
    func fetchData_withError(arguments: ErrorArguments) async throws {
        let isFetching = arguments.isFetching
        let isForceFetch = arguments.isForceFetch

        let mockHtmlConverter = MockHtmlConverter(loadEpisodesResult: .failure(.fetchServerDataError))
        let mockDataSource = MockDataSource(fetchResult: .failure(.fetchLocalDataError))

        let reducer = EpisodesView.ViewReducer(
            htmlConvertable: mockHtmlConverter,
            dataProvideable: mockDataSource,
            userDefaultsManagerable: MockUserDefaultsManager(),
            widgetManagerable: MockWidgetManager(),
            hasServerNewEpisodes: false
        )
        
        let sut = ViewStore(
            initialState: .build(with: .default, isFetchingData: isFetching),
            reducer: reducer.process
        )
        
        var actualStates: [ViewState] = []
        startObserving(sut) {
            Task { @MainActor in
                actualStates.append(sut.state)
            }
        }
        
        await sut.send(.fetchData(isForce: isForceFetch))
        
        #expect(actualStates == arguments.expectedStates)
        #expect(mockDataSource.fetchCount == arguments.expectedLoadLocalEpisodesCount)
        #expect(await mockHtmlConverter.loadEpisodesCount == arguments.expectedLoadServerEpisodesCount)
    }
    
    @Test(
        arguments: [
            ConfirmErrorArguments(isFetching: false, hasEpisodes: false),
            ConfirmErrorArguments(isFetching: false, hasEpisodes: true),
            ConfirmErrorArguments(isFetching: true, hasEpisodes: false),
            ConfirmErrorArguments(isFetching: true, hasEpisodes: true)
        ]
    )
    func confirmErrorAlert(arguments: ConfirmErrorArguments) async throws {
        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = MockDataSource()

        let reducer = EpisodesView.ViewReducer(
            htmlConvertable: mockHtmlConverter,
            dataProvideable: mockDataSource,
            userDefaultsManagerable: MockUserDefaultsManager(),
            widgetManagerable: MockWidgetManager(),
            hasServerNewEpisodes: false
        )

        let episodes: [Episode] = arguments.hasEpisodes ? .dummy(withAmount: 10) : []
        
        let sut = ViewStore(
            initialState: ViewState(
                isFetchingData: arguments.isFetching,
                allEpisodes: episodes,
                favoriteEpisodes: [],
                selectedListType: .all,
                selectedEpisode: nil,
                needsShowPlayPanel: false,
                audioURL: nil,
                fetchDataError: DummyError.fetchServerDataError
            ),
            reducer: reducer.process
        )
        
        let dummyError = try #require(sut.state.fetchDataError as? DummyError)
        #expect(dummyError == .fetchServerDataError)
        #expect(sut.state.isFetchingData == arguments.isFetching)
        #expect(sut.state.allEpisodes == episodes)
        
        await sut.send(.confirmErrorAlert)
        
        #expect(sut.state.fetchDataError == nil)
        #expect(sut.state.isFetchingData == arguments.isFetching)
        #expect(sut.state.allEpisodes == episodes)
    }
    
    @Test func episodeTapped() async throws {
        let reducer = EpisodesView.ViewReducer(
            htmlConvertable: MockHtmlConverter(),
            dataProvideable: MockDataSource(),
            userDefaultsManagerable: MockUserDefaultsManager(),
            widgetManagerable: MockWidgetManager(),
            hasServerNewEpisodes: false
        )
        let state = ViewState(
            isFetchingData: false,
            allEpisodes: [],
            favoriteEpisodes: [],
            selectedListType: .all,
            selectedEpisode: nil,
            needsShowPlayPanel: false,
            audioURL: nil,
            fetchDataError: nil
        )
        let sut = ViewStore(initialState: state, reducer: reducer.process)
        
        let episode = Episode.dummy(withIndex: 100)
        
        await sut.send(.episodeTapped(episode))
        
        #expect(sut.state.selectedEpisode == episode)
    }
    
    @Test(arguments: [
        AddFavorite(
            initialEpisodes: [],
            initialFavoriteEpisodes: [],
            addEpisodeID: "1",
            expectedAllEpisodes: [],
            expectedFavoriteEpisodes: []
        ),
        AddFavorite(
            initialEpisodes: [.dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")],
            initialFavoriteEpisodes: [.dummy(id: "10")],
            addEpisodeID: "10",
            expectedAllEpisodes: [.dummyFav(id: "10"), .dummy(id: "20"), .dummy(id: "30")],
            expectedFavoriteEpisodes: [.dummyFav(id: "10")]
        ),
        AddFavorite(
            initialEpisodes: [.dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")],
            initialFavoriteEpisodes: [.dummy(id: "10")],
            addEpisodeID: "1",
            expectedAllEpisodes: [.dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")],
            expectedFavoriteEpisodes: []
        ),
        AddFavorite(
            initialEpisodes: [.dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")],
            initialFavoriteEpisodes: [],
            addEpisodeID: "40",
            expectedAllEpisodes: [.dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")],
            expectedFavoriteEpisodes: []
        ),
        AddFavorite(
            initialEpisodes: [.dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")],
            initialFavoriteEpisodes: [],
            addEpisodeID: "4",
            expectedAllEpisodes: [.dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")],
            expectedFavoriteEpisodes: []
        ),
        AddFavorite(
            initialEpisodes: [
                .dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            initialFavoriteEpisodes: [.dummy(id: "10")],
            addEpisodeID: "10",
            expectedAllEpisodes: [
                .dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3"),
                .dummyFav(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            expectedFavoriteEpisodes: [
                .dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3"), .dummyFav(id: "10")
            ]
        ),
        AddFavorite(
            initialEpisodes: [
                .dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            initialFavoriteEpisodes: [.dummy(id: "10")],
            addEpisodeID: "1",
            expectedAllEpisodes: [
                .dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            expectedFavoriteEpisodes: [.dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3")]
        ),
        AddFavorite(
            initialEpisodes: [
                .dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            initialFavoriteEpisodes: [],
            addEpisodeID: "40",
            expectedAllEpisodes: [
                .dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            expectedFavoriteEpisodes: [.dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3")]
        ),
        AddFavorite(
            initialEpisodes: [
                .dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            initialFavoriteEpisodes: [],
            addEpisodeID: "4",
            expectedAllEpisodes: [
                .dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            expectedFavoriteEpisodes: [.dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3")]
        ),
    ])
    func addFavorite(arguments: AddFavorite) async throws {
        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = MockDataSource()
        let mockUserDefaultsManager = MockUserDefaultsManager(favoriteEpisodeIDs: ["1", "2", "3"])
        let mockWidgetManager = MockWidgetManager()
        let reducer = EpisodesView.ViewReducer(
            htmlConvertable: mockHtmlConverter,
            dataProvideable: mockDataSource,
            userDefaultsManagerable: mockUserDefaultsManager,
            widgetManagerable: mockWidgetManager,
            hasServerNewEpisodes: false
        )

        let state = ViewState(
            isFetchingData: false,
            allEpisodes: arguments.initialEpisodes,
            favoriteEpisodes: arguments.initialFavoriteEpisodes,
            selectedListType: .all,
            selectedEpisode: nil,
            needsShowPlayPanel: false,
            audioURL: nil,
            fetchDataError: nil
        )
        let sut = ViewStore(
            initialState: state,
            reducer: reducer.process
        )
        
        await sut.send(.favoriteTapped(Episode.dummy(id: arguments.addEpisodeID)))
        
        let expectedViewState = ViewState(
            isFetchingData: false,
            allEpisodes: arguments.expectedAllEpisodes,
            favoriteEpisodes: arguments.expectedFavoriteEpisodes,
            selectedListType: .all,
            selectedEpisode: nil,
            needsShowPlayPanel: false,
            audioURL: nil,
            fetchDataError: nil
        )
        #expect(sut.state == expectedViewState)
        #expect(mockWidgetManager.reloadAllTimelinesCount == 1)
    }
    
    @Test(arguments: [
        RemoveFavorite(
            initialEpisodes: [],
            initialFavoriteEpisodes: [],
            removeEpisodeID: "1",
            expectedAllEpisodes: [],
            expectedFavoriteEpisodes: []
        ),
        RemoveFavorite(
            initialEpisodes: [.dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3")],
            initialFavoriteEpisodes: [.dummy(id: "1")],
            removeEpisodeID: "1",
            expectedAllEpisodes: [.dummy(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3")],
            expectedFavoriteEpisodes: [.dummyFav(id: "2"), .dummyFav(id: "3")]
        ),
        RemoveFavorite(
            initialEpisodes: [.dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3")],
            initialFavoriteEpisodes: [.dummy(id: "1")],
            removeEpisodeID: "2",
            expectedAllEpisodes: [.dummyFav(id: "1"), .dummy(id: "2"), .dummyFav(id: "3")],
            expectedFavoriteEpisodes: [.dummyFav(id: "1"), .dummyFav(id: "3")]
        ),
        RemoveFavorite(
            initialEpisodes: [.dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3")],
            initialFavoriteEpisodes: [.dummy(id: "1")],
            removeEpisodeID: "3",
            expectedAllEpisodes: [.dummyFav(id: "1"), .dummyFav(id: "2"), .dummy(id: "3")],
            expectedFavoriteEpisodes: [.dummyFav(id: "1"), .dummyFav(id: "2")]
        ),
        RemoveFavorite(
            initialEpisodes: [
                .dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            initialFavoriteEpisodes: [.dummy(id: "1"), .dummy(id: "10")],
            removeEpisodeID: "1",
            expectedAllEpisodes: [
                .dummy(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            expectedFavoriteEpisodes: [.dummyFav(id: "2"), .dummyFav(id: "3")]
        ),
        RemoveFavorite(
            initialEpisodes: [
                .dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            initialFavoriteEpisodes: [.dummy(id: "1"), .dummy(id: "10")],
            removeEpisodeID: "2",
            expectedAllEpisodes: [
                .dummyFav(id: "1"), .dummy(id: "2"), .dummyFav(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            expectedFavoriteEpisodes: [.dummyFav(id: "1"), .dummyFav(id: "3")]
        ),
        RemoveFavorite(
            initialEpisodes: [
                .dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            initialFavoriteEpisodes: [.dummy(id: "1"), .dummy(id: "10")],
            removeEpisodeID: "3",
            expectedAllEpisodes: [
                .dummyFav(id: "1"), .dummyFav(id: "2"), .dummy(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            expectedFavoriteEpisodes: [.dummyFav(id: "1"), .dummyFav(id: "2")]
        ),
        RemoveFavorite(
            initialEpisodes: [
                .dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            initialFavoriteEpisodes: [.dummy(id: "1"), .dummy(id: "10")],
            removeEpisodeID: "10",
            expectedAllEpisodes: [
                .dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            expectedFavoriteEpisodes: [.dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3")]
        ),
        RemoveFavorite(
            initialEpisodes: [
                .dummy(id: "1"), .dummy(id: "2"), .dummy(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            initialFavoriteEpisodes: [.dummy(id: "1"), .dummy(id: "10")],
            removeEpisodeID: "5",
            expectedAllEpisodes: [
                .dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3"),
                .dummy(id: "10"), .dummy(id: "20"), .dummy(id: "30")
            ],
            expectedFavoriteEpisodes: [.dummyFav(id: "1"), .dummyFav(id: "2"), .dummyFav(id: "3")]
        ),
    ])
    func removeFavorite(arguments: RemoveFavorite) async throws {
        let mockHtmlConverter = MockHtmlConverter()
        let mockDataSource = MockDataSource()
        let mockUserDefaultsManager = MockUserDefaultsManager(favoriteEpisodeIDs: ["1", "2", "3"])
        let mockWidgetManager = MockWidgetManager()
        let reducer = EpisodesView.ViewReducer(
            htmlConvertable: mockHtmlConverter,
            dataProvideable: mockDataSource,
            userDefaultsManagerable: mockUserDefaultsManager,
            widgetManagerable: mockWidgetManager,
            hasServerNewEpisodes: false
        )

        let state = ViewState(
            isFetchingData: false,
            allEpisodes: arguments.initialEpisodes,
            favoriteEpisodes: arguments.initialFavoriteEpisodes,
            selectedListType: .all,
            selectedEpisode: nil,
            needsShowPlayPanel: false,
            audioURL: nil,
            fetchDataError: nil
        )
        let sut = ViewStore(
            initialState: state,
            reducer: reducer.process
        )
        
        await sut.send(.favoriteTapped(Episode.dummyFav(id: arguments.removeEpisodeID)))
        
        let expectedViewState = ViewState(
            isFetchingData: false,
            allEpisodes: arguments.expectedAllEpisodes,
            favoriteEpisodes: arguments.expectedFavoriteEpisodes,
            selectedListType: .all,
            selectedEpisode: nil,
            needsShowPlayPanel: false,
            audioURL: nil,
            fetchDataError: nil
        )
        #expect(sut.state == expectedViewState)
        #expect(mockWidgetManager.reloadAllTimelinesCount == 1)
    }
    
    @Test(
        arguments: [
            EpisodeDetailLoaded(
                episodeDetail: EpisodeDetail(
                    id: "1",
                    audioLink: "https://downloads.bbc.co.uk/learningenglish/features/6min/241114_6_minute_english_the_bond_between_sisters_download.mp3"
                ),
                expectedNeedsPlayPanel: true,
                expectedAudioURL: URL(
                    string: "https://downloads.bbc.co.uk/learningenglish/features/6min/241114_6_minute_english_the_bond_between_sisters_download.mp3"
                )
            ),
            EpisodeDetailLoaded(
                episodeDetail: EpisodeDetail(id: "", audioLink: ""),
                expectedNeedsPlayPanel: false,
                expectedAudioURL: nil
            )
        ]
    )
    func episodeDetailLoaded(arguments: EpisodeDetailLoaded) async throws {
        let reducer = EpisodesView.ViewReducer(
            htmlConvertable: MockHtmlConverter(),
            dataProvideable: MockDataSource(),
            userDefaultsManagerable: MockUserDefaultsManager(),
            widgetManagerable: MockWidgetManager(),
            hasServerNewEpisodes: false
        )
        let state = ViewState(
            isFetchingData: false,
            allEpisodes: [],
            favoriteEpisodes: [],
            selectedListType: .all,
            selectedEpisode: nil,
            needsShowPlayPanel: false,
            audioURL: nil,
            fetchDataError: nil
        )
        let sut = ViewStore(initialState: state, reducer: reducer.process)
        
        await sut.send(.episodeDetailLoaded(arguments.episodeDetail))
        
        #expect(sut.state.needsShowPlayPanel == arguments.expectedNeedsPlayPanel)
        #expect(sut.state.audioURL == arguments.expectedAudioURL)
    }
    
    @Test func hidePlayPanelView() async throws {
        let reducer = EpisodesView.ViewReducer(
            htmlConvertable: MockHtmlConverter(),
            dataProvideable: MockDataSource(),
            userDefaultsManagerable: MockUserDefaultsManager(),
            widgetManagerable: MockWidgetManager(),
            hasServerNewEpisodes: false
        )
        let state = ViewState(
            isFetchingData: false,
            allEpisodes: [],
            favoriteEpisodes: [],
            selectedListType: .all,
            selectedEpisode: nil,
            needsShowPlayPanel: true,
            audioURL: URL(
                string: "https://downloads.bbc.co.uk/learningenglish/features/6min/241114_6_minute_english_the_bond_between_sisters_download.mp3"
            ),
            fetchDataError: nil
        )
        let sut = ViewStore(initialState: state, reducer: reducer.process)
        
        await sut.send(.hidePlayPanelView)
        
        #expect(sut.state.needsShowPlayPanel == false)
        #expect(sut.state.audioURL == nil)
    }
}

extension EpisodesViewTests {
    private func startObserving(_ store: ViewStore, onChange: @escaping @Sendable () -> Void) {
        withObservationTracking {
            _ = store.state
        } onChange: {
            onChange()
            Task {
                // We should observe again, otherwise, we can't receive changed event after `onChange()`
                // triggered
                await startObserving(store, onChange: onChange)
            }
        }
    }
}

extension DataSource {
    @MainActor
    fileprivate static func mock(with episodes: [Episode] = []) throws -> DataSource {
        let mockDataSource = try DataSource(with: .mock(isStoredInMemoryOnly: true))
        if !episodes.isEmpty {
            try mockDataSource.add(episodes)
        }
        return mockDataSource
    }
}

extension [Episode] {
    fileprivate static var localEpisodes: [Episode] {
        [Episode].dummy(withAmount: 10)
    }
    
    fileprivate static var serverEpisodes: [Episode] {
        [Episode].dummy(withAmount: 20)
    }
}

extension Episode {
    fileprivate static func dummy(id: String) -> Episode {
        Episode(id: id, title: nil, desc: nil, date: nil, imageURLString: nil, urlString: nil)
    }
    
    fileprivate static func dummyFav(id: String) -> Episode {
        let episode = Episode(
            id: id, title: nil, desc: nil, date: nil, imageURLString: nil, urlString: nil
        )
        episode.isFavorite = true
        return episode
    }
}
