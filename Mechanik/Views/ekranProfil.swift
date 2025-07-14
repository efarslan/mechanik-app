//
//  ekranProfil.swift
//  Mechanik
//
//  Created by efe arslan on 21.04.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import FirebaseStorage

// MARK: - View: ekranProfil Ana Ekran

struct ekranProfil: View {
    @State private var gosterSilinenAraclar = false
    @State private var cikisAlertGoster = false
    @State private var gosterHesapBilgileri = false
    @State private var gosterSifreDegistir = false
    @Environment(\.dismiss) var dismiss
    @State private var adSoyad: String = ""
    @State private var email: String = ""
    @State private var isletmeAdi: String = ""
    @State private var telefon: String = ""
    @State private var adres: String = ""
    @State private var profilFotoURL: String = ""
    
    var body: some View {
        VStack( alignment: .leading, spacing: 30) {
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                        .padding()
                }
            }
            
            // Profil Fotoğrafı
            VStack {
                if let url = URL(string: profilFotoURL), !profilFotoURL.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "person.crop.circle")
                                .resizable()
                                .foregroundColor(.gray.opacity(0.5))
                        case .success(let image):
                            image
                                .resizable()
                                .transition(.opacity)
                                .animation(.easeIn(duration: 0.3), value: UUID())
                        case .failure:
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .scaledToFill()
                    .frame(width: 90, height: 90)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .foregroundColor(.gray)
                }
                
                // User Info Section
                VStack(spacing: 4) {
                    Text("\(isletmeAdi) - \(adSoyad)")
                        .font(.headline)
                    Text(email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
            }
            
            VStack(spacing: 10) {
                profilAyarButon(icon: "person", title: "Hesap Bilgileri") {
                    gosterHesapBilgileri = true
                }
                profilAyarButon(icon: "arrow.counterclockwise", title: "Silinen Araçlar") {
                    gosterSilinenAraclar = true
                }
                profilAyarButon(icon: "lock", title: "Şifreyi Değiştir"){
                    gosterSifreDegistir = true
                }
                profilAyarButon(icon: "rectangle.portrait.and.arrow.forward", title: "Çıkış Yap", isDestructive: true) {
                    cikisAlertGoster = true
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .onAppear {
            if let uid = Auth.auth().currentUser?.uid {
                let db = Firestore.firestore()
                db.collection("kullanicilar").document(uid).getDocument { snapshot, error in
                    if let data = snapshot?.data() {
                        self.adSoyad = data["adSoyad"] as? String ?? ""
                        self.email = data["email"] as? String ?? ""
                        self.isletmeAdi = data["isletmeAdi"] as? String ?? ""
                        self.telefon = data["telefon"] as? String ?? ""
                        self.adres = data["adres"] as? String ?? ""
                        self.profilFotoURL = data["profilFotoURL"] as? String ?? ""
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.seaSalt)
        
        .sheet(isPresented: $gosterHesapBilgileri) {
            ekranHesapBilgileri(adSoyad: $adSoyad, email: $email, isletmeAdi: $isletmeAdi, telefon: $telefon, adres: $adres, profilFotoURL: profilFotoURL)
                .presentationDetents([.large])
                .presentationCornerRadius(25)
                .presentationDragIndicator(.visible)
        }
        
        
        .sheet(isPresented: $gosterSilinenAraclar) {
            ekranSilinenAraclar()
                .presentationDetents([.large])
                .presentationCornerRadius(25)
                .presentationDragIndicator(.visible)
        }
        
        .sheet(isPresented: $gosterSifreDegistir) {
            ekranSifreDegistir()
                .presentationDetents([.large])
                .presentationCornerRadius(25)
                .presentationDragIndicator(.visible)
        }
        
        .alert("Çıkış Yapmak Üzeresiniz", isPresented: $cikisAlertGoster) {
            Button("İptal", role: .cancel) { }
            Button("Çıkış Yap", role: .destructive) {
                do {
                    // Clear UserDefaults (reset app cache)
                    UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                    UserDefaults.standard.synchronize()
                    try Auth.auth().signOut()
                    withAnimation {
                        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = scene.windows.first {
                            window.rootViewController = UIHostingController(rootView: ekranLogin())
                            window.makeKeyAndVisible()
                        }
                    }
                } catch {
#if DEBUG
                    print("Çıkış yapılırken hata oluştu: \(error.localizedDescription)")
#endif
                }
            }
        } message: {
            Text("Uygulamadan çıkış yapmak istediğinize emin misiniz?")
        }
    }
    // MARK: - ViewBuilder: Ayar Butonu
    
    @ViewBuilder
    func profilAyarButon(icon: String, title: String, isDestructive: Bool = false, action: (() -> Void)? = nil) -> some View {
        Button(action: {
            action?()
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isDestructive ? .red : .black)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .foregroundColor(isDestructive ? .red : .black)
                    .font(.body)
                    .padding(.leading, 8)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
}
// MARK: - View: Hesap Bilgileri Sayfası

struct ekranHesapBilgileri: View {
    @Binding var adSoyad: String
    @Binding var email: String
    @Binding var isletmeAdi: String
    @Binding var telefon: String
    @Binding var adres: String
    var profilFotoURL: String
    @Environment(\.dismiss) var dismiss
    
    @State private var secilenGorsel: PhotosPickerItem?
    @State private var profilResmiData: Data?
    @State private var gosterFotoSecenekleri = false
    @State private var gorselPickerAcik = false
    var body: some View {
        NavigationView {
            VStack {
                Group {
                    if let data = profilResmiData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                    } else if let url = URL(string: profilFotoURL), !profilFotoURL.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .foregroundColor(.gray.opacity(0.5))
                            case .success(let image):
                                image
                                    .resizable()
                                    .transition(.opacity)
                                    .animation(.easeIn(duration: 0.3), value: UUID())
                            case .failure:
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                }
                .scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                .padding(.vertical, 30)
                .onLongPressGesture {
                    gosterFotoSecenekleri = true
                }
                .confirmationDialog("", isPresented: $gosterFotoSecenekleri, titleVisibility: .hidden) {
                    Button("Profil Fotoğrafını Değiştir") {
                        gorselPickerAcik = true
                    }
                    Button("Profil Fotoğrafını Kaldır", role: .destructive) {
                        // Fotoğrafı kaldırma işlemleri
                        self.profilResmiData = nil
                        if let uid = Auth.auth().currentUser?.uid {
                            let db = Firestore.firestore()
                            db.collection("kullanicilar").document(uid).updateData(["profilFotoURL": ""]) { error in
                                // Hata yönetimi yapılabilir
                            }
                        }
                    }
                    Button("İptal", role: .cancel) {}
                }
                
                Divider()
                
                HStack{
                    Text("Ad Soyad")
                        .frame(width: 140, alignment: .leading)
                        .padding(.leading, 5)
                    
                    TextField("Ad Soyad", text: $adSoyad)
                        .autocapitalization(.words)
                }
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.vertical)
                GradientDivider()
                
                HStack{
                    Text("E-Posta")
                        .frame(width: 140, alignment: .leading)
                        .padding(.leading, 5)
                    
                    TextField("E-Posta", text: $email)
                        .autocapitalization(.none)
                }
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.vertical)
                GradientDivider()
                
                HStack{
                    Text("İşletme Adı")
                        .frame(width: 140, alignment: .leading)
                        .padding(.leading, 5)
                    
                    TextField("İşletme Adı", text: $isletmeAdi)
                        .autocapitalization(.none)
                }
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.vertical)
                GradientDivider()
                
                HStack {
                    Text("Telefon")
                        .frame(width: 140, alignment: .leading)
                        .padding(.leading, 5)
                    
                    TextField("Telefon", text: $telefon)
                        .keyboardType(.phonePad)
                }
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.vertical)
                GradientDivider()
                
                HStack {
                    Text("Adres")
                        .frame(width: 140, alignment: .leading)
                        .padding(.leading, 5)
                    
                    TextField("Adres", text: $adres)
                }
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.vertical)
                Divider()
                Spacer()
                
                // Hidden PhotosPicker
                PhotosPicker(selection: $secilenGorsel, matching: .images) {
                    EmptyView()
                }
                .opacity(0)
                .frame(width: 0, height: 0)
                .sheet(isPresented: $gorselPickerAcik) {
                    PhotosPicker(selection: $secilenGorsel, matching: .images) {
                        EmptyView()
                    }
                }
                .onChange(of: secilenGorsel) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            self.profilResmiData = data
                            if let uid = Auth.auth().currentUser?.uid {
                                let storageRef = Storage.storage().reference().child("profilResimleri/\(uid).jpg")
                                _ = try? await storageRef.putDataAsync(data, metadata: nil)
                                let downloadURL = try? await storageRef.downloadURL()
                                if let url = downloadURL {
                                    let db = Firestore.firestore()
                                    try? await db.collection("kullanicilar").document(uid).updateData(["profilFotoURL": url.absoluteString])
                                }
                            }
                        }
                        gorselPickerAcik = false
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        if let uid = Auth.auth().currentUser?.uid {
                            let db = Firestore.firestore()
                            let ref = db.collection("kullanicilar").document(uid)
                            ref.updateData([
                                "adSoyad": adSoyad,
                                "email": email,
                                "isletmeAdi": isletmeAdi,
                                "telefon": telefon,
                                "adres": adres
                            ]) { error in
                                if let error = error {
#if DEBUG
                                    print("Güncelleme hatası: \(error.localizedDescription)")
#endif
                                } else {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - View: Şifre Değiştir Sayfası

struct ekranSifreDegistir: View {
    @Environment(\.dismiss) var dismiss
    @State private var mevcutSifre: String = ""
    @State private var yeniSifre: String = ""
    @State private var yeniSifreTekrar: String = ""
    @State private var mevcutSifreGizli: Bool = true
    @State private var yeniSifreGizli: Bool = true
    @State private var yeniSifreTekrarGizli: Bool = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Şifreyi Değiştir")
                            .font(.title2.bold())
                            .padding(.bottom, 4)
                        
                        Text("Şifre en az 6 karakter olmalı, rakam, harf ve özel karakter içermelidir.")
                            .font(.callout).bold()
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image("password")
                        .resizable()
                        .frame(width: 200, height: 200)
                }
                
                HStack {
                    if mevcutSifreGizli {
                        SecureField("Mevcut Şifre", text: $mevcutSifre)
                    } else {
                        TextField("Mevcut Şifre", text: $mevcutSifre)
                    }
                    Button(action: { mevcutSifreGizli.toggle() }) {
                        Image(systemName: mevcutSifreGizli ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                HStack {
                    if yeniSifreGizli {
                        SecureField("Yeni Şifre", text: $yeniSifre)
                    } else {
                        TextField("Yeni Şifre", text: $yeniSifre)
                    }
                    Button(action: { yeniSifreGizli.toggle() }) {
                        Image(systemName: yeniSifreGizli ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                HStack {
                    if yeniSifreTekrarGizli {
                        SecureField("Yeni Şifre (Tekrar)", text: $yeniSifreTekrar)
                    } else {
                        TextField("Yeni Şifre (Tekrar)", text: $yeniSifreTekrar)
                    }
                    Button(action: { yeniSifreTekrarGizli.toggle() }) {
                        Image(systemName: yeniSifreTekrarGizli ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Button("Şifremi Unuttum") {
                    // future implementation
                }
                .foregroundColor(.blue)
                .padding(.top)
                
                Spacer()
                
                Button(action: {
                    guard yeniSifre == yeniSifreTekrar else {
#if DEBUG
                        print("Yeni şifreler uyuşmuyor.")
#endif
                        return
                    }
                    
                    guard let user = Auth.auth().currentUser, let email = user.email else {
#if DEBUG
                        print("Kullanıcı oturumu geçersiz.")
#endif
                        return
                    }
                    
                    let credential = EmailAuthProvider.credential(withEmail: email, password: mevcutSifre)
                    
                    user.reauthenticate(with: credential) { result, error in
                        if let error = error {
#if DEBUG
                            print("Mevcut şifre hatalı: \(error.localizedDescription)")
#endif
                        } else {
                            user.updatePassword(to: yeniSifre) { error in
                                if let error = error {
#if DEBUG
                                    print("Şifre güncellenemedi: \(error.localizedDescription)")
#endif
                                } else {
#if DEBUG
                                    print("Şifre başarıyla güncellendi.")
#endif
                                    dismiss()
                                }
                            }
                        }
                    }
                }) {
                    Text("Şifreyi Değiştir")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((yeniSifre.isEmpty || mevcutSifre.isEmpty || yeniSifreTekrar.isEmpty ? Color.gray : Color.blue)
                            .animation(.easeInOut, value: yeniSifre.isEmpty || mevcutSifre.isEmpty || yeniSifreTekrar.isEmpty)
                        )
                    
                        .cornerRadius(24)
                }
                
                Spacer()
            }
            .padding(.top, 50)
            .padding(.horizontal)
        }
        .onTapGesture {
            klavyeyiGizle()
        }
        
    }
}

#Preview {
    ekranProfil()
}

