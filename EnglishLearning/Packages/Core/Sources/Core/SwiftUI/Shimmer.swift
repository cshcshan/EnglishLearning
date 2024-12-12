//
//  Shimmer.swift
//  Core
//
//  Created by Han Chen on 2024/12/12.
//

import SwiftUI

struct Shimmer: ViewModifier {
    struct Configuration {
        let gradient: Gradient
        let initialPoints: (start: UnitPoint, end: UnitPoint)
        let finalPoints: (start: UnitPoint, end: UnitPoint)
        let opacity: Double
        let duration: TimeInterval
    }

    @State private var isInitialState = true
    private let configuration: Configuration

    func body(content: Content) -> some View {
        ZStack {
            content
            LinearGradient(
                gradient: configuration.gradient,
                startPoint: isInitialState
                    ? configuration.initialPoints.start
                    : configuration.finalPoints.start,
                endPoint: isInitialState
                    ? configuration.initialPoints.end
                    : configuration.finalPoints.end
            )
            .opacity(configuration.opacity)
            .blendMode(.screen)
            .animation(
                .linear(duration: configuration.duration).delay(0.25).repeatForever(autoreverses: false),
                value: isInitialState
            )
            .onAppear {
                withAnimation(.linear(duration: configuration.duration).repeatForever(autoreverses: false)) {
                    isInitialState = false
                }
            }
        }
    }
    
    init(configuration: Configuration = .default()) {
        self.configuration = configuration
    }
}

extension Shimmer.Configuration {
    static func `default`() -> Self {
        Shimmer.Configuration(
            gradient: Gradient(colors: [
                .black,
                .white,
                .white,
                .black
            ]),
            initialPoints: (start: UnitPoint(x: -1, y: 0.5), end: .leading),
            finalPoints: (start: .trailing, end: UnitPoint(x: 2, y: 0.5)),
            opacity: 0.6,
            duration: 2
        )
    }
}

extension View {
    public func shimmer() -> some View {
        self.modifier(Shimmer())
    }
}
