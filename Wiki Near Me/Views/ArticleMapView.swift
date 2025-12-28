//
//  ArticleMapView.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import SwiftUI
import MapKit

/// Map view showing article locations
struct ArticleMapView: View {
    let articles: [Article]
    @Binding var selectedArticle: Article?
    @State private var position: MapCameraPosition = .automatic
    @State private var showingSheet = false
    
    // Filter articles with coordinates
    private var mappableArticles: [Article] {
        articles.filter { $0.coordinate != nil }
    }
    
    var body: some View {
        ZStack {
            Map(position: $position, selection: $selectedArticle) {
                ForEach(mappableArticles) { article in
                    if let coordinate = article.coordinate {
                        Marker(article.title, coordinate: coordinate.clCoordinate)
                            .tag(article)
                    }
                }
            }
            .mapStyle(.standard)
            .onChange(of: selectedArticle) { _, newValue in
                showingSheet = newValue != nil
            }
        }
        .sheet(isPresented: $showingSheet) {
            if let article = selectedArticle {
                ArticlePreviewSheet(article: article, selectedArticle: $selectedArticle)
                    .presentationDetents([.height(200), .medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

/// Bottom sheet preview for selected article on map
struct ArticlePreviewSheet: View {
    let article: Article
    @Binding var selectedArticle: Article?
    @State private var showingDetail = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                    
                    if let distance = article.distanceMeters {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 10))
                            Text(DistanceFormatter.format(meters: distance))
                                .font(.subheadline)
                        }
                        .foregroundStyle(.blue)
                    }
                }
                
                Spacer()
                
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
            }
            
            if let extract = article.extract {
                Text(extract)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            Button {
                showingDetail = true
            } label: {
                HStack {
                    Text("View Details")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .blue.opacity(0.3), radius: 5, y: 2)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingDetail) {
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

#Preview {
    ArticleMapView(
        articles: [
            Article(
                id: "1",
                title: "Empire State Building",
                distanceMeters: 500,
                extract: "The Empire State Building is a 102-story Art Deco skyscraper in Midtown Manhattan.",
                coordinate: Article.Coordinate(latitude: 40.7484, longitude: -73.9857),
                source: .geosearch
            )
        ],
        selectedArticle: .constant(nil)
    )
}
