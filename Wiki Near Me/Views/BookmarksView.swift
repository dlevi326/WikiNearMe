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
            Group {
                if bookmarks.isEmpty {
                    ContentUnavailableView(
                        "No Bookmarks",
                        systemImage: "bookmark",
                        description: Text("Bookmark articles from the Nearby tab to see them here")
                    )
                } else {
                    List(bookmarks) { bookmark in
                        Button {
                            selectedArticle = bookmark.toArticle()
                            showingDetail = true
                        } label: {
                            BookmarkRowView(bookmark: bookmark)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Bookmarks")
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
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            if let thumbnailURLString = bookmark.thumbnailURLString,
               let url = URL(string: thumbnailURLString) {
                AsyncImageView(url: url, width: 60, height: 60)
                    .cornerRadius(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(bookmark.extract)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    BookmarksView()
        .modelContainer(for: Bookmark.self, inMemory: true)
}
