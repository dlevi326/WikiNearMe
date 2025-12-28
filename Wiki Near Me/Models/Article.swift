//
//  Article.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import Foundation
import CoreLocation

/// Represents a Wikipedia article discovered near a location
struct Article: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let distanceMeters: Double?
    let extract: String?
    let thumbnailURL: URL?
    let pageURL: URL?
    let coordinate: Coordinate?
    let source: ArticleSource
    var pageviews: Int?
    
    /// Wrapper for CLLocationCoordinate2D to make it Codable
    struct Coordinate: Codable, Hashable {
        let latitude: Double
        let longitude: Double
        
        init(latitude: Double, longitude: Double) {
            self.latitude = latitude
            self.longitude = longitude
        }
        
        init(_ coordinate: CLLocationCoordinate2D) {
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
        }
        
        var clCoordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    enum ArticleSource: String, Codable {
        case geosearch
        case nearcoord
    }
    
    init(
        id: String,
        title: String,
        distanceMeters: Double? = nil,
        extract: String? = nil,
        thumbnailURL: URL? = nil,
        pageURL: URL? = nil,
        coordinate: Coordinate? = nil,
        source: ArticleSource,
        pageviews: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.distanceMeters = distanceMeters
        self.extract = extract
        self.thumbnailURL = thumbnailURL
        self.pageURL = pageURL
        self.coordinate = coordinate
        self.source = source
        self.pageviews = pageviews
    }
    
    /// Calculate curation score (lower is better)
    func curationScore() -> Double {
        let baseDistance = distanceMeters ?? 999999
        let thumbnailBoost = thumbnailURL != nil ? 200.0 : 0.0
        let extractLength = Double(extract?.count ?? 0)
        let extractBoost = min(extractLength, 1200) * 0.1
        
        return baseDistance - thumbnailBoost - extractBoost
    }
    
    /// Calculate popularity score (higher is better)
    /// Falls back to extract length + thumbnail bonus if pageviews unavailable
    var popularityScore: Int {
        if let pageviews = pageviews {
            return pageviews
        }
        // Fallback: use extract length + thumbnail bonus as popularity proxy
        let extractLength = extract?.count ?? 0
        let thumbnailBonus = thumbnailURL != nil ? 200 : 0
        return extractLength + thumbnailBonus
    }
    
    /// Check if article meets curation requirements
    var meetsCurationCriteria: Bool {
        // Must have extract
        guard let extract = extract else { return false }
        
        // Minimum extract length: 280 characters
        guard extract.count >= 280 else { return false }
        
        // Filter out disambiguation pages
        if title.contains("(disambiguation)") {
            return false
        }
        
        return true
    }
}
