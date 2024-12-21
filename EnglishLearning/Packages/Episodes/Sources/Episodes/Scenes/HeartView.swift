//
//  HeartView.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/21.
//

import SwiftUI

struct HeartView: View {
    var isFavorite: Bool
    
    var body: some View {
        Image(systemName: isFavorite ? "heart.fill" : "heart")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.red)
            .frame(width: 24, height: 24)
            .shadow(radius: 8, x: 4, y: 4)
            // Force SwiftUI to recreate the `Image` when `isFavorite` changes. This ensures the heart
            // image updates immediately when the favorite state changes. Additionally, the `@Transient`
            // doesn't trigger event when its value changed, so we couldn't add it to
            // `Episode.isFavorite`
            .id(isFavorite)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HeartView(isFavorite: true)
    HeartView(isFavorite: false)
}
