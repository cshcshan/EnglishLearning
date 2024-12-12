//
//  LocalizedAlertError.swift
//  Core
//
//  Created by Han Chen on 2024/12/13.
//

import SwiftUI

public struct LocalizedAlertError: LocalizedError {
    public let wrappedError: Error?

    public var errorDescription: String? {
        localizedError?.errorDescription
            ?? wrappedError?.localizedDescription
            ?? defaultErrorDescription
    }
    
    public var failureReason: String? {
        localizedError?.failureReason
            ?? (wrappedError as? NSError)?.localizedFailureReason
            ?? defaultFailureReason
    }
    
    public var recoverySuggestion: String? {
        localizedError?.recoverySuggestion
            ?? (wrappedError as? NSError)?.localizedRecoverySuggestion
            ?? defaultRecoverySuggestion
    }
    
    public var helpAnchor: String? {
        localizedError?.helpAnchor
            ?? (wrappedError as? NSError)?.helpAnchor
            ?? defaultHelpAnchor
    }
    
    private let localizedError: LocalizedError?
    private let defaultErrorDescription: String
    private let defaultFailureReason: String
    private let defaultRecoverySuggestion: String
    private let defaultHelpAnchor: String

    public init(
        error: Error?,
        defaultErrorDescription: String = "Something went wrong",
        defaultFailureReason: String = "The operation couldn’t be completed.",
        defaultRecoverySuggestion: String = "Please try again later or contact support if the problem persists.",
        defaultHelpAnchor: String = "support.example.com/help"
    ) {
        self.wrappedError = error
        self.localizedError = error as? LocalizedError
        self.defaultErrorDescription = defaultErrorDescription
        self.defaultFailureReason = defaultFailureReason
        self.defaultRecoverySuggestion = defaultRecoverySuggestion
        self.defaultHelpAnchor = defaultHelpAnchor
    }
}

extension View {
    public func errorAlert<E, V>(
        isPresented: Binding<Bool>,
        error: E?,
        @ViewBuilder actions: () -> V
    ) -> some View where E : Error, V : View {
        let localizedAlertError = LocalizedAlertError(error: error)
        return self.alert(isPresented: isPresented, error: localizedAlertError, actions: actions)
    }
    
    public func errorAlert<E, A, M>(
        isPresented: Binding<Bool>,
        error: E?,
        @ViewBuilder actions: (LocalizedAlertError) -> A,
        @ViewBuilder message: (LocalizedAlertError) -> M
    ) -> some View where E : Error, A : View, M : View {
        let localizedAlertError = LocalizedAlertError(error: error)
        return self.alert(
            isPresented: isPresented,
            error: localizedAlertError,
            actions: { _ in
                actions(localizedAlertError)
            },
            message: { _ in
                message(localizedAlertError)
            }
        )
    }
}
