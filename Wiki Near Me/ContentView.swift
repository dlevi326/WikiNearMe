//
//  ContentView.swift
//  Wiki Near Me
//
//  Created by David Levi on 12/27/25.
//

import SwiftUI

struct ContentView: View {
    @Environment(NearbyViewModel.self) private var nearbyViewModel
    
    var body: some View {
        TabView {
            NearbyView(viewModel: nearbyViewModel)
                .tabItem {
                    Label("Nearby", systemImage: "location.circle.fill")
                }
            
            BookmarksView()
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(NearbyViewModel())
        .environment(LocationManager())
        .modelContainer(for: Bookmark.self, inMemory: true)
}
