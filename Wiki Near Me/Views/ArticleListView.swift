//
//  ArticleListView.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import SwiftUI

/// List view showing nearby articles
struct ArticleListView: View {
    let articles: [Article]
    @Binding var selectedArticle: Article?
    
    var body: some View {
        List(articles) { article in
            Button {
                selectedArticle = article
            } label: {
                ArticleRowView(article: article)
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }
}

/// Individual article row
struct ArticleRowView: View {
    let article: Article
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail
            if let thumbnailURL = article.thumbnailURL {
                AsyncImageView(url: thumbnailURL, width: 60, height: 60)
                    .cornerRadius(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                
                // Distance
                if let distance = article.distanceMeters {
                    Text(DistanceFormatter.format(meters: distance))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Extract preview
                if let extract = article.extract {
                    Text(extract)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ArticleListView(
        articles: [
            Article(
                id: "1",
                title: "Empire State Building",
                distanceMeters: 500,
                extract: "The Empire State Building is a 102-story Art Deco skyscraper in Midtown Manhattan, New York City. It was designed by Shreve, Lamb & Harmon and built from 1930 to 1931.",
                thumbnailURL: nil,
                source: .geosearch
            )
        ],
        selectedArticle: .constant(nil)
    )
}
