//
//  TabView.swift
//  Mechanik
//
//  Created by efe arslan on 11.02.2025.
//

import SwiftUI
import UIKit

struct altTab: View {
    @State private var secilenSayfa = -1
    @State var popupGoster: Bool = false // yeni eklendi

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $secilenSayfa) {
                    ekranAna(popupGoster: $popupGoster)
                        .tag(1)
                    ekranAraclar()
                        .tag(2)
                    ekranAnımsatıcı()
                        .tag(3)
                }
                .toolbar(.hidden, for: .tabBar)
                .overlay(alignment: .bottom) {
                    CustomTabView(secilenSayfa: $secilenSayfa)
                        .disabled(popupGoster)
                        .blur(radius: popupGoster ? 3 : 0)
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    secilenSayfa = 1
                }
            }
        }
    }
}

struct CustomTabView: View {
    @Binding var secilenSayfa: Int
    
    @Namespace private var animationNamespace
    @State private var animateTab: Bool = false

    let tabBarItems: [(image: String, title: String)] = [
        ("house", "Ana Ekran"),
        ("car", "Araçlar"),
        ("calendar.badge.clock", "Anımsatıcı")
    ]

    var body: some View {
        HStack {
            ForEach(0..<tabBarItems.count, id: \.self) { index in
                let isSelected = secilenSayfa == index + 1

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        animateTab.toggle()
                        secilenSayfa = index + 1
                    }
                } label: {
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.myRed)
                                .frame(width: 50, height: 50)
                        }
                        
                        Image(systemName: tabBarItems[index].image)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(isSelected ? .white : .gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.myBlack)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
        )
        .padding(.horizontal, 30)
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}


#Preview {
    altTab()
    
}

