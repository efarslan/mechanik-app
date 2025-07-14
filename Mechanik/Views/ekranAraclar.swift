//
//  ekranAraclar.swift
//  Mechanik
//
//  Created by efe arslan on 11.02.2025.
//

// MARK: - View: ekranAraclar Ana Ekran

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ekranAraclar: View {
    @State private var araclar: [AracModel] = []
    @State private var isLoading = false
    @State private var lastDocument: DocumentSnapshot? = nil
    @State private var showEklemeSayfasi = false
    @State private var toplamKayitSayisi: Int = 0
    
    @State private var aramaMetni: String = ""
    @State private var filtrelenmisAraclar: [AracModel] = []
    @State private var aramaModu: Bool = false
    
    let pageSize = 5  // Sayfa başına kaç araç gösterileceğini belirler
    let db = Firestore.firestore()
    
    var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 15) {
                        HStack{
                            TextField("Plaka Ara", text: $aramaMetni)
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                            
                                .background(Color.seaSalt)
                                .cornerRadius(15)
                                .autocapitalization(.allCharacters)
                                .keyboardType(.asciiCapable)
                                .onChange(of: aramaMetni) { yeniMetin in
                                    var filtreli = yeniMetin.uppercased().filter { $0.isLetter || $0.isNumber }
                                    if filtreli.count > 9 {
                                        filtreli = String(filtreli.prefix(9))
                                    }
                                    aramaMetni = filtreli
                                    aramaModu = !aramaMetni.isEmpty

                                    if aramaModu {
                                        plakaIleArama(plaka: filtreli)
                                    } else {
                                        loadInitialData()
                                    }
                                }
                                .overlay(
                                    HStack {
                                        Spacer()
                                        if !aramaMetni.isEmpty {
                                            Button(action: {
                                                aramaMetni = ""
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.gray)
                                                    .padding(.trailing, 10)
                                            }
                                        }
                                    }
                                )
                            Spacer()
                            
                            Button(action: {
                                showEklemeSayfasi = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .resizable()
                                        .frame(width: 16, height: 16)
                                        .foregroundColor(.white)

                                    Text("Araç Ekle")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 8.6)
                                .padding(.horizontal, 10)
                                .background(Color.myBlack)
                                .cornerRadius(15)
                                
                            }
                        }
                        Divider()
                        
                        ForEach(aramaModu ? filtrelenmisAraclar : araclar) { arac in
                            NavigationLink(destination: ekranAracDetay(
                                arac: Arac(
                                    arac_sahip: arac.aracSahip,
                                    arac_sahipTel: arac.aracSahipTel,
                                    kayit_tarihi: Date(),
                                    marka: arac.marka,
                                    model: arac.model,
                                    motor: arac.motor,
                                    notlar: arac.notlar,
                                    plaka: arac.plaka,
                                    sasi_no: arac.sasi_no,
                                    yakit: arac.yakit,
                                    yil: arac.yil,
                                    kayit_durum: arac.kayit_durum
                                ),
                                araciGetir: { _ in }
                            )) {
                                aracKart(arac: arac)
                            }
                        }
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if lastDocument != nil && !aramaModu {
                            Button(action: {
                                loadMore()
                            }) {
                                Text("Daha Fazla Yükle")
                                    .font(.headline)
                                    .foregroundColor(Color.myRed)
                                    .padding()
                            }
                        }
                        
                        if toplamKayitSayisi > 0 && !aramaModu {
                            VStack(alignment: .leading, spacing: 5) {
                                ProgressView(value: Double(araclar.count), total: Double(toplamKayitSayisi))
                                    .accentColor(Color.myBlack)
                                    .frame(height: 6)

                                Text("\(araclar.count)/\(toplamKayitSayisi) araç gösteriliyor")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        } else if aramaModu {
                            Text("\(filtrelenmisAraclar.count) araç bulundu")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.bottom, 10)
                        }
                    }
                    .padding()
                }


                .onTapGesture {
                    klavyeyiGizle()
                }
            
                .onAppear {
                    loadInitialData()
                }
                .refreshable {loadInitialData()}
                
                .navigationDestination(isPresented: $showEklemeSayfasi) {
                    ekranAracEkle(showEklemeSayfasi: $showEklemeSayfasi)
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    
    // MARK: - View: Araç Kartı
    func aracKart(arac: AracModel) -> some View {
        HStack {
                Image("\(arac.marka.lowercased())_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .padding(.horizontal)
                    
            Divider()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(arac.plaka)
                    .font(.headline)
                    .bold()
                    .foregroundColor(Color(hex: "#1D2B47"))
                
                Text("\(arac.marka) \(arac.model) \(arac.motor) \(arac.yakit)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
//                Spacer()
                .padding()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius:15).fill(Color.seaSalt).shadow(color: .seaSalt ,radius: 3))
    }
    
    // MARK: - Firestore: Plakaya Göre Arama
    func plakaIleArama(plaka: String) {
        guard let userId = Auth.auth().currentUser?.uid
        else {return}
        
        db.collection("kullaniciAraclar").document(userId).collection("araclar")
            .whereField("kayit_durum", isEqualTo: 1)
            .order(by: "plaka")
            .start(at: [plaka])
            .end(at: [plaka + "\u{f8ff}"])
        
            .getDocuments { snapshot, error in
                if let error = error {
#if DEBUG
                    print("Plaka arama hatası: \(error.localizedDescription)")
#endif
                    return
                }
                guard let documents = snapshot?.documents else { return }

                self.filtrelenmisAraclar = documents.compactMap { doc in
                    try? doc.data(as: AracModel.self)
                }
            }
    }
    
    // MARK: - Firestore: Başlangıç Verisi Yükleme
    func loadInitialData() {
        guard let userId = Auth.auth().currentUser?.uid
        else {return}
        isLoading = true
        self.lastDocument = nil

        db.collection("kullaniciAraclar").document(userId).collection("araclar")
            .whereField("kayit_durum", isEqualTo: 1)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    self.toplamKayitSayisi = documents.count
                    if documents.count <= pageSize {
                        self.lastDocument = nil
                    }
                }
            }

        let kullaniciAraclarRef = db.collection("kullaniciAraclar").document(userId).collection("araclar")
        
        
        kullaniciAraclarRef
            .whereField("kayit_durum", isEqualTo: 1)
            .order(by: "kayit_tarihi", descending: true)
            .limit(to: pageSize)
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
#if DEBUG
                    print("Veri yükleme hatası: \(error.localizedDescription)")
#endif
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                self.araclar = documents.compactMap { doc -> AracModel? in
                    return try? doc.data(as: AracModel.self)
                }
                self.lastDocument = documents.last
                if documents.count < pageSize {
                    self.lastDocument = nil
                }
            }
    }
    
    // MARK: - Firestore: Sayfalama (Load More)
    func loadMore() {
        guard let userId = Auth.auth().currentUser?.uid
                else {return}
        
        guard let lastDoc = lastDocument else { return }
        isLoading = true
        
        db.collection("kullaniciAraclar").document(userId).collection("araclar")            .whereField("kayit_durum", isEqualTo: 1)
            .order(by: "kayit_tarihi", descending: true)
            .start(afterDocument: lastDoc)
            .limit(to: pageSize)
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
#if DEBUG
                    print("Daha fazla veri yükleme hatası: \(error.localizedDescription)")
#endif
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                let newAraclar = documents.compactMap { doc -> AracModel? in
                    return try? doc.data(as: AracModel.self)
                }
                
                withAnimation(.easeInOut(duration: 0.8)) {
                    self.araclar.append(contentsOf: newAraclar)
                }
                self.lastDocument = documents.last
                if documents.count < pageSize {
                    self.lastDocument = nil
                }
            }
    }
}

struct AracModel: Identifiable, Codable {
    @DocumentID var id: String?
    var plaka: String
    var marka: String
    var model: String
    var yil: String
    var aracSahip: String
    var aracSahipTel: String
    var motor: String
    var yakit: String
    var notlar: String
    var sasi_no: String
    var kayit_durum: Int
    var kayit_tarihi: Date
    var silinme_tarihi: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case plaka
        case marka
        case model
        case yil
        case aracSahip = "arac_sahip"
        case aracSahipTel = "arac_sahipTel"
        case motor
        case yakit
        case sasi_no
        case notlar
        case kayit_durum
        case kayit_tarihi
        case silinme_tarihi
    }
}

#Preview {
    ekranAraclar()
}
