//
//  AsyncImageView.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import SwiftUI

/// Reusable async image view with placeholder
struct AsyncImageView: View {
    let url: URL?
    let width: CGFloat?
    let height: CGFloat?
    
    init(url: URL?, width: CGFloat? = nil, height: CGFloat? = nil) {
        self.url = url
        self.width = width
        self.height = height
    }
    
    var body: some View {
        if let url = url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: width, height: height)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                case .failure:
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                        .frame(width: width, height: height)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(systemName: "photo")
                .foregroundStyle(.secondary)
                .frame(width: width, height: height)
        }
    }
}
