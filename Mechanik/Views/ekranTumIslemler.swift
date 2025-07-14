// MARK: - View: Tüm İşlemler Ekranı
//
//  ekranTumIslemler.swift
//  Mechanik
//
//  Created by efe arslan on 4.03.2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth


struct ekranTumIslemler: View {
    let aracPlaka: String
    let arac: Arac
    let isletmeAdi: String
    
    @State private var islemler: [Islem] = []
    @State private var secilenIslem: Islem? = nil
    
    @State private var isFiltreSheetPresented: Bool = false
    @State private var secilenIslemTuru: String? = "Tümü"
    @State private var baslangicTarihi: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var bitisTarihi: Date = Date()
    @State private var filtrelenmisIslem:[Islem] = []
        
    @Environment(\.presentationMode) var presentationMode
    
    let islemTurleri = ["Tümü", "Periyodik Bakım", "Motor Mekanik", "Şanzıman ve Debriyaj", "Alt Takım ve Süspansiyon", "Fren Bakım", "Elektrik Sistemi", "Soğutma Sistemi", "Egzoz Sistemi"]
    
    var body: some View {
        VStack{
            HStack{
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.myBlack)
                        .padding()
                }
                Text("Tüm İşlemler")
                    .font(.title2)
                    .foregroundColor(.myBlack)
                Spacer()
            }
            
            Divider()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(islemTurleri, id: \.self) { tur in
                        Button(action: {
                            secilenIslemTuru = tur
                            islemleriFiltrele()
                        }) {
                            HStack {
                                Image(ikonAdi(for: tur))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                
                                Text(tur)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(secilenIslemTuru == tur ? Color.myRed : Color.black.opacity(0.5), lineWidth: secilenIslemTuru == tur ? 2 : 1)
                                    .animation(.easeInOut(duration: 0.3), value: secilenIslemTuru)
                            )
                            .animation(.easeInOut(duration: 0.3), value: secilenIslemTuru)
                        }
                    }
                    Button(action: {
                        isFiltreSheetPresented.toggle()
                    }) {
                        HStack(spacing: 20) {
                            Image(systemName: "calendar")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .background(Color.white)


                            Text("Filtreler")
                                .font(.subheadline)
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(tarihFiltresiAktif ? Color.black : Color.black.opacity(0.5), lineWidth: tarihFiltresiAktif ? 1.5: 1)
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                
                .sheet(isPresented: $isFiltreSheetPresented) {
                    FiltreView(
                        secilenIslemTuru: $secilenIslemTuru,
                        baslangicTarihi: $baslangicTarihi,
                        bitisTarihi: $bitisTarihi,
                        isFiltreSheetPresented: $isFiltreSheetPresented,
                        islemTurleri: islemTurleri,
                        islemleriFiltrele: islemleriFiltrele
                    )
                    .presentationDetents([.fraction(0.30)])
                    .presentationCornerRadius(45)
                }
            }
            ScrollView{
                VStack(spacing: 20) {
                    if islemler.isEmpty {

                        Image("notFound")
                            .resizable()
                            .frame(width: 350, height: 350)
                            .padding(.top, 20)
                        
                        Text("Geçmiş İşlem Bulunamadı.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                        Spacer()
                    }
                    else if filtrelenmisIslem.isEmpty {
                        
                        Image("notFound")
                            .resizable()
                            .frame(width: 350, height: 350)
                        
                        Text("Uygun Sonuç Bulunamadı.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding()
                    }
                    else {
                        
                        ForEach(filtrelenmisIslem , id: \.id) { islem in
                            IslemCardView(islem: islem, arac: self.arac)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.white)
        
        .navigationBarBackButtonHidden(true)
        .onAppear {
            tumIslemleriGetir()
        }
    }
    
    // MARK: - Yardımcı Fonksiyon: İşlem Türü İkonu
    func ikonAdi(for tur: String) -> String {
        switch tur {
        case "Tümü":
            return "menu"
        case "Periyodik Bakım":
            return "oilChange"
        case "Motor Mekanik":
            return "engine"
        case "Alt Takım ve Süspansiyon":
            return "suspension"
        case "Fren Bakım":
            return "brake"
        case "Şanzıman ve Debriyaj":
            return "gearbox"
        case "Elektrik Sistemi":
            return "electric"
        case "Soğutma Sistemi":
            return "cooling"
        case "Egzoz Sistemi":
            return "exhaust"
        default:
            return "questionmark"
        }
    }
    
    
    // MARK: - Firestore: Tüm İşlemleri Getir
    func tumIslemleriGetir() {
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
                    self.islemler = documents.compactMap { doc in
                        let islem = try? doc.data(as: Islem.self)
                        return islem
                    }
                    self.filtrelenmisIslem = self.islemler
                }
            }
    }
    // MARK: - Filtreleme: İşlem Türü ve Tarih
    func islemleriFiltrele() {
        withAnimation(.easeInOut(duration: 0.3)) {
            filtrelenmisIslem = islemler.filter { islem in
                let islemTarihi = islem.tarih.dateValue()
                let tarihUygunMu = islemTarihi >= baslangicTarihi && islemTarihi <= bitisTarihi
                
                if let seciliTur = secilenIslemTuru, seciliTur != "Tümü" {
                    return islem.islemTuru == seciliTur && tarihUygunMu
                } else {
                    return tarihUygunMu
                }
            }
        }
    }
    // MARK: - Filtre Durumu Kontrolü
    var tarihFiltresiAktif: Bool {
        let varsayilanBaslangic = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let bugun = Date()
        
        return !Calendar.current.isDate(baslangicTarihi, inSameDayAs: varsayilanBaslangic) ||
        !Calendar.current.isDateInToday(bitisTarihi)
    }
}

// MARK: - View: İşlem Kartı
struct IslemCardView: View {
    @State private var genislet = false
    @State private var showFullScreenImage = false
    @State private var selectedImageURL = ""
    @State private var selectedImageIndex = 0
    
    let islem: Islem
    let arac: Arac
    
    var body: some View {
        VStack(spacing: 0) {
            
            ZStack(alignment: .bottom) {
                
                if let firstURL = islem._gorselURLList?.first, let url = URL(string: firstURL), !firstURL.isEmpty {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(height: genislet ? 200 : 300)
                    .clipped()
                    .cornerRadius(24)
                    .onTapGesture {
                        selectedImageURL = firstURL
                        selectedImageIndex = 0
                        showFullScreenImage = true
                    }
                } else {
                    
                    Image("placeholder")
                        .resizable()
                        .frame(height: genislet ? 200 : 300)
                        .clipped()
                        .cornerRadius(24)
                }
                
                HStack {
                    if !genislet {
                        VStack(alignment: .leading) {
                            Text(islem.islemTuru)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text(islem.tarihString)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        Spacer()
                    }
                    
                }
                .padding()

                HStack {
                    Spacer()
                    HStack {
                        Image(systemName: islem.status == "Tamamlandı" ? "checkmark.circle.fill" : "info.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.white)

                        Text(islem.status)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                .padding()
            }
            .padding(.bottom, 0)
            .padding([.leading, .trailing, .top], 10)

            if genislet {
                VStack(alignment: .leading, spacing: 10) {
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text(islem.islemTuru)
                                .font(.headline)
                                .foregroundColor(.black)
                            Text(islem.tarihString)
                                .font(.subheadline)
                                .foregroundColor(.black.opacity(0.8))
                        }
                        Spacer()
                        Button(action: {
                            pdfOlustur(islem: islem, arac: arac)
                        }) {
                            ZStack{
                                Image(systemName: "square.and.arrow.up")
                                    .resizable()
                                    .frame(width: 14, height: 20)
                                //                                    .padding(.horizontal)
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(Circle().stroke(Color.black, lineWidth: 0.5))
                            }
                            .padding(.bottom, 15)

                        }
                    }

                    HStack{
                        HStack {
                            VStack(alignment: .center) {
                                Text(islem.kilometre)
                                    .bold()
                                Text("Kilometre")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack(alignment: .center) {
                                Text(islem.toplamParcaUcreti == 0 ? "-" : "\(islem.toplamParcaUcreti, specifier: "%.2f")₺")
                                    .bold()
                                Text("Parça Ücreti")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack(alignment: .center) {
                                Text(islem.iscilikUcreti == 0 ? "-" : "\(islem.iscilikUcreti, specifier: "%.2f")₺")
                                    .bold()
                                Text("İşçilik Ücreti")
                                    .font(.caption)
                            }
                            
                        }

                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(islem.parcalar, id: \.id) { parca in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(parca.ad) - \(parca.marka)")
                                        .font(.caption)
                                        .bold()
                                    Text("\(parca.adet) adet - \(Int(parca.birimFiyat))₺")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding(8)
                                .background(Color.seaSalt)
                                .cornerRadius(24)
                            }
                        }
                        .padding(.vertical)
                    }
                    Text(islem.notlar.isEmpty ? "Not Eklenmemiş" : islem.notlar)

                    if let gorseller = islem._gorselURLList, !gorseller.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(gorseller.enumerated()), id: \.offset) { index, urlStr in
                                    if let url = URL(string: urlStr) {
                                        AsyncImage(url: url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                        } placeholder: {
                                            Color.gray.opacity(0.3)
                                        }
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(10)
                                        .onTapGesture {
                                            selectedImageURL = urlStr
                                            selectedImageIndex = index
                                            showFullScreenImage = true
                                        }
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
//                    Spacer(minLength: 20)
                }
                .padding()
            
                .transition(.move(edge: .bottom))
            }

            Button(action: {
                withAnimation(.easeIn(duration: 0.6)) { genislet.toggle() }
            }) {
                Image(systemName: "chevron.up")
                    .rotationEffect(.degrees(genislet ? 180 : 0))
                    .animation(.easeIn(duration: 0.6), value: genislet)
                    .foregroundColor(.black)
                    .padding()
                    .shadow(radius: 4)
            }
        }
        .animation(.easeIn(duration: 0.6), value: genislet)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)
        .fullScreenCover(isPresented: $showFullScreenImage) {
            FullScreenImageView(
                imageURLs: islem._gorselURLList ?? [],
                selectedIndex: selectedImageIndex,
                isPresented: $showFullScreenImage
            )
        }
    }
}

// MARK: - View: Tam Ekran Görsel
struct FullScreenImageView: View {
    let imageURLs: [String]
    @State var selectedIndex: Int
    @Binding var isPresented: Bool
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("\(selectedIndex + 1) / \(imageURLs.count)")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(20)
                }
                .padding()
                
                Spacer()
                
                TabView(selection: $selectedIndex) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, urlStr in
                        if let url = URL(string: urlStr) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(currentScale)
                                    .gesture(
                                        MagnificationGesture()
                                            .onChanged { value in
                                                currentScale = finalScale * value
                                            }
                                            .onEnded { value in
                                                finalScale = currentScale
                                                // Zoom limitlerini ayarla
                                                if finalScale < 1.0 {
                                                    finalScale = 1.0
                                                    currentScale = 1.0
                                                } else if finalScale > 3.0 {
                                                    finalScale = 3.0
                                                    currentScale = 3.0
                                                }
                                            }
                                    )
                                    .onTapGesture(count: 2) {
                                        // Çift dokunma ile zoom reset
                                        withAnimation(.spring()) {
                                            currentScale = 1.0
                                            finalScale = 1.0
                                        }
                                    }
                            } placeholder: {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(2)
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: selectedIndex) { _ in
                    // Sayfa değiştiğinde zoom'u sıfırla
                    withAnimation(.easeOut(duration: 0.3)) {
                        currentScale = 1.0
                        finalScale = 1.0
                    }
                }
                
                Spacer()
                
                // Sayfa göstergeleri
                if imageURLs.count > 1 {
                    HStack(spacing: 8) {
                        ForEach(0..<imageURLs.count, id: \.self) { index in
                            Circle()
                                .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}


// MARK: - View: Filtre Ekranı
struct FiltreView: View {
    @Binding var secilenIslemTuru: String?
    @Binding var baslangicTarihi: Date
    @Binding var bitisTarihi: Date
    @Binding var isFiltreSheetPresented: Bool
    let islemTurleri: [String]
    let islemleriFiltrele: () -> Void
    
    var body: some View {
        NavigationView{
            VStack{
                Text("Filtreler")
                    .font(.title)
                    .bold()
                    .padding(.top, 15)
                    .foregroundColor(.black)
                
                HStack{
                    Image(systemName: "hourglass.bottomhalf.filled")
                    Text("Başlangıç Tarihi")
                        .frame(width: 120, alignment: .trailing)
                    Rectangle()
                        .frame(width: 1, height: 30) // 🔥 İnce
                        .foregroundColor(.black)
                    
                    DatePicker("",selection: $baslangicTarihi, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: 110)
                }
                .padding(.horizontal, 35)
                
                HStack{
                    Image(systemName: "hourglass.tophalf.filled")
                    Text("Bitiş Tarihi")
                        .frame(width: 120, alignment: .trailing)
                    
                    Rectangle()
                        .frame(width: 1, height: 30)
                        .foregroundColor(.black)
                    
                    DatePicker("", selection: $bitisTarihi, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: 110)
                }
                .padding(.horizontal, 35)
                
                HStack{
                    Button("Uygula") {
                        isFiltreSheetPresented = false
                        islemleriFiltrele()
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.yellow)
                    .cornerRadius(20)
                    
                    Button("Sıfırla") {
                        secilenIslemTuru = "Tümü"
                        baslangicTarihi = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
                        bitisTarihi = Date()
                        islemleriFiltrele()
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.seaSalt)
                    .cornerRadius(20)
                    .shadow(radius: 1)
                }
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}


#Preview {
    ekranTumIslemler(
        aracPlaka: "34ABC123",
        arac: Arac(
            arac_sahip: "Ali Kabadayı",
            arac_sahipTel: "05321234567",
            kayit_tarihi: Date(),
            marka: "Mercedes",
            model: "C200",
            motor: "1.6",
            notlar: "Bakım geçmişi tam",
            plaka: "34KLM54",
            sasi_no: "WDD2040491A123456",
            yakit: "Benzin",
            yil: "2019",
            kayit_durum: 1
        ),
        isletmeAdi: "Örnek İşletme"
    )
}
