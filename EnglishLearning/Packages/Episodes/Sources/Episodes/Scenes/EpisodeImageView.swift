//
//  EpisodeImageView.swift
//  Episodes
//
//  Created by Han Chen on 2024/12/12.
//

import SwiftUI

struct EpisodeImageView: View {
    let imageURL: URL?

    var body: some View {
        AsyncImage(url: imageURL) { image in
            image
                .resizable()
        } placeholder: {
            Rectangle()
                .fill(.gray.opacity(0.4))
                .redacted(reason: .placeholder)
                .shimmer()
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1920 / 1080, contentMode: .fit)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    EpisodeImageView(imageURL: URL(string: "https://ichef.bbci.co.uk/images/ic/1920xn/p0k67wpv.jpg"))
}
