//
//  klavyeyiGizle.swift
//  Mechanik
//
//  Created by efe arslan on 12.07.2025.
//

import SwiftUI

func klavyeyiGizle() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
