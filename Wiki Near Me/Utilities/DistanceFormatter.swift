//
//  DistanceFormatter.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import Foundation

/// Formats distances in miles/feet
struct DistanceFormatter {
    /// Format distance in meters to miles or feet
    static func format(meters: Double?) -> String {
        guard let meters = meters else {
            return ""
        }
        
        let miles = meters / 1609.34
        
        if miles >= 0.1 {
            // Show miles
            return String(format: "%.1f mi", miles)
        } else {
            // Show feet for distances under 0.1 miles
            let feet = meters * 3.28084
            return String(format: "%.0f ft", feet)
        }
    }
}
