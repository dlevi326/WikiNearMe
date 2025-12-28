//
//  Wiki_Near_MeApp.swift
//  Wiki Near Me
//
//  Created by David Levi on 12/27/25.
//

import SwiftUI
import SwiftData

@main
struct Wiki_Near_MeApp: App {
    // SwiftData container for bookmarks
    let modelContainer: ModelContainer
    
    // Environment objects
    @State private var locationManager = LocationManager()
    @State private var nearbyViewModel = NearbyViewModel()
    
    init() {
        do {
            modelContainer = try ModelContainer(for: Bookmark.self)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(locationManager)
                .environment(nearbyViewModel)
        }
    }
}
