//
//  VirtualFileOrganizerApp.swift
//  VirtualFileOrganizer
//
//  Created by Dennis Stewart Jr. on 10/28/25.
//
import SwiftUI

@main
struct VirtualFileOrganizerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
