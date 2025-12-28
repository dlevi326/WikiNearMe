//
//  Bookmark.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import Foundation
import SwiftData

/// SwiftData model for persisting bookmarked articles
@Model
final class Bookmark {
    @Attribute(.unique) var id: String
    var title: String
    var extract: String
    var thumbnailURLString: String?
    var pageURLString: String?
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date
    
    init(
        id: String,
        title: String,
        extract: String,
        thumbnailURLString: String? = nil,
        pageURLString: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.extract = extract
        self.thumbnailURLString = thumbnailURLString
        self.pageURLString = pageURLString
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
    }
    
    /// Convert Article to Bookmark
    convenience init(from article: Article) {
        self.init(
            id: article.id,
            title: article.title,
            extract: article.extract ?? "",
            thumbnailURLString: article.thumbnailURL?.absoluteString,
            pageURLString: article.pageURL?.absoluteString,
            latitude: article.coordinate?.latitude,
            longitude: article.coordinate?.longitude
        )
    }
    
    /// Convert Bookmark back to Article
    func toArticle() -> Article {
        let coordinate: Article.Coordinate? = if let lat = latitude, let lon = longitude {
            Article.Coordinate(latitude: lat, longitude: lon)
        } else {
            nil
        }
        
        // Convert empty or whitespace-only extracts to nil
        let validExtract = extract.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : extract
        
        return Article(
            id: id,
            title: title,
            distanceMeters: nil,
            extract: validExtract,
            thumbnailURL: thumbnailURLString.flatMap { URL(string: $0) },
            pageURL: pageURLString.flatMap { URL(string: $0) },
            coordinate: coordinate,
            source: .geosearch
        )
    }
}
