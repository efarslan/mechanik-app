import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ekranSilinenAraclar: View {
    @State private var silinenAraclar: [AracModel] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var gosterUyari = false
    @State private var gosterSilmeOnayi = false
    @State private var seciliArac: AracModel? = nil
    
    let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack(alignment: .leading){
                    Text("Son Silinenler")
                        .font(.title)
                        .fontWeight(.bold)
                        .zIndex(1)
                        .padding(.leading, 25)
                        .padding(.bottom, 130)
                    
                    Text("Bir aracı son 60 gün içinde\nsildiysen geri alabilirsin.")
                        .font(.body)
                        .zIndex(1)
                        .padding(.leading, 25)
                    
                    Image("sonSilinenler")
                        .resizable()
                        .frame(width: .infinity, height: 280)
                        .ignoresSafeArea()
                }
                if silinenAraclar.isEmpty {
                    Text("Silinen Araç Bulunamadı.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        HStack {
                            Text("Araç")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Silinme Tarihi")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                        
                        ForEach(silinenAraclar) { arac in
                            aracKart(arac: arac)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        seciliArac = arac
                                        gosterSilmeOnayi = true
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        seciliArac = arac
                                        gosterUyari = true
                                    } label: {
                                        Label("Geri Yükle", systemImage: "arrow.uturn.backward")
                                    }
                                    .tint(.green)
                                }
                        }
                        .padding()
                    }
                    .listStyle(.plain)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            for arac in silinenAraclar {
                                geriYukle(arac: arac)
                            }
                        }) {
                            Text("Tümünü Geri Yükle")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
            }
            .navigationBarBackButtonHidden(true)
            
            .alert("Geri Yükle", isPresented: $gosterUyari) {
                Button("İptal", role: .cancel) { }
                Button("Devam Et", role: .destructive) {
                    if let arac = seciliArac {
                        withAnimation {
                            geriYukle(arac: arac)
                        }
                    }
                }
            } message: {
                Text("Seçtiğiniz aracı geri yüklemek istediğinize emin misiniz?")
            }
            .alert("Kalıcı Olarak Sil", isPresented: $gosterSilmeOnayi) {
                Button("İptal", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    if let arac = seciliArac {
                        kaliciSil(arac: arac)
                    }
                }
            } message: {
                Text("Bu araç tamamen silinecek. Devam etmek istiyor musunuz?")
            }
            .onAppear {
                yukleSilinenAraclar()
            }
            .refreshable {
                yukleSilinenAraclar()
            }
        }
    }
    
    // MARK: - Firestore: Araç Geri Yükleme
    func geriYukle(arac: AracModel) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("kullaniciAraclar").document(userId).collection("araclar").document(arac.plaka).updateData([
            "kayit_durum": 1,
            "silinme_tarihi": FieldValue.delete()
        ]) { error in
            if let error = error {
#if DEBUG
                print("Geri yükleme hatası: \(error.localizedDescription)")
#endif
            } else {
#if DEBUG
                print("Araç başarıyla geri yüklendi.")
#endif
                // Animasyonla listeden kaldır
                DispatchQueue.main.async {
                    withAnimation {
                        silinenAraclar.removeAll { $0.id == arac.id }
                    }
                }
            }
        }
    }
    // MARK: - Firestore: Kalıcı Silme
    func kaliciSil(arac: AracModel) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        db.collection("kullaniciAraclar").document(userId).collection("araclar").document(arac.plaka).delete { error in
            if let error = error {
#if DEBUG
                print("Kalıcı silme hatası: \(error.localizedDescription)")
#endif
            } else {
#if DEBUG
                print("Araç kalıcı olarak silindi.")
#endif
                DispatchQueue.main.async {
                    withAnimation {
                        silinenAraclar.removeAll { $0.id == arac.id }
                    }
                }
            }
        }
    }
    // MARK: - Firestore: Silinen Araçları Yükleme
    func yukleSilinenAraclar() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isLoading = true
        db.collection("kullaniciAraclar").document(userId).collection("araclar")
            .whereField("kayit_durum", isEqualTo: 0)
            .order(by: "kayit_tarihi", descending: true)
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
#if DEBUG
                    print("Hata: \(error.localizedDescription)")
#endif
                    return
                }
                
                silinenAraclar = (snapshot?.documents.compactMap { doc in
                    try? doc.data(as: AracModel.self)
                } ?? []).filter { arac in
                    guard let silinmeTarihi = arac.silinme_tarihi else { return true }
                    let calendar = Calendar.current
                    if let sonTarih = calendar.date(byAdding: .day, value: 60, to: silinmeTarihi) {
                        return sonTarih > Date()
                    }
                    return true
                }
            }
    }
    
    // MARK: - ViewBuilder: Araç Kartı
    func aracKart(arac: AracModel) -> some View {
        HStack{
            VStack(alignment: .leading, spacing: 8){
                Text(arac.plaka)
                    .font(.headline)
                Text("\(arac.marka) \(arac.model) - \(arac.yil)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 8){
                let silinme = arac.silinme_tarihi ?? Date()
                Text("\(formattedTarih(from: silinme)) \n  (\(gunSayisiKaldi(silinme)) gün)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        
    }
    
    // MARK: - Yardımcı Fonksiyon: Gün Sayısı Hesaplama
    func gunSayisiKaldi(_ silinmeTarihi: Date) -> Int {
        let calendar = Calendar.current
        let bitisTarihi = calendar.date(byAdding: .day, value: 60, to: silinmeTarihi) ?? silinmeTarihi
        let kalanGun = calendar.dateComponents([.day], from: Date(), to: bitisTarihi).day ?? 0
        return max(0, kalanGun)
    }
}

// MARK: - Yardımcı Fonksiyon: Tarih Formatlama
func formattedTarih(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy"
    return formatter.string(from: date)
}

#Preview("Silinen Araçlar") {
    ekranSilinenAraclar()
}
#Preview("Tüm Araçlar"){
    ekranAraclar()
}
