//
//  ArticleDetailView.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import SwiftUI
import SwiftData

/// Detail view showing full article information
struct ArticleDetailView: View {
    let article: Article
    @Environment(\.modelContext) private var modelContext
    @Query private var bookmarks: [Bookmark]
    @State private var showingSafari = false
    
    private var isBookmarked: Bool {
        bookmarks.contains { $0.id == article.id }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(article.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                // Distance
                if let distance = article.distanceMeters {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.secondary)
                        Text(DistanceFormatter.format(meters: distance))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Thumbnail
                if let thumbnailURL = article.thumbnailURL {
                    AsyncImageView(url: thumbnailURL, width: nil, height: 200)
                        .cornerRadius(12)
                }
                
                // Extract
                if let extract = article.extract {
                    Text(extract)
                        .font(.body)
                        .lineSpacing(4)
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    // Bookmark button
                    Button {
                        toggleBookmark()
                    } label: {
                        Label(
                            isBookmarked ? "Bookmarked" : "Bookmark",
                            systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                        )
                    }
                    .buttonStyle(.bordered)
                    
                    // Open in Safari button
                    if article.pageURL != nil {
                        Button {
                            showingSafari = true
                        } label: {
                            Label("Open Full Page", systemImage: "safari")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .sheet(isPresented: $showingSafari) {
            if let url = article.pageURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func toggleBookmark() {
        if let existing = bookmarks.first(where: { $0.id == article.id }) {
            // Remove bookmark
            modelContext.delete(existing)
        } else {
            // Add bookmark
            let bookmark = Bookmark(from: article)
            modelContext.insert(bookmark)
        }
        
        try? modelContext.save()
    }
}

#Preview {
    ArticleDetailView(
        article: Article(
            id: "1",
            title: "Empire State Building",
            distanceMeters: 500,
            extract: "The Empire State Building is a 102-story Art Deco skyscraper in Midtown Manhattan, New York City. It was designed by Shreve, Lamb & Harmon and built from 1930 to 1931. Its name is derived from \"Empire State\", the nickname of the state of New York.",
            thumbnailURL: nil,
            pageURL: URL(string: "https://en.wikipedia.org/wiki/Empire_State_Building"),
            source: .geosearch
        )
    )
    .modelContainer(for: Bookmark.self, inMemory: true)
}
