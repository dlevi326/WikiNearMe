//
//  NearbyViewModel.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import Foundation
import CoreLocation
import MapKit
import Observation

/// ViewModel managing nearby article discovery and state
@MainActor
@Observable
class NearbyViewModel: NSObject, MKLocalSearchCompleterDelegate {
    // State
    var articles: [Article] = []
    var selectedArticle: Article?
    var isLoading = false
    var errorMessage: String?
    
    // Location state
    var currentCoordinate: CLLocationCoordinate2D?
    var radiusMeters: Int = 805 // 0.5 miles default
    var searchQuery = ""
    var locationSuggestions: [LocationSuggestion] = []
    
    // Services
    private let wikipediaClient = WikipediaClient()
    private let geocoder = CLGeocoder()
    private let searchCompleter = MKLocalSearchCompleter()
    
    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }
    
    // Computed
    var radiusMiles: Double {
        Double(radiusMeters) / 1609.34
    }
    
    func setRadiusMiles(_ miles: Double) {
        // Convert to meters with minimum of 10 meters
        let meters = miles * 1609.34
        radiusMeters = max(10, Int(meters))
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
            
            // Calculate distance for articles that have coordinates but no distance
            let articlesWithDistance = articlesWithSummaries.map { article -> Article in
                if article.distanceMeters == nil, let articleCoord = article.coordinate {
                    let distance = calculateDistance(
                        from: coordinate,
                        to: articleCoord.clCoordinate
                    )
                    return Article(
                        id: article.id,
                        title: article.title,
                        distanceMeters: distance,
                        extract: article.extract,
                        thumbnailURL: article.thumbnailURL,
                        pageURL: article.pageURL,
                        coordinate: article.coordinate,
                        source: article.source
                    )
                }
                return article
            }
            
            // Filter by radius - only include articles within the specified radius
            let withinRadius = articlesWithDistance.filter { article in
                guard let distance = article.distanceMeters else { return false }
                return distance <= Double(radiusMeters)
            }
            
            // Apply curation
            let curated = curateArticles(withinRadius)
            
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
    
    /// Fetch location suggestions for autocomplete
    func fetchLocationSuggestions(for query: String) {
        guard !query.isEmpty else {
            locationSuggestions = []
            searchCompleter.cancel()
            return
        }
        
        searchCompleter.queryFragment = query
    }
    
    /// MKLocalSearchCompleterDelegate method
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            // Convert search results to location suggestions
            let results = completer.results.prefix(8).map { result in
                LocationSuggestion(
                    title: result.title,
                    subtitle: result.subtitle,
                    completion: result
                )
            }
            locationSuggestions = results
        }
    }
    
    /// MKLocalSearchCompleterDelegate method
    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            locationSuggestions = []
        }
    }
    
    /// Select a location from suggestions
    func selectLocationSuggestion(_ suggestion: LocationSuggestion) async {
        guard let completion = suggestion.completion else { return }
        
        // Perform search to get the actual coordinate
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            if let mapItem = response.mapItems.first {
                currentCoordinate = mapItem.placemark.coordinate
                searchQuery = suggestion.title
                locationSuggestions = []
                await refreshArticles()
            }
        } catch {
            errorMessage = "Failed to resolve location"
        }
    }
    
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
        locationSuggestions = []
        
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
    
    // MARK: - Helper
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation)
    }
}

// MARK: - Location Suggestion

struct LocationSuggestion: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let completion: MKLocalSearchCompletion?
    
    init(title: String, subtitle: String, completion: MKLocalSearchCompletion?) {
        self.title = title
        self.subtitle = subtitle
        self.completion = completion
    }
    
    static func == (lhs: LocationSuggestion, rhs: LocationSuggestion) -> Bool {
        lhs.id == rhs.id
    }
}
