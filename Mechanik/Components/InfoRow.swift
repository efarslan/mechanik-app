//
//  InfoRow.swift
//  Mechanik
//
//  Created by efe arslan on 12.07.2025.
//
import SwiftUI

struct InfoRow: View {
    var title: String
    var value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.myBlack)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.myBlack.opacity(0.7))
        }
    }
}
