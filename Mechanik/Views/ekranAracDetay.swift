//
//  ekranAracDetay.swift
//  Mechanik
//
//  Created by efe arslan on 16.02.2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

// MARK: - View: EkranAracDetay Ana Görünüm
struct ekranAracDetay: View {
    let arac: Arac?
    var araciGetir: (String) -> Void
    
    @State private var secilenIslem: Islem? = nil
    @State private var yeniIslemPU = false
    @State private var gecmisIslemler: [Islem] = []
    @State private var duzenleSheet = false
    @State private var gosterSilmeOnayi = false
    @State private var isUploading: Bool = false

    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        
        ScrollView {
            headerButtonsView
            
            VStack {
                aracBilgiView
                digerBilgilerView
                gecmisIslemlerView
                yeniIslemButon
            }
            .padding()
            .sheet(item: $secilenIslem) { islem in
                islemDetayView(islem: islem)
                    .presentationDetents(UIScreen.main.bounds.height < 700 ? [.fraction(0.70)] : [.fraction(0.50)])
                    .presentationCornerRadius(45)
                    .presentationDragIndicator(.hidden)
            }
            .sheet(isPresented: $yeniIslemPU) {
                yeniIslemEkleView(aracPlaka: arac?.plaka ?? "", gecmisIslemGetir: gecmisIslemGetir, isUploading: $isUploading)
                    .safeAreaInset(edge: .bottom) { Spacer().frame(height: 10) }
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(25)
                    .interactiveDismissDisabled(isUploading)
            }
            .onAppear {
                gecmisIslemGetir()
            }
        }
        .navigationBarBackButtonHidden(true)
        .refreshable {
            gecmisIslemGetir()
            if let plaka = arac?.plaka {
                araciGetir(plaka)
            }
        }

    }
    
    // MARK: - Alt Görünümler
    private var headerButtonsView: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.black)
                    .padding()
            }

            Spacer()

            Menu {
                Button(action: {
                    duzenleSheet = true
                }) {
                    Label("Araç Düzenle", systemImage: "pencil")
                }

                Button(role: .destructive, action: {
                    gosterSilmeOnayi = true
                }) {
                    Label("Aracı Sil", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.black)
                    .padding()
            }
            .sheet(isPresented: $duzenleSheet) {
                if let arac = arac {
                    AracDuzenleView(arac: arac) { guncellenenArac in
                        aracGuncelle(guncellenenArac)
                        araciGetir(guncellenenArac.plaka)
                    }
                }
            }
            .alert("Bu aracı silmek istediğine emin misin?", isPresented: $gosterSilmeOnayi) {
                Button("Sil", role: .destructive) {
                    if let plaka = arac?.plaka {
                        araciSil(plaka: plaka)
                    }
                }
                Button("İptal", role: .cancel) {}
            }
        }
    }
    
    private var aracBilgiView: some View {
        Group {
            if let arac = arac {
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        InfoRow(title: "Marka", value: arac.marka)
                        InfoRow(title: "Model", value: arac.model)
                        InfoRow(title: "Yıl", value: arac.yil)
                        InfoRow(title: "Motor", value: "\(arac.motor) - \(arac.yakit)")
                        InfoRow(title: "Şasi No", value: arac.sasi_no)
                    }
                    .padding()
                    Spacer()
                    Image(arac.marka.lowercased() + "_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .aspectRatio(1, contentMode: .fit)
                        .padding()
                }
                .background(Color.seaSalt)
                .cornerRadius(10)
            } else {
                Text("Araç Bilgileri Yüklenemedi.")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.top, 10)
            }
        }
    }
    
    private var digerBilgilerView: some View {
        VStack {
            HStack {
                Text("Diğer Bilgiler ")
                    .font(.headline)
                    .foregroundColor(.myBlack)
                    .padding(.top, 20)
                Spacer()
            }
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text")
                            .resizable()
                            .frame(width: 15, height: 15)
                            .foregroundColor(.myRed)
                        Text("Araç Notları")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.myBlack)
                    }
                    Text(arac?.notlar == "-" ? "Not Bulunamadı." : (arac?.notlar ?? "-"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(width: 170, height: 100, alignment: .topLeading)
                .background(Color.seaSalt)
                .cornerRadius(15)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 15, height: 15)
                            .foregroundColor(.myRed)
                        Text("Araç Sahibi")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.myBlack)
                    }
                    Text("\(arac?.arac_sahip ?? "Bilinmiyor")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(arac?.arac_sahipTel ?? "-")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(width: 180, height: 100, alignment: .topLeading)
                .background(Color.seaSalt)
                .cornerRadius(15)
            }
        }

    }
    
    private var gecmisIslemlerView: some View {
        VStack {
            HStack {
                Text("Geçmiş İşlemler")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                NavigationLink(destination: ekranTumIslemler(aracPlaka: arac?.plaka ?? "", arac: arac!, isletmeAdi: "")) {
                    Text("Tümünü Gör")
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .padding()
                }
            }
            .padding(.bottom, -10)
            if !gecmisIslemler.isEmpty {
                ForEach(gecmisIslemler.prefix(3), id: \.id) { islem in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(islem.islemTuru)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.myBlack)
                            Text(islem.tarihString)
                                .font(.caption)
                                .foregroundColor(.myBlack)
                        }
                        Spacer()
                        Button(action: {
                            secilenIslem = islem
                        }) {
                            Image(systemName: "arrow.up.right")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 10, height: 10)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.myRed)
                                .contrast(1.2)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .padding()
                    .background(Color.seaSalt)
                    .cornerRadius(15)
                    
                }
            } else {
                Text("Geçmiş işlem bulunamadı.")
                    .font(.subheadline)
                    .foregroundColor(.black)
            }
        }
    }
    
    private var yeniIslemButon: some View {
        Button(action: {
            yeniIslemPU = true
        }) {
            Text("Yeni İşlem +")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.myBlack)
                .contrast(1.2)
                .cornerRadius(15)
        }
        .padding(.top, 10)
    }
    // MARK: - Firestore: Aracı Silme
    /// Belirtilen plakaya sahip aracı siler (kaydını pasif yapar).
    /// - Parameter plaka: Silinecek aracın plakası.
    func araciSil(plaka: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("kullaniciAraclar").document(userId).collection("araclar").document(plaka).updateData([
            "kayit_durum": 0,
            "silinme_tarihi": Date()
        ]) { error in
            if let error = error {
#if DEBUG
                print("Silme hatası: \(error.localizedDescription)")
#endif
            } else {
#if DEBUG
                print("Araç başarıyla silindi)")
#endif
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    // MARK: - Firestore: Geçmiş İşlemleri Getir
    /// Seçilen aracın geçmiş işlemlerini Firestore'dan çeker ve günceller.
    func gecmisIslemGetir() {
        guard let aracPlaka = arac?.plaka else { return }
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("kullaniciAraclar").document(userId).collection("araclar").document(aracPlaka).collection("islemler")
            .order(by: "tarih", descending: true)
            .getDocuments { snapshot, err in
                if let error = err {
#if DEBUG
                    print("Hata: \(error.localizedDescription)")
#endif
                    return
                }
                if let documents = snapshot?.documents {
                    self.gecmisIslemler = documents.compactMap { doc in
                        try? doc.data(as: Islem.self)
                    }
                }
            }
    }
}
// MARK: - İşlemler
let hizliIslemler: [String: [String]] = [
    "Periyodik Bakım": ["Yağ", "Yağ Filtresi", "Hava Filtresi", "Polen Filtresi", "Yakıt Filtresi"],
    "Motor Mekanik": ["Triger Seti Değişimi", "V Kayışı Değişimi", "Devirdaim Pompası", "Enjektör İşlemi", "Turbo", "Motor Kulağı"],
    "Şanzıman ve Debriyaj": ["Debriyaj Seti Değişimi", "Şanzıman Yağı Değişimi", "Volan Değişimi"],
    "Alt Takım ve Süspansiyon": ["Amortisör", "Z-Rot", "Salıncak", "Rotil", "Rot Başı"],
    "Fren Bakım": ["Fren Balataları", "Fren Diski", "Fren Hidroliği Değişimi", "Fren Kaliperleri"],
    "Elektrik Sistemi": ["Akü", "Marş Motoru", "Şarj Dinamosu", "Buji Değişimi"],
    "Soğutma Sistemi": ["Radyatör Değişimi", "Termostat Değişimi", "Hortum Değişimi", "Antifriz Değişimi"],
    "Egzoz Sistemi": ["DPF Temizliği", "Katalizör Temizliği", "Oksijen Sensörü Değişimi","Manifold Contası", "Egzoz Susturucuları"]
]
    
// MARK: - yeni işlem ekleme view
struct yeniIslemEkleView: View {
    let aracPlaka: String
    var gecmisIslemGetir: () -> Void
    @Environment(\.presentationMode) var presentationMode

    @Binding var isUploading: Bool

    @State private var klavyeAcik: Bool = false
    
    // Form alanları
    @State private var tarih: String = ""
    @State private var kilometre: String = ""
    @State private var notlar: String = ""
    @State private var kullaniciNotlari: String = ""
    @State private var hazirNotlar: String = ""

    @State private var seciliIslem: String = "Periyodik Bakım"
    @State private var seciliStatus: String = "Devam Ediyor"
    @State private var parcaUcret: String = ""
    @State private var iscilikUcret: String = ""
    
    // Bakım ek alanları
    @State private var filtreler = BakimFiltreleri()
    @State private var parcalar: [Parca] = []
    @State private var yeniParcaAd = ""
    @State private var yeniParcaMarka = ""
    @State private var yeniParcaAdet = ""
    @State private var yeniParcaFiyat = ""
    @State private var parcaDetaylari: [String: (marka: String, adet: String, fiyat: String)] = [:]
    
    @State private var duzenleniyor: Bool = false
    @State private var kmHata: Bool = false
    @State private var gosterSecenekler = false
    @State private var gosterImagePicker = false
    // Çoklu görsel seçimi için
    @State private var secilenGorseller: [UIImage] = []
    @State private var secilenGorsel: UIImage? = nil
    @State private var pickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showKaynakSecimi = false
    @State private var gorselBoyutUyarisiGoster = false
    @State private var fazlaFotoUyarisiGoster = false


    // Seçenekler
    
    let status = ["Devam Ediyor", "Tamamlandı"]
    
    let islemTurleri = ["Periyodik Bakım", "Motor Mekanik", "Şanzıman ve Debriyaj", "Alt Takım ve Süspansiyon", "Fren Bakım", "Elektrik Sistemi", "Soğutma Sistemi", "Egzoz Sistemi"]
    
    init(aracPlaka: String, gecmisIslemGetir: @escaping () -> Void, isUploading: Binding<Bool>) {
        self.aracPlaka = aracPlaka
        self.gecmisIslemGetir = gecmisIslemGetir
        self._isUploading = isUploading
    }
    
    var body: some View {
        ZStack {
            if isUploading {
                ProgressView("Görseller yükleniyor, lütfen bekleyin...")
                    .padding()
                    .background(Color.seaSalt)
                    .cornerRadius(15)
                    .zIndex(1)
            }
            
            
        VStack(spacing: 5) {
            ScrollView{
                VStack(spacing: 15) {
                    Image("mechanic")
                        .resizable()
                        .frame(width: .infinity, height: 250)
                        .padding(.vertical)
                    
                    
                    HStack{
                        Text("İşlem Türü")
                            .padding(.horizontal)
                            .foregroundColor(.gray)
                        Spacer()
                        
                        Picker("", selection: $seciliIslem) {
                            ForEach(islemTurleri, id: \.self) { islem in
                                
                                Text(islem)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.leading, 60)
                        .padding(.vertical, 10)
                        .tint(.black)
                        
                    }
                    .background(Color.seaSalt)
                    .cornerRadius(15)
                    .padding(.horizontal)
                    
                    // Hızlı seçenekler diğer işlemler için (Periyodik Bakım hariç)
                    if let hizliSecenekler = hizliIslemler[seciliIslem] {
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack(spacing: 10) {
                                ForEach(hizliSecenekler, id: \.self) { secenek in
                                    hizliSecim(islemAdi: secenek, isSelected: Binding(
                                        get: { filtreler.secilenIslemler.contains(secenek) },
                                        set: { yeniDeger in
                                            if yeniDeger {
                                                filtreler.secilenIslemler.append(secenek)
                                            } else {
                                                filtreler.secilenIslemler.removeAll(where: { $0 == secenek })
                                            }
                                        }
                                    ))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .onChange(of: seciliIslem) { _ in
                            filtreler.secilenIslemler.removeAll()
                            parcaDetaylari.removeAll()
                        }
                    }
                    
                    
                    if !filtreler.secilenIslemler.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Parça Detaylarını Girin").bold()
                                .padding(.horizontal)
                            
                            ForEach(filtreler.secilenIslemler, id: \.self) { isim in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(isim).bold()
                                    
                                    TextField("Marka", text: Binding(
                                        get: { parcaDetaylari[isim]?.marka ?? "" },
                                        set: { parcaDetaylari[isim, default: ("", "", "")].marka = $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    
                                    HStack {
                                        TextField("Adet", text: Binding(
                                            get: { parcaDetaylari[isim]?.adet ?? "" },
                                            set: { parcaDetaylari[isim, default: ("", "", "")].adet = $0 }
                                        ))
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.roundedBorder)
                                        
                                        TextField("Fiyat", text: Binding(
                                            get: { parcaDetaylari[isim]?.fiyat ?? "" },
                                            set: { parcaDetaylari[isim, default: ("", "", "")].fiyat = $0 }
                                        ))
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color.seaSalt)
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    TextField("Kilometre", text: $kilometre)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.seaSalt)
                        .cornerRadius(15)
                        .padding(.horizontal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(kmHata ? Color.red : Color.clear, lineWidth: 2)
                                .padding(.horizontal)
                        )
                        .onChange(of: kilometre) {
                            if !kilometre.isEmpty {
                                kmHata = false
                                let raw = kilometre.replacingOccurrences(of: ".", with: "")
                                if let kmInt = Int(raw) {
                                    let formatter = NumberFormatter()
                                    formatter.numberStyle = .decimal
                                    formatter.groupingSeparator = "."
                                    if let formatted = formatter.string(from: NSNumber(value: kmInt)) {
                                        kilometre = formatted
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                    
                    
                    
                    TextField("İşçilik Ücreti ₺", text: $iscilikUcret)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.seaSalt)
                        .cornerRadius(15)
                        .padding(.horizontal)
                    
                    
                    ZStack(alignment: .topLeading) {
                        if kullaniciNotlari.isEmpty && !duzenleniyor {
                            Text("Not Ekle...")
                                .foregroundColor(Color.init(hex: "#bfbfc3"))
                                .padding(.horizontal, 35)
                                .padding(.vertical, 25)
                                .zIndex(1)
                        }
                        
                        TextEditor(text: $kullaniciNotlari)
                            .frame(height: 100)
                            .padding()
                            .scrollContentBackground(.hidden)
                            .background(Color.seaSalt)
                            .cornerRadius(15)
                            .padding(.horizontal)
                            .onTapGesture {
                                duzenleniyor = true
                            }
                            .onDisappear {
                                duzenleniyor = false
                            }
                            .onChange(of: notlar) {
                                if notlar.count > 200 {
                                    notlar = String(notlar.prefix(200))
                                }
                            }
                        
                    }
                    .padding(.top, 30)
                    
                    HStack {
                        Spacer()
                        Text("\(kullaniciNotlari.count)/200")
                            .font(.caption2)
                            .foregroundColor(notlar.count >= 200 ? .red : .gray)
                            .padding(.trailing, 25)
                    }
                    .padding(.bottom ,10)
                    
                    // GÖRSEL BOYUT UYARISI (Her zaman gösterilecek)
                    if gorselBoyutUyarisiGoster {
                        HStack {
                            Text("⚠️ Seçtiğiniz fotoğraf boyutu 2 MB'ı geçemez.")
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            Spacer()
                            Button(action: {
                                gorselBoyutUyarisiGoster = false
                            }) {
                                EmptyView()
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color.seaSalt.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    // FAZLA FOTOĞRAF UYARISI
                    if fazlaFotoUyarisiGoster {
                        HStack {
                            Text("⚠️ En fazla 5 fotoğraf eklenebilir.")
                                .foregroundColor(.red)
                                .font(.subheadline)
                                .padding(.horizontal)
                                .padding(.top, 8)
                            Spacer()
                            Button(action: {
                                fazlaFotoUyarisiGoster = false
                            }) {
                                EmptyView()
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color.seaSalt.opacity(0.5))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    // Çoklu fotoğraf gösterimi ve silme
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(secilenGorseller.enumerated()), id: \.offset) { index, image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 150, height: 150)
                                        .cornerRadius(10)
                                        .padding(.horizontal, 4)
                                    Button(action: {
                                        secilenGorseller.remove(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .padding(5)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .transition(.opacity)
            
            // Klavye açıksa "İlerle" butonunu gösterme
            if !klavyeAcik {
                Button(action: {
                    if kilometre.isEmpty {
                        withAnimation {
                            kmHata = true
                        }
                    } else {
                        withAnimation {
                            gosterSecenekler = true
                        }
                    }
                }) {
                    Text("İlerle")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.myBlack)
                        .cornerRadius(15)
                }
                .padding(.horizontal)
                .padding(.top)
            }
        }
        .disabled(isUploading)
    }
        
        .onTapGesture {
            klavyeyiGizle()
        }
        

        
        .confirmationDialog("İlerle", isPresented: $gosterSecenekler, titleVisibility: .visible) {
            Button("Kaydet") {
                // Görsel boyutu kontrolü olmadan direkt kaydet
                yeniIslemKaydet()
            }
            Button("Fotoğraf Ekle") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showKaynakSecimi = true
                }
            }
            Button("İptal", role: .cancel) {
                
            }
        }
        .confirmationDialog("Fotoğraf Kaynağını Seç", isPresented: $showKaynakSecimi, titleVisibility: .visible) {
            Button("Kamera") {
                pickerSource = .camera
                gosterImagePicker = true
            }

            Button("Galeriden Seç") {
                pickerSource = .photoLibrary
                gosterImagePicker = true
            }

            Button("İptal", role: .cancel) { }
        }
        .sheet(isPresented: $gosterImagePicker, onDismiss: {
            if let image = secilenGorsel, let imageData = image.jpegData(compressionQuality: 0.8) {
                if imageData.count > 5 * 1024 * 1024 {
                    withAnimation {
                        gorselBoyutUyarisiGoster = true
                    }
                } else if secilenGorseller.count >= 5 {
                    withAnimation {
                        fazlaFotoUyarisiGoster = true
                    }
                } else {
                    withAnimation {
                        secilenGorseller.append(image)
                        gorselBoyutUyarisiGoster = false
                        fazlaFotoUyarisiGoster = false
                    }
                }
                secilenGorsel = nil
            }
        }) {
            ImagePicker(selectedImage: $secilenGorsel, sourceType: pickerSource)
        }
    }
    
    // MARK: - Firestore: Görsel Yükleme
    /// Bir görseli Firebase Storage'a yükler ve indirme URL'sini döner.
    /// - Parameters:
    ///   - image: Yüklenecek UIImage nesnesi.
    ///   - completion: Yükleme tamamlandığında çağrılır, URL string döner.
    func gorselYukleVeURLAl(image: UIImage, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }
        // Maksimum görsel boyutu (5 MB)
        let maxImageSize = 5 * 1024 * 1024 // 5 MB sınırı
        // Boyut kontrolü
        if imageData.count > maxImageSize {
            gorselBoyutUyarisiGoster = true
            completion(nil)
            return
        }
        let storage = Storage.storage()
        let uuid = UUID().uuidString
        let ref = storage.reference().child("notGorselleri/\(uuid).jpg")
        ref.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
#if DEBUG
                print("Yükleme hatası: \(error.localizedDescription)")
#endif
                completion(nil)
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
#if DEBUG
                    print("URL alma hatası: \(error.localizedDescription)")
#endif
                    completion(nil)
                    return
                }
                completion(url?.absoluteString)
            }
        }
    }
    
    // MARK: - Yardımcı Fonksiyonlar
    // MARK: - Notları güncelleme fonksiyonu
    func updateNotlar() {
        var filtrelerList: [String] = []


        hazirNotlar = filtrelerList.joined(separator: ", ")

        if !hazirNotlar.isEmpty && !kullaniciNotlari.isEmpty {
            notlar = "\(hazirNotlar) - \(kullaniciNotlari)"
        } else if !hazirNotlar.isEmpty {
            notlar = hazirNotlar
        } else {
            notlar = kullaniciNotlari
        }
    }
    
    // MARK: - Firestore: Yeni İşlem Kaydet
    /// Yeni bir işlem kaydını Firestore'a ekler, görsel yüklemeleriyle birlikte.
    func yeniIslemKaydet() {
        updateNotlar()
        parcalar.removeAll()
        isUploading = true
        // 30 saniye sonra hala upload varsa timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if isUploading {
                isUploading = false
#if DEBUG
                print("Yükleme zaman aşımına uğradı.")
#endif
            }
        }
        for isim in filtreler.secilenIslemler {
            let detay = parcaDetaylari[isim] ?? ("", "", "")
            let marka = detay.marka.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : detay.marka
            let adet = Int(detay.adet.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let fiyat = Double(detay.fiyat.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0.0
            let parca = Parca(ad: isim, marka: marka, adet: adet, birimFiyat: fiyat)
            parcalar.append(parca)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMdd"
        let tarihStr = formatter.string(from: Date())
        let randomNum = Int.random(in: 1000...9999)
        let islemID = "\(tarihStr)-\(randomNum)"
        guard let userId = Auth.auth().currentUser?.uid else { isUploading = false; return }
        let islemlerRef = Firestore.firestore()
            .collection("kullaniciAraclar").document(userId)
            .collection("araclar").document(aracPlaka)
            .collection("islemler")
        let userDoc = Firestore.firestore().collection("kullanicilar").document(userId)
        userDoc.getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let isletmeAdi = data["isletmeAdi"] as? String,
                  let isletmeSahibi = data["adSoyad"] as? String else {
#if DEBUG
                print("İşletme adı alınamadı")
#endif
                isUploading = false
                return
            }
            // Çoklu görsel yükleme
            let dispatchGroup = DispatchGroup()
            var gorselURLList: [String] = []
            if secilenGorseller.isEmpty {
                // Görsel yoksa direkt kayıt
                FirestoreKaydet(gorselURLList: [])
                return
            }
            for (index, image) in secilenGorseller.enumerated() {
                dispatchGroup.enter()
#if DEBUG
                print("Yükleme başlıyor: Görsel \(index+1)")
#endif
                gorselYukleVeURLAl(image: image) { url in
                    if let url = url {
#if DEBUG
                        print("Yükleme tamamlandı: \(url)")
#endif
                        gorselURLList.append(url)
                    } else {
#if DEBUG
                        print("Yükleme HATASI: Görsel \(index+1)")
#endif
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
#if DEBUG
                print("Tüm yüklemeler bitti: \(gorselURLList.count) adet URL var")
#endif
                FirestoreKaydet(gorselURLList: gorselURLList)
            }
            // MARK: - Firestore: Yeni İşlem Kaydet
            func FirestoreKaydet(gorselURLList: [String]) {
                let yeniIslem: [String: Any] = [
                    "id": islemID,
                    "tarih": Timestamp(date: Date()),
                    "kilometre": kilometre,
                    "notlar": notlar,
                    "islemTuru": seciliIslem,
                    "status": seciliStatus,
                    "plaka": aracPlaka,
                    "parcaUcreti": parcalar.reduce(0) { $0 + ($1.birimFiyat * Double($1.adet)) },
                    "iscilikUcreti": Double(iscilikUcret) ?? 0,
                    "parcalar": parcalar.map { [
                        "id": $0.id,
                        "ad": $0.ad,
                        "marka": $0.marka,
                        "adet": $0.adet,
                        "birimFiyat": $0.birimFiyat
                    ] },
                    "gorselURLList": gorselURLList,
                    "isletmeAdi": isletmeAdi,
                    "isletmeSahibi": isletmeSahibi
                ]
                islemlerRef.document(islemID).setData(yeniIslem) { error in
                    isUploading = false
                    if let error = error {
#if DEBUG
                        print("Hata: \(error.localizedDescription)")
#endif
                    } else {
#if DEBUG
                        print("İşlem Başarıyla Eklendi")
#endif
                        presentationMode.wrappedValue.dismiss()
                        self.gecmisIslemGetir()
                    }
                }
            }
        }
    }
}
// MARK: - Bakım Filtreleri
struct BakimFiltreleri {
    var yagFiltresi: Bool = false
    var havaFiltresi: Bool = false
    var polenFiltresi: Bool = false
    var yakitFiltresi: Bool = false
    var secilenIslemler: [String] = []
}

// MARK: - Veri Yapıları
struct Islem: Identifiable, Codable {
    @DocumentID var id: String?
    let tarih: Timestamp
    let kilometre: String
    let notlar: String
    let islemTuru: String
    let plaka: String
    let isletmeAdi: String
    let isletmeSahibi: String?
    let status: String

    let parcaUcreti: Double
    let iscilikUcreti: Double

    let parcalar: [Parca]

    // Firestore'dan okunan gerçek alan
    let gorselURLList: [String]?

    // Eski view kodları için uyumluluk
    var _gorselURLList: [String]? {
        gorselURLList
    }

    var tarihString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: tarih.dateValue())
    }

    var toplamParcaUcreti: Double {
        parcalar.reduce(0) { $0 + (Double($1.adet) * $1.birimFiyat) }
    }

    var toplamTutar: Double {
        toplamParcaUcreti + iscilikUcreti
    }
}

struct Parca: Identifiable, Codable {
    var id = UUID().uuidString
    var ad: String
    var marka: String
    var adet: Int
    var birimFiyat: Double
}

// MARK: - İşlem Detay Görünümü
struct islemDetayView: View {
    let islem: Islem

    var body: some View {
        
        VStack(spacing: 8){
            Image("bakim")
                .resizable()
                .frame(width: 300, height: 250)
                .padding(.top,30)
            
            VStack(alignment: .leading, spacing: 5){
                HStack{
                    Text(islem.islemTuru)
                        .font(.title2)
                        .bold()
                    Spacer()
                    
                    Text(islem.status)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(islem.status == "Tamamlandı" ? Color.green.opacity(0.2): Color.orange.opacity(0.2))
                        .cornerRadius(10)
                }
                Text(islem.tarihString)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Divider()
                
                    HStack(spacing: 10) {
                        if islem.toplamParcaUcreti == 0 && islem.iscilikUcreti == 0{
                            detailItem(icon: "turkishlirasign", text: "Ücret Belirtilmedi.")
                        }
                        else{
                            detailItem(icon: "turkishlirasign", text: "P: \(islem.toplamParcaUcreti)\nİ: \(islem.iscilikUcreti)")
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        detailItem(icon: "gauge.with.dots.needle.33percent", text: "\(islem.kilometre) km")
                        detailItem(icon: "licenseplate", text: islem.plaka)
                    }
                    .fontWeight(.medium)
                    Divider()
                    
                    detailItem(icon: "list.clipboard", text: islem.notlar.isEmpty ? "Not Eklenmemiş" : islem.notlar)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 50)
            }
            .padding(.horizontal)
        }
    }
    
    
    @ViewBuilder
    private func detailItem(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            Text(text)
                .font(.callout)
                .foregroundColor(.black)
        }
    }
}
// MARK: - Araç Detay Düzenleme Görünümü
struct AracDuzenleView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var arac: Arac
    var kaydet: (Arac) -> Void
    @State private var duzenleniyor: Bool = false
    @State private var kaydedildi: Bool = false
    
    let yilAraligi = (1990...2025).reversed().map { String($0) }
    let yakitTipleri = ["Benzin", "Dizel", "LPG", "Elektrik", "Hibrit"]
    
    var body: some View {
        NavigationStack{
            VStack{
                VStack{
                    
                    VStack {
                        Image(arac.marka.lowercased() + "_logo")
                            .resizable()
                            .frame(width: 60, height: 60)
                            
                    }
                    .frame(width: 80, height: 80)
                    .background(Color.seaSalt)
                    .clipShape(Circle())

                    .padding(.horizontal, 20)
                    
                    Text("\(arac.marka) \(arac.model)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .padding(.vertical, 5)
                    
                    Text("\(arac.plaka)")
                        .font(.subheadline)
                        .fontWeight(.thin)
                    
                }
                
                Divider()
                    
                HStack{
                    Text("Araç Sahibi Adı")
                        .frame(width: 140, alignment: .leading)
                        .padding(.leading, 5)
                    
                    TextField("Araç Sahibi Adı", text: $arac.arac_sahip)
                        .autocapitalization(.words)
                }
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.vertical)
                GradientDivider()
                
                // Telefon Numarası
                HStack{
                    Text("Telefon Numarası")
                        .frame(width: 140, alignment: .leading)
                        .padding(.leading, 5)
                    
                    TextField("Telefon Numarası", text: $arac.arac_sahipTel)
                        .keyboardType(.phonePad)
                    
                        .onChange(of: arac.arac_sahipTel) {
                            let filtered = arac.arac_sahipTel.filter { $0.isNumber }
                            if filtered.count > 10 {
                                arac.arac_sahipTel = String(filtered.prefix(10))
                            } else {
                                arac.arac_sahipTel = filtered
                            }
                        }
                }
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.vertical)
                GradientDivider()

                HStack{
                    Text("Motor Hacmi")
                        .frame(width: 140, alignment: .leading)
                        .padding(.leading, 5)

                    TextField("Motor Hacmi", text: $arac.motor)
                        .keyboardType(.decimalPad)
                    
                        .onChange(of: arac.motor) {
                            arac.motor = arac.motor.replacingOccurrences(of: ",", with: ".")
                        }
                }
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.vertical)
                GradientDivider()
                
                HStack{
                    Text("Şasi No")
                        .frame(width: 140, alignment: .leading)
                        .padding(.leading, 5)

                    TextField("Şasi No", text: $arac.sasi_no)
                        .autocapitalization(.none)
                        .onChange(of: arac.sasi_no) {
                            if arac.sasi_no.count > 17 {
                                arac.sasi_no = String(arac.sasi_no.prefix(17))
                            }
                        }
                }
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.vertical)
                GradientDivider()

                HStack{
                        Text("Model Yılı")
                        .frame(width: 130, alignment: .leading)
                        .padding(.leading, 5)

                    Picker("", selection: $arac.yil) {
                            ForEach(yilAraligi, id: \.self) { yil in
                                
                                Text(yil)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .tint(.black)
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.vertical, 10)
                GradientDivider()

                HStack{
                        Text("Yakıt Tipi")
                        .frame(width: 130, alignment: .leading)
                        .padding(.leading, 5)
                    
                    Picker("", selection: $arac.yakit) {
                            ForEach(yakitTipleri, id: \.self) { yakit in
                                
                                Text(yakit)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .tint(.black)
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cornerRadius(15)
                .padding(.horizontal)
                .padding(.vertical, 10)
                GradientDivider()
                
                HStack(alignment: .top) {
                    Text("Notlar")
                        .frame(width: 130, alignment: .leading)
                        .padding(.leading, 5)
                        .padding(.top, 10) // Notlar label'ını TextEditor'la hizalamak için

                    TextEditor(text: $arac.notlar)
                        .frame(minHeight: 100, maxHeight: 100)
                        .padding(8)
                        .cornerRadius(10)
                        .scrollContentBackground(.hidden)
                        .padding(.vertical, -5)

                }
                .padding(.horizontal)
                .padding(.vertical, 10)

                Divider()
                
            }
            .navigationTitle("Araç Düzenle")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("İptal") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Kaydet") {
                            kaydet(arac)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            
            }
        .background(Color.seaSalt)
        .ignoresSafeArea()
        }
    }
// MARK: - Firestore: Araç Güncelleme
/// Belirtilen aracın verilerini Firestore'da günceller.
/// - Parameter guncellenenArac: Güncellenmiş araç nesnesi.
func aracGuncelle(_ guncellenenArac: Arac) {
    let db = Firestore.firestore()
    let aracPlaka = guncellenenArac.plaka
    let guncellenenVeri: [String: Any] = [
        "arac_sahip": guncellenenArac.arac_sahip,
        "arac_sahipTel": guncellenenArac.arac_sahipTel,
        "motor": guncellenenArac.motor,
        "sasi_no": guncellenenArac.sasi_no,
        "yakit": guncellenenArac.yakit,
        "notlar": guncellenenArac.notlar
    ]
    guard let userId = Auth.auth().currentUser?.uid else { return }
    db.collection("kullaniciAraclar").document(userId).collection("araclar").document(aracPlaka).updateData(guncellenenVeri) { error in
        if let error = error {
#if DEBUG
            print("Araç güncellenirken hata oluştu: \(error.localizedDescription)")
#endif
        } else {
#if DEBUG
            print("Araç başarıyla güncellendi.")
#endif
        }
    }
}

// MARK: - Preview
#Preview {
    ekranAracDetay(arac: Arac(
        arac_sahip: "Ali Ayşe",
        arac_sahipTel: "-",
        kayit_tarihi: Date(),
        marka: "Mercedes-Benz",
        model: "C Serisi",
        motor: "2.0",
        notlar: "-",
        plaka: "34KLM54",
        sasi_no: "1234567890abcdefg",
        yakit: "Benzin",
        yil: "2020",
        kayit_durum: 1
    ),
                   araciGetir: { _ in print("Arac getirildi") }
    )
    
//            AracDuzenleView(
//                arac: Arac(
//                    arac_sahip: "Ali Ayşe",
//                    arac_sahipTel: "5551234567",
//                    kayit_tarihi: "01.04.2025",
//                    marka: "Toyota",
//                    model: "Corolla",
//                    motor: "1.6",
//                    notlar: "Periyodik bakım yapıldı",
//                    plaka: "34XYZ99",
//                    sasi_no: "ABC1234567890",
//                    yakit: "Benzin",
//                    yil: "2022"
//                ),
//                kaydet: { _ in print("Kaydet tıklandı") }
//            )
    //    islemDetayView(islem:Islem(
    //        id: "12345",
    //        tarih: Timestamp(date: Date()),
    //        kilometre: "150.000",
    //        notlar: "Triger kayışı değiştirildi",
    //        islemTuru: "Mekanik",
    //        status: "Devam Ediyor"))
}

#Preview {
    ekranTumIslemler(
        aracPlaka: "34KLM54",
        arac: Arac(
            arac_sahip: "Ali Ayşe",
            arac_sahipTel: "555555555",
            kayit_tarihi: Date(),
            marka: "Mercedes-Benz",
            model: "C Serisi",
            motor: "2.0",
            notlar: "01.03.2025'e kadar servis bakımlı",
            plaka: "34KLM54",
            sasi_no: "1234567890abcdefg",
            yakit: "Benzin",
            yil: "2020",
            kayit_durum: 1
        ),
        isletmeAdi: "Test İşletme"
    )
}



// MARK: - Hızlı Seçim Bileşeni
struct hizliSecim: View {
    var islemAdi: String
    @Binding var isSelected: Bool

    var body: some View {
        Button(action: {
            isSelected.toggle()
        }) {
            Text(islemAdi)
                .font(.subheadline)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.myRed : Color.seaSalt)
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.myRed.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
    }
}
