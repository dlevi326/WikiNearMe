//
//  NearbyViewModel.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import Foundation
import CoreLocation
import Observation

/// ViewModel managing nearby article discovery and state
@MainActor
@Observable
class NearbyViewModel {
    // State
    var articles: [Article] = []
    var selectedArticle: Article?
    var isLoading = false
    var errorMessage: String?
    
    // Location state
    var currentCoordinate: CLLocationCoordinate2D?
    var radiusMeters: Int = 805 // 0.5 miles default
    var searchQuery = ""
    
    // Services
    private let wikipediaClient = WikipediaClient()
    private let geocoder = CLGeocoder()
    
    // Computed
    var radiusMiles: Double {
        Double(radiusMeters) / 1609.34
    }
    
    func setRadiusMiles(_ miles: Double) {
        radiusMeters = Int(miles * 1609.34)
    }
    
    // MARK: - Refresh Articles
    
    func refreshArticles() async {
        guard let coordinate = currentCoordinate else {
            errorMessage = "No location available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch from both sources in parallel
            async let geoResults = wikipediaClient.fetchGeoSearch(
                coordinate: coordinate,
                radiusMeters: radiusMeters
            )
            
            async let nearResults = wikipediaClient.fetchNearCoordSearch(
                coordinate: coordinate,
                radiusMeters: radiusMeters
            )
            
            let (geoArticles, nearArticles) = try await (geoResults, nearResults)
            
            // Merge and deduplicate
            var articlesById: [String: Article] = [:]
            
            // Prefer geosearch results (have distance)
            for article in geoArticles {
                articlesById[article.id] = article
            }
            
            for article in nearArticles {
                if articlesById[article.id] == nil {
                    articlesById[article.id] = article
                }
            }
            
            let candidates = Array(articlesById.values)
            
            // Fetch summaries concurrently (max 8 at a time)
            let articlesWithSummaries = await wikipediaClient.fetchSummaries(
                for: candidates,
                maxConcurrent: 8
            )
            
            // Apply curation
            let curated = curateArticles(articlesWithSummaries)
            
            articles = curated
            isLoading = false
            
        } catch {
            errorMessage = "Failed to fetch articles: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Curation
    
    private func curateArticles(_ articles: [Article]) -> [Article] {
        // Filter by curation criteria
        let filtered = articles.filter { $0.meetsCurationCriteria }
        
        // Sort by curation score (lower is better)
        let sorted = filtered.sorted { $0.curationScore() < $1.curationScore() }
        
        // Take top 30
        return Array(sorted.prefix(30))
    }
    
    // MARK: - Location Search
    
    func searchLocation(_ query: String) async {
        guard !query.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(query)
            
            guard let location = placemarks.first?.location?.coordinate else {
                errorMessage = "Location not found"
                isLoading = false
                return
            }
            
            currentCoordinate = location
            searchQuery = placemarks.first?.name ?? query
            
            // Refresh with new location
            await refreshArticles()
            
        } catch {
            errorMessage = "Geocoding failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func useCurrentLocation(from locationManager: LocationManager) async {
        searchQuery = ""
        
        if let location = await locationManager.fetchLocation() {
            currentCoordinate = location
            await refreshArticles()
        } else {
            errorMessage = "Failed to get current location"
        }
    }
    
    // MARK: - Article Selection
    
    func selectArticle(_ article: Article) {
        selectedArticle = article
    }
    
    func clearSelection() {
        selectedArticle = nil
    }
}
