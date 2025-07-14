//
//  MechanikApp.swift
//  Mechanik
//
//  Created by efe arslan on 30.03.2025.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import Network
import Foundation

// MARK: - AppDelegate: Firebase ve Google Giriş Yapılandırması
class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
      return true
  }
  
  func application(_ app: UIApplication, open url: URL,
                   options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      return GIDSignIn.sharedInstance.handle(url)
  }
}

// MARK: - Ağ İzleme Sınıfı
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected: Bool = true
    
    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    deinit {
        monitor.cancel()
    }
}

// MARK: - Uygulama Giriş Noktası
@main
struct MechanikApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var splashGoster = true
    @State private var girisBasarili = false
    @State private var girisKontrolEdiliyor = true
    @StateObject private var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            if splashGoster {
                ekranSplash()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { // TODO: Splash süresi dinamik yapılabilir (ayar dosyasına taşınabilir)
                            splashGoster = false
                            kullaniciKontrolEt()
                        }
                    }
            } else {
                if !networkMonitor.isConnected {
                    VStack(spacing: 20) {
                        Image(systemName: "wifi.exclamationmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        Text("İnternet bağlantısı yok.")
                            .font(.headline)
                        Text("Lütfen bağlantınızı kontrol edin.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        ProgressView()
                            .padding(.top, 20)
                    }
                    .padding()
                } else {
                    if girisKontrolEdiliyor {
                        Image("appLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250)
                    } else {
                        if girisBasarili {
                            altTab()
                        } else {
                            ekranLogin()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Giriş Durumu Kontrolü
    func kullaniciKontrolEt() {
        if let user = Auth.auth().currentUser {
            #if DEBUG
            print("Kullanıcı kontrol ediliyor...")
            #endif
            let db = Firestore.firestore()
            db.collection("kullanicilar").document(user.uid).getDocument { document, error in
                if let document = document, document.exists {
                    let data = document.data()
                    let kayitDurumu = data?["kayitDurumu"] as? String ?? ""
                    if kayitDurumu == "tamam" {
                        girisBasarili = true
                    } else {
                        #if DEBUG
                        print("Kullanıcı bulunamadı veya kayıt tamam değil.")
                        #endif
                        try? Auth.auth().signOut()
                    }
                } else {
                    #if DEBUG
                    print("Kullanıcı bulunamadı veya kayıt tamam değil.")
                    #endif
                    try? Auth.auth().signOut()
                }
                girisKontrolEdiliyor = false
            }
        } else {
            girisKontrolEdiliyor = false
        }
    }
}
