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
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(articles) { article in
                    Button {
                        selectedArticle = article
                    } label: {
                        ArticleRowView(article: article)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// Individual article row
struct ArticleRowView: View {
    let article: Article
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Thumbnail
            if let thumbnailURL = article.thumbnailURL {
                AsyncImageView(url: thumbnailURL, width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "text.document")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    )
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(article.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                // Distance
                if let distance = article.distanceMeters {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text(DistanceFormatter.format(meters: distance))
                            .font(.subheadline)
                    }
                    .foregroundStyle(.blue)
                }
                
                // Extract preview
                if let extract = article.extract {
                    Text(extract)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
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
