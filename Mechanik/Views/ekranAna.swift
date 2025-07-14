//
//  Ana Ekran.swift
//  Mechanik
//
//  Created by efe arslan on 10.02.2025.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage


struct ekranAna: View {

    // MARK: - State Değişkenleri
    @State var plakaSorgulama = ""
    @State private var aracBilgisi: Arac? = nil
    @State private var navigateToDetail = false
    @State private var devamEdenIslemler: [DevamEdenIslem] = []
    @State private var seciliIslem: DevamEdenIslem? = nil
    @Binding var popupGoster: Bool
    @State private var islemTamamlandi = false
    @State private var yeniNotEki: String = ""
    @State private var gosterUyari = false
    @State private var gosterAracBulunamadiAlert = false
    @State private var gosterAracEkleSayfasi = false
    @State private var gosterSilOnay = false
    @State private var selectedGorselURLToDelete: String? = nil
    @State private var gosterGorselSilOnayi = false
    @State private var secilenTarih = Date()
    @State private var sonBakilanlar: [SonBakilanArac] = []
    @State private var kullaniciAdi: String = ""
    @State private var ekranYuklendi = false
    @State private var sonAramalarTemizlendi = false
    @State private var profilFotoURL: String = ""
    @State private var isPressingImage: Bool = false
    @State private var selectedImageURL: String? = nil
    @State private var gosterGorselBuyukUyari = false
    @State private var gosterGorselLimitUyari = false
    @State private var gorselSec = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImage: UIImage? = nil
    @State private var showGaleridenPicker = false
    @State private var gosterSecimDialog = false
    @State private var secilenKaynak: String? = nil
    @State private var gorselYukleniyor = false
    @FocusState private var isTyping: Bool

    // MARK: - Body
    var body: some View {
        NavigationStack{
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading){
                        // MARK: - Üst Bilgi (Karşılama ve Profil)
                        HStack{
                            VStack(alignment: .leading){
                                Text("Mechänik")
                                    .padding(.horizontal)
                                    .fontWeight(.thin)
                                
                                HStack(spacing: 0) {
                                    Text("Merhaba ")
                                        .foregroundColor(Color.myBlack)
                                    
                                    Text(kullaniciAdi)
                                        .foregroundColor(Color.myRed)
                                        .contrast(0.83)
                                }
                                .padding(.horizontal)
                                .font(.title)
                                .fontWeight(.bold)
                            }
                            Spacer()
                            NavigationLink(destination: ekranProfil()) {
                                if let url = URL(string: profilFotoURL), !profilFotoURL.isEmpty {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .empty:
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.gray.opacity(0.5))
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .transition(.opacity)
                                                .animation(.easeIn(duration: 0.3), value: UUID())
                                        case .failure:
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundColor(.gray)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .padding(.horizontal)
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(Color.myBlack)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 5)
                        .padding(.top, 30)
                        
                        // MARK: - Plaka Arama Alanı
                        VStack{
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                
                                TextField("Plaka", text: $plakaSorgulama)
                                    .autocapitalization(.allCharacters)
                                    .keyboardType(.asciiCapable)
                                    .onChange(of: plakaSorgulama) {
                                        var filteredValue = plakaSorgulama.uppercased().filter { $0.isLetter || $0.isNumber }
                                        if filteredValue.count > 9 {
                                            filteredValue = String(filteredValue.prefix(9))
                                        }
                                        plakaSorgulama = filteredValue
                                    }
                                    .onSubmit {
                                        araciGetir(plaka: plakaSorgulama)
                                    }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 15)
                            .background(Color.seaSalt)
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.clear, lineWidth: 0.5)
                            )
                            
                            // MARK: - Son Aramalar
                            if !sonBakilanlar.isEmpty {
                                // MARK: - Son Aramalar
                                HStack(spacing: 5) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundColor(.myBlack.opacity(0.7))
                                    
                                    Text("Son Aramalar")
                                        .foregroundColor(.myBlack.opacity(0.7))
                                    Spacer()
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            sonAramalarTemizlendi = true
                                            sonBakilanlar.removeAll()
                                            UserDefaults.standard.removeObject(forKey: "sonBakilanAraclar")
                                        }
                                    }) {
                                        Text("Temizle")
                                            .foregroundColor(.myRed)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .padding(.horizontal, 5)
                                }
                                .padding(.vertical, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(sonBakilanlar) { arac in
                                            Button(action: {
                                                plakaSorgulama = arac.plaka
                                                araciGetir(plaka: arac.plaka)
                                            }) {
                                                VStack{
                                                    VStack {
                                                        Image(arac.marka.lowercased() + "_logo")
                                                            .resizable()
                                                            .frame(width: 40, height: 40)
                                                    }
                                                    .frame(width: 70, height: 70)
                                                    .background(Color.white)
                                                    .clipShape(Circle())
                                                    .overlay(
                                                        Circle()
                                                            .stroke(Color.myRed, lineWidth: 1)
                                                    )
                                                    .padding(.horizontal, 20)
                                                    
                                                    Text(arac.plaka)
                                                        .foregroundColor(.black)
                                                        .font(.footnote)
                                                        .padding(.vertical, 5)
                                                }
                                                .padding(.top, 10)
                                            }
                                        }
                                    }
                                    .transition(.opacity)
                                }
                            }
                        }
                        .padding()
                        .shadow(radius: 0.5)
                        .padding(.horizontal)
                        
                        // MARK: - Devam Eden İşlemler
                        HStack(spacing: 6) {
                            Image(systemName: "hourglass")
                                .foregroundColor(.myBlack.opacity(0.7))
                            Text("Devam Eden İşlemler")
                                .foregroundColor(.myBlack.opacity(0.7))
                        }
                        .padding(.horizontal, 25)
                        .padding(.top, 20)
                        
                        // MARK: - Devam Eden İşlemler
                        ScrollView(.horizontal, showsIndicators: false) {
                            if !devamEdenIslemler.isEmpty {
                                HStack (spacing: 15) {
                                    ForEach(devamEdenIslemler) { islem in
                                        devamKart(
                                            logo: islem.marka.lowercased() + "_logo",
                                            arac: "\(islem.marka) \(islem.model) \(islem.yil)",
                                            plaka: islem.plaka,
                                            bakimTuru: islem.islemTuru,
                                            clicked: {
                                                let db = Firestore.firestore()
                                                if let userId = Auth.auth().currentUser?.uid, let islemID = islem.id {
                                                    db.collection("kullaniciAraclar").document(userId)
                                                        .collection("araclar").document(islem.plaka)
                                                        .collection("islemler").document(islemID)
                                                        .getDocument { snapshot, error in
                                                            if let document = snapshot, document.exists {
                                                                do {
                                                                    let guncellenmisIslem = try document.data(as: Islem.self)
                                                                    var yeni = islem
                                                                    yeni.gorselURLList = guncellenmisIslem.gorselURLList
                                                                    yeni.notlar = guncellenmisIslem.notlar
                                                                    yeni.tamamlandi = guncellenmisIslem.status == "Tamamlandı"
                                                                    seciliIslem = yeni
                                                                    yeniNotEki = guncellenmisIslem.notlar
                                                                    popupGoster = true
                                                                } catch {
                                                                    print("Veri işlenemedi: \(error.localizedDescription)")
                                                                }
                                                            }
                                                        }
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            } else {
                                VStack(alignment: .center) {
                                    HStack {
                                        Spacer(minLength: 35)
                                        Image("notFound")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: UIScreen.main.bounds.width * 0.75)
                                        Spacer()
                                    }
                                    Text("Devam Eden İşlem Bulunamadı.")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                        .padding(.bottom, 60)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 20)
                                .padding(.horizontal)
                            }
                        }
                        .disabled(devamEdenIslemler.isEmpty)
                        
                        // MARK: - Navigation & onAppear
                        .navigationDestination(isPresented: $navigateToDetail) {
                            if let arac = aracBilgisi {
                                ekranAracDetay(arac: arac, araciGetir: araciGetir)
                            }
                        }
                    }
                    .padding(.top, -10)
                    .onAppear {
                        guard !ekranYuklendi else { return }
                        // kullanıcı adını ve profil fotoğrafını Firestore'dan çek
                        if let uid = Auth.auth().currentUser?.uid {
                            let db = Firestore.firestore()
                            db.collection("kullanicilar").document(uid).getDocument { snapshot, error in
                                if let data = snapshot?.data() {
                                    if let adSoyad = data["adSoyad"] as? String {
                                        let isim = adSoyad.components(separatedBy: " ").first ?? ""
                                        self.kullaniciAdi = isim
                                    }
                                    if let fotoURL = data["profilFotoURL"] as? String {
                                        self.profilFotoURL = fotoURL
                                    }
                                }
                            }
                        }
                        ekranYuklendi = true
                        devamEdenIslemleriGetir()
                        if let data = UserDefaults.standard.data(forKey: "sonBakilanAraclar"),
                           let kayitli = try? JSONDecoder().decode([SonBakilanArac].self, from: data) {
                            sonBakilanlar = kayitli
                        }
                    }
                }
            }
            .refreshable {
                devamEdenIslemleriGetir()
            }
            

            .onTapGesture {
                klavyeyiGizle()
            }
            
            // MARK: - İşlem Düzenleme Popup
            .overlay(
                ZStack {
                    if popupGoster {
                        Rectangle()
                            .fill(Color.black.opacity(0.6))
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation {
                                    popupGoster = false
                                    seciliIslem = nil
                                }
                            }
                        VStack(alignment: .leading) {
                            // MARK: - Görsel Carousel & Ekleme Butonu
                            if let urls = seciliIslem?.gorselURLList, !urls.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(urls, id: \.self) { urlStr in
                                            AsyncImage(url: URL(string: urlStr)) { phase in
                                                if let image = phase.image {
                                                    image
                                                        .resizable()
                                                        .scaledToFill()
                                                } else if phase.error != nil {
                                                    Color.red
                                                } else {
                                                    ProgressView()
                                                }
                                            }
                                            .frame(width: 100, height: 100)
                                            .clipped()
                                            .cornerRadius(10)
                                            .scaleEffect(isPressingImage && selectedImageURL == urlStr ? 1.05 : 1.0)
                                            .animation(.easeInOut(duration: 0.2), value: isPressingImage)
                                            .gesture(
                                                LongPressGesture(minimumDuration: 0.5)
                                                    .onEnded { _ in
                                                        withAnimation(.easeInOut(duration: 0.3)) {
                                                            selectedImageURL = urlStr
                                                            isPressingImage = true
                                                        }
                                                        titreşimVer()
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                            isPressingImage = false
                                                            selectedGorselURLToDelete = urlStr
                                                            gosterGorselSilOnayi = true
                                                        }
                                                    }
                                            )
                                        }
                                        if (seciliIslem?.gorselURLList?.count ?? 0) < 5 {
                                            Button {
                                                gosterSecimDialog = true
                                            } label: {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(Color.seaSalt)
                                                        .frame(width: 100, height: 100)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 10)
                                                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                                                .foregroundColor(.gray)
                                                        )
                                                    if gorselYukleniyor {
                                                        VStack(spacing: 6) {
                                                            ProgressView()
                                                                .progressViewStyle(CircularProgressViewStyle())
                                                            Text("Yükleniyor...")
                                                                .font(.caption2)
                                                                .foregroundColor(.gray)
                                                        }
                                                    } else {
                                                        Image(systemName: "plus")
                                                            .font(.title)
                                                            .foregroundColor(.gray)
                                                    }
                                                }
                                            }
                                            .disabled(gorselYukleniyor)
                                            .confirmationDialog("Fotoğraf Kaynağını Seç", isPresented: $gosterSecimDialog, titleVisibility: .visible) {
                                                Button("Kamera") {
                                                    secilenKaynak = "kamera"
                                                    gorselSec = true
                                                }
                                                Button("Galeriden Seç") {
                                                    secilenKaynak = "galeri"
                                                    showGaleridenPicker = true
                                                }
                                                Button("İptal", role: .cancel) { }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.bottom)
                            }
                            // MARK: - İşlem Notları ve Sil Butonu
                            HStack {
                                Text("İşlem Notları")
                                    .font(.subheadline)
                                Spacer()
                                Button(role: .destructive, action: {
                                    withAnimation {
                                        gosterSilOnay = true
                                    }
                                }) {
                                    Label("İşlemi Sil", systemImage: "trash")
                                        .font(.subheadline)
                                        .foregroundColor(.red)
                                        .padding(8)
                                        .background(Color.white.opacity(0.6))
                                        .cornerRadius(8)
                                }
                            }
                            TextEditor(text: $yeniNotEki)
                                .frame(height: 80)
                                .padding(10)
                                .background(Color.seaSalt)
                                .cornerRadius(10)
                                .scrollContentBackground(.hidden)
                            HStack {
                                Spacer()
                                Text("\(yeniNotEki.count)/200 karakter")
                                    .font(.caption2)
                                    .foregroundColor(yeniNotEki.count >= 200 ? .red : .gray)
                            }
                            Divider()
                            // MARK: - İşlem Tamamlandı Toggle ve Kaydet
                            HStack {
                                Toggle("İşlem Tamamlandı", isOn: Binding(
                                    get: { seciliIslem?.tamamlandi ?? false },
                                    set: { newValue in
                                        seciliIslem?.tamamlandi = newValue
                                    }
                                ))
                                .toggleStyle(CheckboxToggleStyle())
                                Spacer()
                                Button(action: {
                                    if seciliIslem?.tamamlandi == true {
                                        withAnimation { gosterUyari = true }
                                    } else {
                                        withAnimation { islemKaydet() }
                                    }
                                }) {
                                    Text("Kaydet")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                        .frame(height: 50)
                                        .frame(minWidth: 120)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                        )
                                }
                            }
                            .padding(.top, 5)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(.horizontal, 30)
                        .transition(.scale)
                    }
                }
            )
            // MARK: - Alert & Sheet
            .alert("İşlemi İptal Et", isPresented: $gosterSilOnay) {
                Button("İptal", role: .cancel) { }
                Button("İşlemi Sil", role: .destructive) {
                    withAnimation{
                        islemSil()
                    }
                }
            } message: {
                Text("İşlemi iptal etmek istediğinize emin misiniz?")
            }
            .alert("Bu işlem geri alınamaz", isPresented: $gosterUyari) {
                Button("İptal", role: .cancel) { }
                Button("Devam Et", role: .destructive) {
                    withAnimation{
                        islemKaydet()
                    }
                }
            } message: {
                Text("Tamamlandı olarak işaretlediğiniz işlemi geri alamazsınız. Devam etmek istiyor musunuz?")
            }
            .alert("Araç Bulunamadı", isPresented: $gosterAracBulunamadiAlert) {
                Button("Tekrar Dene", role: .cancel) {}
                Button("Araç Ekle") {
                    gosterAracEkleSayfasi = true
                }
            } message: {
                Text("Bu plakaya ait kayıt bulunamadı. Tekrar denemek ister misiniz?")
            }
            .alert("Bu görseli silmek istediğinize emin misiniz?", isPresented: $gosterGorselSilOnayi) {
                Button("Sil", role: .destructive) {
                    if let url = selectedGorselURLToDelete {
                        silGorsel(url)
                    }
                }
                Button("İptal", role: .cancel) {}
            }
            .sheet(isPresented: $gorselSec) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .photosPicker(
                isPresented: $showGaleridenPicker,
                selection: $selectedPhotos,
                maxSelectionCount: 1,
                matching: .images
            )
            .onChange(of: selectedPhotos) { newItems in
                guard let item = newItems.first else { return }
                selectedPhotos = []

                let toplamMevcut = (seciliIslem?.gorselURLList?.count ?? 0)
                guard toplamMevcut < 5 else {
                    gosterGorselLimitUyari = true
                    return
                }

                item.loadTransferable(type: Data.self) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let data):
                            guard let data = data else { return }
                            if data.count > 5 * 1024 * 1024 {
                                gosterGorselBuyukUyari = true
                                return
                            }
                            // Görseli hemen yükle ve Firestore'a ekle
                            gorselYukleniyor = true
                            guard let userId = Auth.auth().currentUser?.uid else {
                                gorselYukleniyor = false
                                return
                            }
                            let uuid = UUID().uuidString
                            let storage = Storage.storage()
                            let refStorage = storage.reference().child("kullaniciGorselleri/\(userId)/\(uuid).jpg")
                            refStorage.putData(data, metadata: nil) { metadata, error in
                                if let error = error {
                                    print("Yükleme hatası: \(error.localizedDescription)")
                                    gorselYukleniyor = false
                                    return
                                }
                                refStorage.downloadURL { url, error in
                                    if let url = url {
                                        let db = Firestore.firestore()
                                        db.collection("kullaniciAraclar").document(userId)
                                            .collection("araclar").document(seciliIslem?.plaka ?? "")
                                            .collection("islemler").document(seciliIslem?.id ?? "")
                                            .updateData([
                                                "gorselURLList": FieldValue.arrayUnion([url.absoluteString])
                                            ])
                                        if seciliIslem?.gorselURLList == nil {
                                            seciliIslem?.gorselURLList = []
                                        }
                                        seciliIslem?.gorselURLList?.append(url.absoluteString)
                                        gorselYukleniyor = false
                                    } else {
                                        gorselYukleniyor = false
                                    }
                                }
                            }
                        case .failure(let error):
                            print("Transfer hatası: \(error.localizedDescription)")
                            gorselYukleniyor = false
                        }
                    }
                }
            }
            .onChange(of: selectedImage) { newImage in
                guard let image = newImage,
                      let data = image.jpegData(compressionQuality: 0.8) else { return }

                selectedImage = nil

                let toplamMevcut = (seciliIslem?.gorselURLList?.count ?? 0)
                guard toplamMevcut < 5 else {
                    gosterGorselLimitUyari = true
                    return
                }

                if data.count > 5 * 1024 * 1024 {
                    gosterGorselBuyukUyari = true
                    return
                }

                gorselYukleniyor = true
                guard let userId = Auth.auth().currentUser?.uid else {
                    gorselYukleniyor = false
                    return
                }
                let uuid = UUID().uuidString
                let storage = Storage.storage()
                let refStorage = storage.reference().child("kullaniciGorselleri/\(userId)/\(uuid).jpg")
                refStorage.putData(data, metadata: nil) { metadata, error in
                    if let error = error {
                        print("Yükleme hatası: \(error.localizedDescription)")
                        gorselYukleniyor = false
                        return
                    }
                    refStorage.downloadURL { url, error in
                        if let url = url {
                            let db = Firestore.firestore()
                            db.collection("kullaniciAraclar").document(userId)
                                .collection("araclar").document(seciliIslem?.plaka ?? "")
                                .collection("islemler").document(seciliIslem?.id ?? "")
                                .updateData([
                                    "gorselURLList": FieldValue.arrayUnion([url.absoluteString])
                                ])
                            if seciliIslem?.gorselURLList == nil {
                                seciliIslem?.gorselURLList = []
                            }
                            seciliIslem?.gorselURLList?.append(url.absoluteString)
                            gorselYukleniyor = false
                        } else {
                            gorselYukleniyor = false
                        }
                    }
                }
            }
        }
        
        .sheet(isPresented: $gosterAracEkleSayfasi) {
            ekranAracEkle(showEklemeSayfasi: $gosterAracEkleSayfasi)
                .presentationDetents([.fraction(0.85)])
                .presentationCornerRadius(25)
                .presentationDragIndicator(.visible)
        }

    }
    
    // MARK: - Fonksiyonlar
    // MARK: - İşlem Silme
    func islemSil() {
        guard let islem = seciliIslem, let islemID = islem.id else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let ref = db.collection("kullaniciAraclar").document(userId).collection("araclar").document(islem.plaka).collection("islemler").document(islemID).delete { error in
            if let error = error {
                #if DEBUG
                print("İşlem silinirken hata oluştu: \(error.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                print("İşlem başarıyla silindi.")
                #endif
                withAnimation {
                    popupGoster = false
                    seciliIslem = nil
                    devamEdenIslemleriGetir()
                }
            }
        }
    }
    
    // MARK: - İşlem Kaydetme
    func islemKaydet() {
        guard let islem = seciliIslem, let islemID = islem.id else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let ref = db.collection("kullaniciAraclar").document(userId).collection("araclar").document(islem.plaka).collection("islemler").document(islemID)
        let guncelNot = yeniNotEki.trimmingCharacters(in: .whitespacesAndNewlines)
        let status = seciliIslem?.tamamlandi == true ? "Tamamlandı" : "Devam Ediyor"
        ref.updateData([
            "notlar": guncelNot,
            "status": status
        ]) { error in
            if let error = error {
                #if DEBUG
                print("Güncelleme hatası: \(error.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                print("İşlem başarıyla güncellendi.")
                #endif
                popupGoster = false
                seciliIslem = nil
                islemTamamlandi = false
                yeniNotEki = ""
                devamEdenIslemleriGetir()
            }
        }
    }
    
    // MARK: - Görsel Silme
    func silGorsel(_ url: String) {
        guard let islemID = seciliIslem?.id,
              let plaka = seciliIslem?.plaka,
              let userId = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let ref = db.collection("kullaniciAraclar")
            .document(userId)
            .collection("araclar")
            .document(plaka)
            .collection("islemler")
            .document(islemID)

        ref.updateData([
            "gorselURLList": FieldValue.arrayRemove([url])
        ]) { error in
            if let error = error {
                #if DEBUG
                print("Görsel silme hatası: \(error.localizedDescription)")
                #endif
            } else {
                #if DEBUG
                print("Görsel başarıyla silindi")
                #endif
                if var islem = seciliIslem,
                   let index = islem.gorselURLList?.firstIndex(of: url) {
                    // Remove from the selected popup state
                    islem.gorselURLList?.remove(at: index)
                    seciliIslem = islem

                    // Also update the main list so reopening uses updated data
                    if let listIndex = devamEdenIslemler.firstIndex(where: { $0.id == islem.id }) {
                        devamEdenIslemler[listIndex].gorselURLList = islem.gorselURLList
                    }
                }
            }
        }
    }
    
    // MARK: - Araç Getirme
    // Plakaya göre aracı getirir, detay ekranına yönlendirir.
    func araciGetir(plaka: String) {
        guard !plaka.trimmingCharacters(in: .whitespaces).isEmpty else {
            #if DEBUG
            print("Plaka boş. Arama yapılmadı.")
            #endif
            return
        }
        guard let userId = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("Kullanıcı oturumu yok.")
            #endif
            return
        }
        let db = Firestore.firestore()
        db.collection("kullaniciAraclar").document(userId).collection("araclar").document(plaka).getDocument { (document, error) in
            if let document = document, document.exists {
                do {
                    let arac = try document.data(as: Arac.self)
                    if let kayitDurum = (document.data()?["kayit_durum"] as? Int), kayitDurum == 0 {
                        #if DEBUG
                        print("Pasif araç, detay ekranına yönlendirilmedi.")
                        #endif
                        return
                    }
                    aracBilgisi = arac
                    navigateToDetail = true
                    plakaKaydet(plaka)
                } catch {
                    #if DEBUG
                    print("Veri işlenirken hata oluştu: \(error.localizedDescription)")
                    #endif
                }
            } else {
                #if DEBUG
                print("Araç Bulunamadı.")
                #endif
                gosterAracBulunamadiAlert = true
            }
        }
    }
    
    // MARK: - Plaka Kaydetme
    func plakaKaydet(_ plaka: String) {
        guard let marka = aracBilgisi?.marka else { return }

        let yeniKayit = SonBakilanArac(plaka: plaka, marka: marka)

        var mevcutlar: [SonBakilanArac] = []
        if let data = UserDefaults.standard.data(forKey: "sonBakilanAraclar"),
           let kayitli = try? JSONDecoder().decode([SonBakilanArac].self, from: data) {
            mevcutlar = kayitli
        }

        
        if mevcutlar.first?.plaka == plaka {
            return
        }

        mevcutlar.removeAll { $0.plaka == plaka }
        mevcutlar.insert(yeniKayit, at: 0)
        if mevcutlar.count > 5 {
            mevcutlar = Array(mevcutlar.prefix(5))
        }

        if let encoded = try? JSONEncoder().encode(mevcutlar) {
            UserDefaults.standard.set(encoded, forKey: "sonBakilanAraclar")
        }
        sonBakilanlar = mevcutlar
    }
    
    // MARK: - Devam Eden İşlemleri Getirme
    // Firestore'dan kullanıcıya ait araçları ve devam eden işlemleri getirir.
    func devamEdenIslemleriGetir() {
        guard let userId = Auth.auth().currentUser?.uid else {
            #if DEBUG
            print("Kullanıcı oturumu yok.")
            #endif
            return
        }

        let db = Firestore.firestore()

        db.collection("kullaniciAraclar").document(userId).collection("araclar").getDocuments { (snapshot, error) in
            if let error = error {
                #if DEBUG
                print("Araçlar çekilirken hata oluştu: \(error.localizedDescription)")
                #endif
                return
            }

            guard let documents = snapshot?.documents else { return }

            var yeniIslemler: [DevamEdenIslem] = []
            let group = DispatchGroup()

            for doc in documents {
                let plaka = doc.documentID
                let aracData = doc.data()

                guard let marka = aracData["marka"] as? String,
                      let model = aracData["model"] as? String,
                      let yil = aracData["yil"] as? String else {
                    continue
                }

                guard let kayitDurum = aracData["kayit_durum"] as? Int, kayitDurum == 1 else {
                    continue
                }

                let islemlerRef =
                db.collection("kullaniciAraclar").document(userId).collection("araclar").document(plaka).collection("islemler")

                group.enter()
                islemlerRef.whereField("status", isEqualTo: "Devam Ediyor")
                    .getDocuments { (islemSnapshot, error) in
                    defer { group.leave() }

                    if let error = error {
                        #if DEBUG
                        print("İşlem çekilirken hata: \(error.localizedDescription)")
                        #endif
                        return
                    }

                    guard let islemlerDocs = islemSnapshot?.documents else { return }

                    for islemDoc in islemlerDocs {
                        do {
                            let islem = try islemDoc.data(as: Islem.self)
                            let devamEden = DevamEdenIslem(
                                id: islem.id,
                                islemTuru: islem.islemTuru ?? "",
                                plaka: plaka,
                                marka: marka,
                                model: model,
                                yil: yil,
                                notlar: islem.notlar,
                                gorselURLList: islem.gorselURLList
                            )
                            yeniIslemler.append(devamEden)
                        } catch {
                            #if DEBUG
                            print("İşlem modeline dönüşüm hatası: \(error)")
                            #endif
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.devamEdenIslemler = yeniIslemler
            }
        }
    }

}
struct Arac: Codable, Identifiable {
    @DocumentID var id: String?
    var arac_sahip: String
    var arac_sahipTel: String
    var kayit_tarihi: Date
    var marka: String
    var model: String
    var motor: String
    var notlar: String
    var plaka: String
    var sasi_no: String
    var yakit: String
    var yil: String
    var kayit_durum: Int
}

struct DevamEdenIslem: Identifiable, Codable {
    var id: String?
    var islemTuru: String
    var plaka: String
    var marka: String
    var model: String
    var yil: String
    var notlar: String?
    var tamamlandi: Bool = false
    var gorselURLList: [String]?
}

struct SonBakilanArac: Identifiable, Codable {
    var id: String { plaka }
    var plaka: String
    var marka: String
}


#Preview ("Navbarsız"){
    ekranAna(popupGoster: .constant(false))
}

#Preview ("Navbarlı") {
    altTab()
}


