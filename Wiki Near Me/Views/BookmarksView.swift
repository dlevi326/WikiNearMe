//
//  BookmarksView.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import SwiftUI
import SwiftData

/// View showing bookmarked articles
struct BookmarksView: View {
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    @State private var selectedArticle: Article?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                Group {
                    if bookmarks.isEmpty {
                        ContentUnavailableView(
                            "No Bookmarks",
                            systemImage: "bookmark",
                            description: Text("Bookmark articles from the Nearby tab to see them here")
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(bookmarks) { bookmark in
                                    Button {
                                        selectedArticle = bookmark.toArticle()
                                        showingDetail = true
                                    } label: {
                                        BookmarkRowView(bookmark: bookmark)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingDetail) {
                if let article = selectedArticle {
                    NavigationStack {
                        ArticleDetailView(article: article)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") {
                                        showingDetail = false
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
}

/// Individual bookmark row
struct BookmarkRowView: View {
    let bookmark: Bookmark
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Thumbnail
            if let thumbnailURLString = bookmark.thumbnailURLString,
               let url = URL(string: thumbnailURLString) {
                AsyncImageView(url: url, width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.pink.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(bookmark.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                Text(bookmark.extract)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer(minLength: 0)
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        )
    }
}

#Preview {
    BookmarksView()
        .modelContainer(for: Bookmark.self, inMemory: true)
}
