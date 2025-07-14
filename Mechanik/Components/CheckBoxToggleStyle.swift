//
//  CheckBoxToggleStyle.swift
//  Mechanik
//
//  Created by efe arslan on 12.07.2025.
//

import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .black : .gray)
                configuration.label
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
