//
//  LoginEkran.swift
//  Mechanik
//
//  Created by efe arslan on 6.02.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import FirebaseCore

struct ekranLogin: View {
    @State private var email: String = ""
    @State private var emailKayit: String = ""
    @State private var emailSifirla: String = ""
    @State private var sifreGiris: String = ""
    @State private var sifreKayit: String = ""
    
    @State private var girisBasarili: Bool = false
    @State private var hataMesaji: String?
    @State private var sifreGizli: Bool = true
    @State private var seciliTab: String = "login"

    @State private var isletmeAdi: String = ""
    @State private var adSoyad: String = ""
    @State private var dogrulamaAlertiGoster: Bool = false
    @State private var gosterKayitAlert: Bool = false
    @State private var ekranGorunur: Bool = false
    @State private var sifreUnuttumPopupGoster: Bool = false
    @State private var googleGirisYapildi : Bool = false
    
    

    var body: some View {
        ZStack {
            if girisBasarili {
                altTab()
            } else {
                Color.white
                    .ignoresSafeArea(.all)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Image("appLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                        
                        VStack {

                            HStack(spacing: 0) {

                                Button(action: {
                                    withAnimation {
                                        seciliTab = "login"
                                        hataMesaji = ""
                                    }
                                }) {
                                    Text("Giriş Yap")
                                        .foregroundColor(seciliTab == "login" ? .black : .gray)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            ZStack {
                                                if seciliTab == "login" {
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .fill(Color.white)
                                                        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
                                                }
                                            }
                                        )
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        seciliTab = "register"
                                    }
                                }) {
                                    Text("Kayıt Ol")
                                        .foregroundColor(seciliTab == "register" ? .black : .gray)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            ZStack {
                                                if seciliTab == "register" {
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .fill(Color.white)
                                                        .shadow(color: .gray.opacity(0.2), radius: 3, x: 0, y: 2)
                                                }
                                            }
                                        )
                                }
                            }
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.gray, lineWidth: 1))
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                            
                            if seciliTab == "login" {
                                TextField("E-Posta", text: $email)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .padding()
                                    .background(Color.seaSalt)
                                    .cornerRadius(24)
                                    .padding(.horizontal)
                                
                                HStack {
                                    Group {
                                        if sifreGizli {
                                            SecureField("Şifre", text: $sifreGiris)
                                                .autocapitalization(.none)
                                        } else {
                                            TextField("Şifre", text: $sifreGiris)
                                                .autocapitalization(.none)
                                        }
                                    }
                                    .frame(height: 20)
                                    .padding(.vertical, 10)
                                    
                                    Button(action: {
                                        sifreGizli.toggle()
                                    }) {
                                        Image(systemName: sifreGizli ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .frame(height: 50)
                                .background(Color.seaSalt)
                                .cornerRadius(24)
                                .padding(.horizontal)
                                .padding(.top)
                                
                                // Hata mesajı gösterimi
                                if let hata = hataMesaji, !hata.isEmpty {
                                    Text(hata)
                                        .foregroundColor(.red)
                                        .font(.footnote)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                        .padding(.top)
                                }
                                
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        sifreUnuttumPopupGoster = true
                                    }) {
                                        Text("Şifremi Unuttum")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 32)
                                            .padding(.top)
                                    }
                                }

                                
                                Button(action: {
                                    Auth.auth().signIn(withEmail: email, password: sifreGiris) { result, error in
                                        if let error = error {
                                            let hataKod = (error as NSError).code
                                            if hataKod == AuthErrorCode.wrongPassword.rawValue ||
                                               hataKod == AuthErrorCode.userNotFound.rawValue ||
                                               hataKod == AuthErrorCode.invalidEmail.rawValue ||
                                               error.localizedDescription.contains("The supplied auth credential is malformed or has expired.") {
                                                hataMesaji = "Bilgilerinizi kontrol ediniz."
                                            } else {
                                                hataMesaji = error.localizedDescription
                                            }
                                        } else if let user = Auth.auth().currentUser {
                                            user.reload { _ in
                                                if user.isEmailVerified {
                                                    DispatchQueue.main.async {
                                                        girisBasarili = true
                                                    }
                                                } else {
                                                    dogrulamaAlertiGoster = true
                                                    user.sendEmailVerification()
                                                    try? Auth.auth().signOut()
                                                }
                                            }
                                        }
                                    }
                                }) {
                                    Text("Giriş Yap")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                    
                                        .background(email.isEmpty || sifreGiris.isEmpty ? Color.gray : Color.init(hex: "#627b65"))
                                        .animation(.easeInOut, value: email.isEmpty || sifreGiris.isEmpty)
                                        .cornerRadius(24)
                                        .padding(.horizontal)
                                        .padding(.top)
                                }
                                .disabled(email.isEmpty || sifreGiris.isEmpty)
                                
                                .alert("E-posta Doğrulaması Gerekli", isPresented: $dogrulamaAlertiGoster) {
                                    Button("Tamam", role: .cancel) { }
                                } message: {
                                    Text("Lütfen e-posta adresinizi doğrulamak için size gönderilen bağlantıyı kontrol edin.")
                                }
                                
                            } else {
                                VStack {
                                    TextField("İşletme Adı", text: $isletmeAdi)
                                        .padding()
                                        .background(Color.seaSalt)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(hataMesaji != nil && isletmeAdi.isEmpty ? Color.red : Color.clear, lineWidth: 1)
                                        )
                                        .cornerRadius(24)
                                        .padding(.horizontal)
                                    
                                    TextField("Ad Soyad", text: $adSoyad)
                                        .padding()
                                        .background(Color.seaSalt)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(hataMesaji != nil && adSoyad.isEmpty ? Color.red : Color.clear, lineWidth: 1)
                                        )
                                        .cornerRadius(24)
                                        .padding(.horizontal)
                                        .padding(.top)
                                    
                                    TextField("E-Posta", text: $emailKayit)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                        .textContentType(.emailAddress)
                                        .padding()
                                        .background(Color.seaSalt)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(hataMesaji != nil && emailKayit.isEmpty ? Color.red : Color.clear, lineWidth: 1)
                                        )
                                        .cornerRadius(24)
                                        .padding(.horizontal)
                                        .padding(.top)
                                    
                                    ZStack(alignment: .trailing) {
                                        Group {
                                            if sifreGizli {
                                                SecureField("Şifre", text: $sifreKayit)
                                                    .textContentType(.newPassword)
                                                    .autocapitalization(.none)
                                                    .autocorrectionDisabled(true)
                                            } else {
                                                TextField("Şifre", text: $sifreKayit)
                                                    .textContentType(.newPassword)
                                                    .autocapitalization(.none)
                                                    .autocorrectionDisabled(true)
                                            }
                                        }
                                        .padding(.leading)
                                        
                                        Button(action: {
                                            sifreGizli.toggle()
                                        }) {
                                            Image(systemName: sifreGizli ? "eye.slash" : "eye")
                                                .foregroundColor(.gray)
                                                .padding()
                                        }
                                    }
                                    .frame(height: 50)
                                    .background(Color.seaSalt)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(hataMesaji != nil && sifreKayit.isEmpty ? Color.red : Color.clear, lineWidth: 1)
                                    )
                                    .cornerRadius(24)
                                    .padding(.horizontal)
                                    .padding(.top)
                                }
                                Text("Kayıt olarak kullanım şartlarını ve gizlilik politikasını kabul etmiş olursunuz.")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 6)
                                    .padding(.horizontal)
                                Button(action: {
                                    if emailKayit.isEmpty || sifreKayit.isEmpty || isletmeAdi.isEmpty || adSoyad.isEmpty {
                                        hataMesaji = "Lütfen tüm alanları doldurun."
                                        return
                                    }
                                    Auth.auth().createUser(withEmail: emailKayit, password: sifreKayit) { result, error in
                                        if let error = error {
                                            hataMesaji = error.localizedDescription
                                        } else if let user = result?.user {
                                            user.sendEmailVerification { error in
                                                if let error = error {
                                                    hataMesaji = "Doğrulama e-postası gönderilemedi: \(error.localizedDescription)"
                                                } else {
                                                    gosterKayitAlert = true
                                                }
                                            }
                                            
                                            let db = Firestore.firestore()
                                            db.collection("kullanicilar").document(user.uid).setData([
                                                "email": emailKayit,
                                                "isletmeAdi": isletmeAdi,
                                                "adSoyad": adSoyad,
                                                "kayitDurumu": "tamam"
                                            ]) { error in
                                                if let error = error {
                                                    hataMesaji = error.localizedDescription
                                                }
                                            }
                                        }
                                    }
                                }) {
                                    Text("Kayıt Ol")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(red: 97/255, green: 123/255, blue: 101/255))
                                        .cornerRadius(24)
                                        .padding(.horizontal)
                                        .padding(.bottom, 60)
                                }
                                .padding(.top, 33)
                                
                                .alert("Kayıt Başarılı", isPresented: $gosterKayitAlert) {
                                    Button("Tamam", role: .cancel) {
                                        seciliTab = "login"
                                        emailKayit = ""
                                        sifreKayit = ""
                                        isletmeAdi = ""
                                        adSoyad = ""
                                        hataMesaji = ""
                                    }
                                } message: {
                                    Text("Hesabınız başarıyla oluşturuldu. Lütfen e-posta adresinize gönderilen doğrulama bağlantısına tıklayarak hesabınızı aktif hale getirin.")
                                }
                            }
                            
                            if seciliTab == "login" {
                                HStack {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(height: 1)
                                    Text("veya")
                                        .foregroundColor(.gray)
                                        .padding(.horizontal)
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(height: 1)
                                }
                                .padding(.vertical)
                                
                                VStack(spacing: 15) {

                                    Button(action: {
                                        googleIleGirisYap()
                                    }) {
                                        HStack {
                                            Image("google")
                                                .resizable()
                                                .frame(width: 25, height: 25)
                                            Spacer()
                                            Text("Google ile devam et")
                                                .fontWeight(.bold)
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray, lineWidth: 1)
                                        )
                                    }
                                    
                                    HStack {
                                        Image(systemName: "applelogo")
                                            .resizable()
                                            .frame(width: 23, height: 25)
                                        Spacer()
                                        Text("Apple ile devam et")
                                            .fontWeight(.bold)
                                        Spacer()
                                        
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 60)
                            }
                        }
                    }
                    .padding()
                }
                .opacity(ekranGorunur ? 1 : 0)
                .offset(y: ekranGorunur ? 0 : 40)
                .animation(.easeOut(duration: 0.5), value: ekranGorunur)
            }
        }
        .overlay(
            Group {
                if sifreUnuttumPopupGoster {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    ZStack(alignment: .topTrailing) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("E-Posta")
                                .font(.title)
                                .padding(.top)
                            
                            Text("Şifrenizi sıfırlamanız için size bir e-posta göndereceğiz.")
                                .font(.subheadline)
                                .padding(.bottom, 20)
                            
                            TextField("E-Posta", text: $emailSifirla)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .padding()
                                .background(Color.seaSalt)
                                .cornerRadius(24)
                            
                            Button("Devam Et") {
                                guard !emailSifirla.isEmpty else { return }
                                
                                let temizlenmisEmail = emailSifirla.trimmingCharacters(in: .whitespacesAndNewlines)

                                Auth.auth().sendPasswordReset(withEmail: temizlenmisEmail) { error in
                                    if let error = error {
#if DEBUG
                                        print("Şifre sıfırlama hatası: \(error.localizedDescription)")
#endif
                                        hataMesaji = "Bu e-posta ile ilişkili bir kullanıcı bulunamadı."
                                    } else {
#if DEBUG
                                        print("Şifre sıfırlama e-postası gönderildi.")
#endif
                                        sifreUnuttumPopupGoster = false
                                        hataMesaji = nil
                                    }
                                }
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#627b65"))
                            .cornerRadius(24)
                            .padding(.top)
                        }
                        .padding()
                        .frame(width: 350)
                        .background(Color.white)
                        .cornerRadius(24)
                        .shadow(radius: 10)

                        Button(action: {
                            sifreUnuttumPopupGoster = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.gray)
                                .padding(8)
                        }
                    }
                }
            }
        )
        // MARK: - Sheet: Google Giriş Sonrası Bilgi Tamamlama
        .sheet(isPresented: $googleGirisYapildi) {
            VStack(spacing: 20) {

                    Image("infos")
                        .resizable()
                        .frame(width: 200, height: 200)
                HStack{
                    Text("Bilgileri Tamamla")
                        .font(.title2)
                        .padding(.horizontal)
                        .foregroundColor(.gray)
                    
                    Spacer()
                }

                TextField("Ad Soyad", text: $adSoyad)
                    .padding()
                    .background(Color.seaSalt)
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .padding(.top, 20)

                TextField("İşletme Adı", text: $isletmeAdi)
                    .padding()
                    .background(Color.seaSalt)
                    .cornerRadius(24)
                    .padding(.horizontal)

                Button("Devam Et") {
                    guard !isletmeAdi.isEmpty else {
                        hataMesaji = "İşletme adı boş bırakılamaz."
                        return
                    }

                    if let uid = Auth.auth().currentUser?.uid {
                        let db = Firestore.firestore()
                        db.collection("kullanicilar").document(uid).setData([
                            "email": email,
                            "isletmeAdi": isletmeAdi,
                            "adSoyad": adSoyad
                        ]) { error in
                            if let error = error {
                                hataMesaji = error.localizedDescription
                            } else {
                                // Update kayitDurumu to "tamam" before proceeding
                                db.collection("kullanicilar").document(uid).updateData([
                                    "kayitDurumu": "tamam"
                                ]) { _ in
                                    DispatchQueue.main.async {
                                        googleGirisYapildi = false
                                        girisBasarili = true
                                    }
                                }
                            }
                        }
                    }
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(adSoyad.isEmpty || isletmeAdi.isEmpty ? Color.gray : Color(hex: "#627b65"))
                .animation(.easeInOut, value: adSoyad.isEmpty || isletmeAdi.isEmpty)
                .cornerRadius(24)
                .padding(.horizontal)
                .padding(.top, 20)
                .disabled(adSoyad.isEmpty || isletmeAdi.isEmpty)

                Spacer()
            }
            .padding()
            .interactiveDismissDisabled(true)
            .onTapGesture {
                klavyeyiGizle()
            }
        }
        // MARK: - onAppear: Oturum Kontrolü
        .onAppear {
            ekranGorunur = true
            DispatchQueue.global(qos: .userInitiated).async {
                if let user = Auth.auth().currentUser {
                    let db = Firestore.firestore()
                    db.collection("kullanicilar").document(user.uid).getDocument { document, error in
                        DispatchQueue.main.async {
                            if let document = document, document.exists {
                                let data = document.data()
                                let kayitDurumu = data?["kayitDurumu"] as? String ?? ""
                                if kayitDurumu == "tamam" {
                                    self.girisBasarili = true
                                } else {
                                    try? Auth.auth().signOut()
                                }
                            } else {
                                try? Auth.auth().signOut()
                            }
                        }
                    }
                }
            }
        }
        
        .onTapGesture {
            klavyeyiGizle()
        }

    }
    
    // MARK: - Google ile Giriş
    func googleIleGirisYap() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }

        let config = GIDConfiguration(clientID: clientID)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }

        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { result, error in
            if let error = error {
                hataMesaji = error.localizedDescription
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                hataMesaji = "Google hesabı bilgileri alınamadı."
                return
            }

            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    hataMesaji = error.localizedDescription
                } else if let uid = Auth.auth().currentUser?.uid {
                    let db = Firestore.firestore()
                    db.collection("kullanicilar").document(uid).getDocument { document, error in
                        if let document = document, document.exists {
                            let data = document.data()
                            let kayitDurumu = data?["kayitDurumu"] as? String ?? ""
                            if kayitDurumu == "tamam" {
                                self.girisBasarili = true
                            } else {
                                self.email = user.profile?.email ?? ""
                                self.adSoyad = user.profile?.name ?? ""
                                self.googleGirisYapildi = true
                            }
                        } else {
                            self.email = user.profile?.email ?? ""
                            self.adSoyad = user.profile?.name ?? ""
                            self.googleGirisYapildi = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ekranLogin()
}

