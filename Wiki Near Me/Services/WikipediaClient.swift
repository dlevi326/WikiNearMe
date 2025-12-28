//
//  WikipediaClient.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import Foundation
import CoreLocation

/// API client for Wikipedia MediaWiki and REST APIs
actor WikipediaClient {
    private let baseURL = "https://en.wikipedia.org"
    private let apiPath = "/w/api.php"
    private let restPath = "/api/rest_v1/page/summary"
    
    // In-memory cache for summaries
    private var summaryCache: [String: ArticleSummary] = [:]
    
    // MARK: - Data Structures
    
    struct GeoSearchResult: Codable {
        let pageid: Int
        let title: String
        let lat: Double
        let lon: Double
        let dist: Double?
        
        func toArticle() -> Article {
            Article(
                id: String(pageid),
                title: title,
                distanceMeters: dist,
                coordinate: Article.Coordinate(latitude: lat, longitude: lon),
                source: .geosearch
            )
        }
    }
    
    struct NearCoordSearchResult: Codable {
        let pageid: Int
        let title: String
    }
    
    struct ArticleSummary: Codable {
        let title: String
        let extract: String?
        let thumbnail: Thumbnail?
        let content_urls: ContentURLs?
        let type: String?
        let description: String?
        
        struct Thumbnail: Codable {
            let source: String
        }
        
        struct ContentURLs: Codable {
            let desktop: DesktopURL
            
            struct DesktopURL: Codable {
                let page: String
            }
        }
        
        var isDisambiguation: Bool {
            type == "disambiguation" ||
            description?.lowercased().contains("disambiguation") == true
        }
    }
    
    // MARK: - API Methods
    
    /// Fetch geotagged pages near a coordinate
    func fetchGeoSearch(
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Int
    ) async throws -> [Article] {
        var components = URLComponents(string: baseURL + apiPath)!
        components.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "geosearch"),
            URLQueryItem(name: "gscoord", value: "\(coordinate.latitude)|\(coordinate.longitude)"),
            URLQueryItem(name: "gsradius", value: String(radiusMeters)),
            URLQueryItem(name: "gslimit", value: "50"),
            URLQueryItem(name: "gsprop", value: "type|name|country|region|globe|dim|dist")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct Response: Codable {
            let query: Query
            struct Query: Codable {
                let geosearch: [GeoSearchResult]
            }
        }
        
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.query.geosearch.map { $0.toArticle() }
    }
    
    /// Fetch pages near coordinate using search
    /// NOTE: nearcoord search may have limited availability. Falls back gracefully.
    func fetchNearCoordSearch(
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Int
    ) async throws -> [Article] {
        var components = URLComponents(string: baseURL + apiPath)!
        components.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "search"),
            URLQueryItem(name: "srnamespace", value: "0"),
            URLQueryItem(name: "srlimit", value: "50"),
            URLQueryItem(name: "srsearch", value: "nearcoord:\(coordinate.latitude),\(coordinate.longitude),\(radiusMeters)")
        ]
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        struct Response: Codable {
            let query: Query?
            struct Query: Codable {
                let search: [NearCoordSearchResult]
            }
        }
        
        do {
            let response = try JSONDecoder().decode(Response.self, from: data)
            guard let results = response.query?.search else { return [] }
            
            return results.map { result in
                Article(
                    id: String(result.pageid),
                    title: result.title,
                    source: .nearcoord
                )
            }
        } catch {
            // nearcoord search may not be available - return empty gracefully
            return []
        }
    }
    
    /// Fetch summary for an article
    func fetchSummary(for article: Article) async throws -> Article {
        let normalizedTitle = article.title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? article.title
        
        // Check cache
        if let cached = summaryCache[article.title] {
            return mergeArticleWithSummary(article, summary: cached)
        }
        
        let url = URL(string: baseURL + restPath + "/\(normalizedTitle)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let summary = try JSONDecoder().decode(ArticleSummary.self, from: data)
        
        // Cache it
        summaryCache[article.title] = summary
        
        return mergeArticleWithSummary(article, summary: summary)
    }
    
    /// Fetch summaries for multiple articles concurrently (with limit)
    func fetchSummaries(for articles: [Article], maxConcurrent: Int = 8) async -> [Article] {
        await withTaskGroup(of: Article?.self) { group in
            var results: [Article] = []
            var iterator = articles.makeIterator()
            var inFlight = 0
            
            // Start initial batch
            while inFlight < maxConcurrent, let article = iterator.next() {
                group.addTask {
                    try? await self.fetchSummary(for: article)
                }
                inFlight += 1
            }
            
            // Process results and add more tasks
            while let result = await group.next() {
                if let article = result {
                    results.append(article)
                }
                
                // Add next task
                if let nextArticle = iterator.next() {
                    group.addTask {
                        try? await self.fetchSummary(for: nextArticle)
                    }
                } else {
                    inFlight -= 1
                }
            }
            
            return results
        }
    }
    
    // MARK: - Helper
    
    private func mergeArticleWithSummary(_ article: Article, summary: ArticleSummary) -> Article {
        Article(
            id: article.id,
            title: summary.title,
            distanceMeters: article.distanceMeters,
            extract: summary.extract,
            thumbnailURL: summary.thumbnail.flatMap { URL(string: $0.source) },
            pageURL: summary.content_urls.flatMap { URL(string: $0.desktop.page) },
            coordinate: article.coordinate,
            source: article.source
        )
    }
}
