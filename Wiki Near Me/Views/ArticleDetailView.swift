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
            VStack(alignment: .leading, spacing: 20) {
                // Thumbnail
                if let thumbnailURL = article.thumbnailURL {
                    AsyncImageView(url: thumbnailURL, width: nil, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                } else {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 240)
                        .overlay(
                            Image(systemName: "text.document")
                                .font(.system(size: 60))
                                .foregroundStyle(.white)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    Text(article.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    // Distance badge
                    if let distance = article.distanceMeters {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                            Text(DistanceFormatter.format(meters: distance))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 5, y: 2)
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 1)
                        .padding(.vertical, 4)
                    
                    // Extract
                    if let extract = article.extract {
                        Text(extract)
                            .font(.body)
                            .lineSpacing(6)
                            .foregroundStyle(.primary)
                    }
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        // Bookmark button
                        Button {
                            toggleBookmark()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 16, weight: .medium))
                                Text(isBookmarked ? "Bookmarked" : "Bookmark")
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(isBookmarked ? .white : .blue)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isBookmarked ? 
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color(.systemBackground), Color(.systemBackground)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .strokeBorder(Color.blue, lineWidth: isBookmarked ? 0 : 2)
                                    )
                                    .shadow(color: isBookmarked ? .blue.opacity(0.3) : .clear, radius: 5, y: 2)
                            )
                        }
                        
                        // Open in Safari button
                        if article.pageURL != nil {
                            Button {
                                showingSafari = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "safari")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Read Full")
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [.purple, .purple.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: .purple.opacity(0.3), radius: 5, y: 2)
                                )
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
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
