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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(article.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if let distance = article.distanceMeters {
                        Text(DistanceFormatter.format(meters: distance))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let thumbnailURL = article.thumbnailURL {
                    AsyncImageView(url: thumbnailURL, width: 60, height: 60)
                        .cornerRadius(8)
                }
            }
            
            if let extract = article.extract {
                Text(extract)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            
            Button {
                showingDetail = true
            } label: {
                Text("Open")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
