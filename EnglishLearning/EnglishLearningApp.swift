//
//  EnglishLearningApp.swift
//  EnglishLearning
//
//  Created by Han Chen on 2024/11/22.
//

import Core
import Episodes
import SwiftData
import SwiftUI

@main
struct EnglishLearningApp: App {
    private let dataSource: DataSource
    
    @MainActor
    var body: some Scene {
        WindowGroup {
            EpisodesView(
                htmlConvertable: HtmlConverter(),
                dataSource: dataSource,
                userDefaultsManagerable: UserDefaultsManager(store: UserDefaults.appGroup),
                appGroupFileManagerable: AppGroupFileManager(appGroupURL: FileManager.default.appGroup!),
                widgetManagerable: WidgetManager(),
                episodeImagePathFormat: Configuration.episodeImagePathFormat
            )
        }
        .modelContainer(dataSource.modelContainer)
    }
    
    init() {
        do {
            let modelContainer = try ModelContainer.buildProd()
            self.dataSource = try DataSource(with: modelContainer)
        } catch {
            fatalError()
        }
        
        printSandbox()
    }
    
    private func printSandbox() {
        let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        print("Library \(libraryURL?.absoluteString ?? "")")
        
        let appGroupURL = FileManager.default.appGroup
        print("App Group \(appGroupURL?.absoluteString ?? "")")
    }
}
