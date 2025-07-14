//
//  GradientDivider.swift
//  Mechanik
//
//  Created by efe arslan on 12.07.2025.
//

import SwiftUI

struct GradientDivider: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .white.opacity(0.6), location: 0.0),
                        .init(color: .white.opacity(0.6), location: 0.40),
                        .init(color: .gray.opacity(0.5), location: 0.40),
                        .init(color: .gray.opacity(0.5), location: 1.0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 0.5)
            .padding(.horizontal)
    }
}
