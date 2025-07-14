//
//  ekranAnımsatıcı.swift
//  Düzeltilmiş Versiyon
//

import SwiftUI
import FirebaseFirestore

// MARK: - View: Anımsatıcı Ana Ekranı
struct ekranAnımsatıcı: View {
    @State private var anımsatSheetAcik: Bool = false
    @State private var seciliTarih = Date()
    @State private var kayitliAnımsatmalar: [Anımsatma] = []
    @State private var tumunuGoruntule = false
    
    private let calendar = Calendar.current
    
    private var gunler: [Date] {
        let start = calendar.date(byAdding: .day, value: -3, to: Date())!
        let end = calendar.date(byAdding: .day, value: 15, to: Date())!
        return calendar.generateDates(
            inside: DateInterval(start: start, end: end),
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
    }
    
    var body: some View {
        NavigationStack{
            VStack {
                VStack { //Takvim ve Buton
                    HStack {
                        Text("Takvim")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            tumunuGoruntule = true
                        }) {
                            Text("Tümünü Görüntüle")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(gunler, id: \.self) { tarih in
                                VStack(spacing: 4) {
                                    Text(gunKisaltma(_date: tarih))
                                        .font(.caption)
                                        .foregroundColor(calendar.isDate(tarih, inSameDayAs: seciliTarih) ? .white : .gray)
                                    
                                    Text(tarih.formatted(.dateTime.day()))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                                .frame(width: 48, height: 68)
                                .background(
                                    calendar.isDate(tarih, inSameDayAs: seciliTarih) ?
                                    Color.myRed :
                                        (calendar.isDateInToday(tarih) ? Color.myBlack.opacity(0.2) : Color.gray.opacity(0.15))
                                )
                                .foregroundColor(calendar.isDate(tarih, inSameDayAs: seciliTarih) ? .white : .myBlack)
                                .cornerRadius(12)
                                .onTapGesture {
                                    seciliTarih = tarih
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 5)
                    }
                    
                    HStack {
                        Text(gunBilgisi(_tarih: seciliTarih))
                            .font(.headline)
                            .padding(.leading)
                        Spacer()
                        
                        Button(action: {
                            anımsatSheetAcik.toggle()
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.black)
                                .padding()
                        }
                    }
                }
                
                ScrollView {
                    // Binding ile doğru güncelleme
                    ForEach(kayitliAnımsatmalar.indices, id: \.self) { index in
                        if calendar.isDate(kayitliAnımsatmalar[index].tarih, inSameDayAs: seciliTarih) {
                            IsimKartView(
                                animsatma: $kayitliAnımsatmalar[index],
                                onUpdate: {
                                    // Değişiklik olduğunda UserDefaults'u güncelle
                                    kaydetAnımsatmalar()
                                },
                                onDelete: {
                                    // Silme işlemi
                                    kayitliAnımsatmalar.remove(at: index)
                                    kaydetAnımsatmalar()
                                }
                            )
                        }
                    }
                    
                    // Boş durum kontrolü
                    if !kayitliAnımsatmalar.contains(where: { calendar.isDate($0.tarih, inSameDayAs: seciliTarih) }) {
                        VStack(spacing: 10) {
                            Image(systemName: "bell.slash")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray.opacity(0.5))
                            Text("Bu gün için kayıtlı anımsatıcı bulunmamaktadır.")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                                .padding(.top, 4)
                        }
                        .padding(.top, 40)
                    }
                }
            }
            .padding(.top, 30)
        }
        .navigationDestination(isPresented: $tumunuGoruntule) {
            TumAnimsaticilarView(
                animsaticilar: $kayitliAnımsatmalar,
                onUpdate: {
                    kaydetAnımsatmalar()
                }
            )
        }
        
        .onAppear {
            yukleAnımsatmalar()
        }
        .sheet(isPresented: $anımsatSheetAcik, onDismiss: {
            yukleAnımsatmalar()
        }) {
            yeniAnımsatmaView(seciliTarih: seciliTarih) {
                yukleAnımsatmalar()
            }
            .presentationDetents([.large])
            .presentationCornerRadius(25)
            .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: - Helper Functions
    
    /// UserDefaults'tan anımsatmaları yükler ve 3 günden eski olanları temizler
    private func yukleAnımsatmalar() {
        if let data = UserDefaults.standard.data(forKey: "tumAnımsatmalar"),
           let decoded = try? JSONDecoder().decode([Anımsatma].self, from: data) {
            kayitliAnımsatmalar = decoded
            
            // Eski kayıtları temizle (3 günden eski)
            let enGecTarih = calendar.date(byAdding: .day, value: -3, to: Date())!
            let oncekiSayisi = kayitliAnımsatmalar.count
            kayitliAnımsatmalar.removeAll(where: { $0.tarih < enGecTarih })
            
            // Eğer temizleme yapıldıysa UserDefaults'u güncelle
            if kayitliAnımsatmalar.count != oncekiSayisi {
                kaydetAnımsatmalar()
            }
        } else {
            kayitliAnımsatmalar = []
        }
    }
    /// Anımsatmaları UserDefaults'a kaydeder
    private func kaydetAnımsatmalar() {
        do {
            let data = try JSONEncoder().encode(kayitliAnımsatmalar)
            UserDefaults.standard.set(data, forKey: "tumAnımsatmalar")
            #if DEBUG
            print("✅ Anımsatmalar kaydedildi: \(kayitliAnımsatmalar.count) adet")
            #endif
        } catch {
            #if DEBUG
            print("❌ Anımsatma kaydetme hatası: \(error)")
            #endif
        }
    }
    
    private func gunBilgisi(_tarih: Date) -> String {
        if calendar.isDateInToday(_tarih) {
            return "Bugün"
        } else if calendar.isDateInTomorrow(_tarih) {
            return "Yarın"
        } else if calendar.isDateInYesterday(_tarih) {
            return "Dün"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "tr_TR")
            formatter.dateFormat = "d MMMM"
            return formatter.string(from: _tarih)
        }
    }
    
    private func gunKisaltma(_date : Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "E"
        return formatter.string(from: _date).capitalized
    }
}

// MARK: - View: Yeni Anımsatma Oluştur
struct yeniAnımsatmaView: View {
    @Environment(\.dismiss) var dismiss
    
    let oncekiSeciliTarih: Date
    let onSave: () -> Void
    
    @State private var seciliGun: Date
    @State private var seciliSaat = Date()
    @State private var isim: String = ""
    @State private var saatSecimiAcik = false
    @State private var isimBosUyarisi: Bool = false
    @State private var gecmisTarihUyarisi: Bool = false
    
    // Calendar instance
    private let calendar = Calendar.current

    init(seciliTarih: Date, onSave: @escaping () -> Void) {
        self.oncekiSeciliTarih = seciliTarih
        self.onSave = onSave
        // State'i başlat
        self._seciliGun = State(initialValue: seciliTarih)
    }

    var body: some View {
        ScrollView{
            VStack(spacing: 20){
                TextField("Randevu Alan (kişinin adı)", text: $isim)
                    .padding()
                    .background(Color.seaSalt)
                    .cornerRadius(15)
                    .autocapitalization(.allCharacters)
                    .keyboardType(.asciiCapable)
                    .padding(.horizontal)
                    .padding(.top, 40)
                    .onChange(of: isim) {
                        if isim.count > 20 {
                            isim = String(isim.prefix(20))
                        }
                    }

                DatePicker("Tarih",
                          selection: $seciliGun,
                          in: Date()..., // Bugünden itibaren
                          displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .padding()

                Toggle("Saat", isOn: $saatSecimiAcik)
                    .padding(.horizontal)

                if saatSecimiAcik {
                    DatePicker("Saat", selection: $seciliSaat, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Divider()

                Button(action: kaydetAnımsatma) {
                    Text("Kaydet")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.myBlack)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }
            .animation(.easeInOut, value: saatSecimiAcik)
        }
        .alert("İsim boş bırakılamaz.", isPresented: $isimBosUyarisi) {
            Button("Tamam", role: .cancel) { }
        }
        .alert("Geçmiş tarihe anımsatıcı eklenemez.", isPresented: $gecmisTarihUyarisi) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text("Lütfen bugün veya gelecek bir tarih seçin.")
        }
    }
    
    /// Yeni bir anımsatmayı kontrol ederek kaydeder
    private func kaydetAnımsatma() {
        let temizIsim = isim.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !temizIsim.isEmpty else {
            isimBosUyarisi = true
            return
        }
        
        // Tarihi doğru şekilde oluştur - Local timezone'da kalacak şekilde
        let finalTarih: Date
        if saatSecimiAcik {
            // Seçili günün başlangıcını al
            let gunBaslangici = calendar.startOfDay(for: seciliGun)
            
            // Saat bileşenlerini al
            let saatKomponentleri = calendar.dateComponents([.hour, .minute], from: seciliSaat)
            
            // Tarihi local timezone'da oluştur
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: gunBaslangici)
            dateComponents.hour = saatKomponentleri.hour ?? 0
            dateComponents.minute = saatKomponentleri.minute ?? 0
            dateComponents.second = 0
            dateComponents.timeZone = TimeZone.current // Local timezone kullan
            
            finalTarih = calendar.date(from: dateComponents) ?? seciliGun
        } else {
            // Saat seçimi yoksa günün başlangıcını al (local timezone'da)
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: seciliGun)
            dateComponents.hour = 0
            dateComponents.minute = 0
            dateComponents.second = 0
            dateComponents.timeZone = TimeZone.current
            
            finalTarih = calendar.date(from: dateComponents) ?? calendar.startOfDay(for: seciliGun)
        }
        
        // Geçmiş tarih kontrolü (ekstra güvenlik)
        let bugun = calendar.startOfDay(for: Date())
        let seciliGunBaslangici = calendar.startOfDay(for: finalTarih)
        
        if seciliGunBaslangici < bugun {
            gecmisTarihUyarisi = true
            return
        }
        
        // Eğer bugün seçilmişse ve saat seçimi varsa, geçmiş saati kontrol et
        if saatSecimiAcik && calendar.isDateInToday(finalTarih) {
            if finalTarih < Date() {
                gecmisTarihUyarisi = true
                return
            }
        }
        
        // Yeni anımsatma oluştur
        let anımsatma = Anımsatma(
            id: UUID(),
            isim: temizIsim,
            tarih: finalTarih,
            tamamlandi: false
        )
        
        // Debug için tarih bilgisini yazdır
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "dd/MM/yyyy HH:mm"
        formatter.timeZone = TimeZone.current
        #if DEBUG
        print("🕐 Kaydedilen tarih (local): \(formatter.string(from: finalTarih))")
        print("🌍 Kaydedilen tarih (UTC): \(finalTarih)")
        #endif
        
        // Mevcut listeyi al ve yeni anımsatmayı ekle
        var mevcutlar: [Anımsatma] = []
        if let data = UserDefaults.standard.data(forKey: "tumAnımsatmalar"),
           let decoded = try? JSONDecoder().decode([Anımsatma].self, from: data) {
            mevcutlar = decoded
        }
        
        mevcutlar.append(anımsatma)
        
        // Kaydet
        do {
            let data = try JSONEncoder().encode(mevcutlar)
            UserDefaults.standard.set(data, forKey: "tumAnımsatmalar")
            #if DEBUG
            print("✅ Yeni anımsatma kaydedildi: \(anımsatma.isim) - Local: \(formatter.string(from: anımsatma.tarih))")
            #endif
        } catch {
            #if DEBUG
            print("❌ Kaydetme hatası: \(error)")
            #endif
        }
        
        onSave()
        dismiss()
    }
}

// MARK: - View: Anımsatma Kartı
struct IsimKartView: View {
    @Binding var animsatma: Anımsatma
    let onUpdate: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "bell")
                .resizable()
                .frame(width: 25, height: 25)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(animsatma.isim)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Text(animsatma.tarih.hasTime()
                     ? animsatma.tarih.formatted(.dateTime.locale(Locale(identifier: "tr_TR")).day().month(.wide).hour().minute())
                     : animsatma.tarih.formatted(.dateTime.locale(Locale(identifier: "tr_TR")).day().month(.wide)))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut) {
                    animsatma.tamamlandi.toggle()
                    onUpdate()
                }
            }) {
                Image(systemName: animsatma.tamamlandi ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(animsatma.tamamlandi ? Color.green : .gray.opacity(0.4))
            }
        }
        .padding()
        .background(animsatma.tamamlandi ? Color.green.opacity(0.2) : Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - View: Tüm Anımsatıcılar
struct TumAnimsaticilarView: View {
    @Binding var animsaticilar: [Anımsatma]
    let onUpdate: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        let grouped = Dictionary(grouping: animsaticilar) {
            calendar.startOfDay(for: $0.tarih)
        }
        let sortedKeys = grouped.keys.sorted()

        List {
            ForEach(sortedKeys, id: \.self) { date in
                Section(header: Text(date.formatted(.dateTime.day().month().year().locale(Locale(identifier: "tr_TR"))))
                    .font(.headline)
                    .foregroundColor(.primary)) {

                    ForEach(grouped[date] ?? [], id: \.id) { animsat in
                        VStack(alignment: .leading) {
                            Text(animsat.isim)
                                .font(.headline)
                            Text(animsat.tarih.hasTime()
                                 ? animsat.tarih.formatted(.dateTime.locale(Locale(identifier: "tr_TR")).day().month(.wide).hour().minute())
                                 : animsat.tarih.formatted(.dateTime.locale(Locale(identifier: "tr_TR")).day().month(.wide)))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 6)
                    }
                    .onDelete { indexSet in
                        silAnımsaticilar(date: date, indices: indexSet)
                    }
                }
            }
        }
        .navigationTitle("Tüm Anımsatıcılar")
    }
    
    private func silAnımsaticilar(date: Date, indices: IndexSet) {
        let grouped = Dictionary(grouping: animsaticilar) {
            calendar.startOfDay(for: $0.tarih)
        }
        
        guard let gununkiler = grouped[date] else { return }
        
        for index in indices {
            if index < gununkiler.count {
                let silinecekItem = gununkiler[index]
                // Ana listeden sil
                animsaticilar.removeAll { $0.id == silinecekItem.id }
            }
        }
        
        onUpdate()
    }
}

// MARK: - Extensions (Değişmedi)

extension Calendar {
    func generateDates(
        inside interval: DateInterval,
        matching components: DateComponents
    ) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)

        enumerateDates(startingAfter: interval.start,
                       matching: components,
                       matchingPolicy: .nextTime) { date, _, stop in
            if let date = date, date < interval.end {
                dates.append(date)
            } else {
                stop = true
            }
        }

        return dates
    }
}

// MARK: - Model
struct Anımsatma: Codable, Identifiable {
    let id: UUID
    let isim: String
    let tarih: Date
    var tamamlandi: Bool
}

extension Date {
    func hasTime() -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: self)
        return (components.hour ?? 0) != 0 || (components.minute ?? 0) != 0
    }
}

#Preview {
    ekranAnımsatıcı()
}
