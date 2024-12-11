//
//  EpisodesState+Equatable.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/1.
//

@testable import Episodes

extension EpisodesView.ViewState: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        let sortedLHSEpisodes = lhs.episodes.sorted { $0.id ?? "" < $1.id ?? "" }
        let sortedRHSEpisodes = rhs.episodes.sorted { $0.id ?? "" < $1.id ?? "" }
        let hasLHSError = lhs.fetchDataError != nil
        let hasRHSError = rhs.fetchDataError != nil
        
        return lhs.isFetchingData == rhs.isFetchingData
            && sortedLHSEpisodes == sortedRHSEpisodes
            && hasLHSError == hasRHSError
    }
}
