//
//  ekranSplash.swift
//  Mechanik
//
//  Created by efe arslan on 24.05.2025.
//

import SwiftUI

struct ekranSplash: View {
    @State private var logoScale: CGFloat = 0.6
    var body: some View {
            Image("appLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 250)
                .scaleEffect(logoScale)
                // MARK: - Animasyon: Logo Büyütme
                .onAppear {
                    withAnimation(.easeOut(duration: 1.0)) {
                        logoScale = 1.0
                    }
                }

    }
}

#Preview {
    ekranSplash()
}
