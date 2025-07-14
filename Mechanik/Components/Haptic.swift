//
//  Haptic.swift
//  Mechanik
//
//  Created by efe arslan on 12.07.2025.
//

import SwiftUI

func titreşimVer() {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.prepare()
    generator.impactOccurred()
}
