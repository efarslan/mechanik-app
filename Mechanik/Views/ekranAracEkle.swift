//
//  IslemEkle.swift
//  Mechanik
//
//  Created by efe arslan on 11.02.2025.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth


struct ekranAracEkle: View {
   @State private var mevcutAsama = 1
    @Binding var showEklemeSayfasi: Bool
    
    @State private var plaka = ""
    @State private var marka = ""
    @State private var model = ""
    @State private var yil = "2025"
    @State private var yakit = "Benzin"
    @State private var motor = ""
    @State private var sasiNo = ""
    @State private var aracSahip = ""
    @State private var aracSahipTel = ""
    @State private var notlar = ""
    @State private var mesaj = ""
    
    @State private var duzenleniyor: Bool = false
    @State private var kaydedildi: Bool = false
    
    @State private var markalar: [String] = []
    @State private var modeller: [String] = []
    
    @State private var motorHata: Bool = false
    @State private var isimHata: Bool = false
    
    
    let db = Firestore.firestore()
    let yakitTipleri: [String] = ["Benzin", "Dizel", "LPG", "Elektrik", "Hibrit"]
    let yilAraligi = (1990...2025).reversed().map { String($0) }
    
        var body: some View {
                VStack {
                    ScrollView {
                        switch mevcutAsama {
                        case 1:
                            VStack{
                                Image("aracKabul")
                                    .resizable()
                                    .frame(width: 400, height: 300)
                                HStack(spacing: 0) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color.blue)
                                            .frame(width: 40, height: 70)
                                        Text("TR")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                            .padding(.top, 40)
                                    }
                                    
                                    TextField("34 ABC 1234", text: $plaka)
                                        .padding(.horizontal)
                                        .font(.system(size: 45, weight: .bold))
                                    
                                        .background(Color.white)
                                        .autocapitalization(.allCharacters)
                                        .keyboardType(.asciiCapable)
                                        .font(.system(size: 50, weight: .bold))
                                    
                                        .multilineTextAlignment(.center)
                                        .onChange(of: plaka) {
                                            plaka = formatPlaka(plaka)
                                        }
                                }
                                .frame(maxWidth: .infinity)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.black, lineWidth: 3))
                                .padding(.horizontal)
                                
                                HStack(spacing: -25){
                                    Button(action: {
                                        withAnimation {
                                            showEklemeSayfasi = false
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "xmark")
                                            Spacer()
                                            Text("İptal")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.red)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.clear)
                                        .cornerRadius(15)
                                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.red, lineWidth: 1))
                                    }
                                    .padding(.horizontal)
                                    
                                    Button(action: {
                                        if !plaka.isEmpty {
                                            withAnimation {
                                                mevcutAsama = 2
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Text("İlerle")
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(hex: "#627b65"))
                                        .cornerRadius(15)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 20)
                                    .disabled(plaka.isEmpty)
                                }
                            }
                        case 2:
                            VStack(spacing: 20) {
                                Text("Araç Bilgileri")
                                    .font(.largeTitle)
                                    .bold(true)
                                    .foregroundColor(.black)
                                
                                HStack{
                                    Image("\(marka.lowercased())_logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 46, height: 40)
                                        .padding(.horizontal)
                                    
                                    Spacer()
                                    
                                    Picker("", selection: $marka) {
                                        ForEach(markalar, id: \.self) { marka in
                                            
                                            Text(marka)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(.leading, 60)
                                    .padding(.vertical, 10)
                                    .tint(.black)
                                    
                                    .onChange(of: marka) {
                                        modelleriGetir(marka: marka)
                                    }
                                    
                                }
                                .background(Color.seaSalt)
                                .cornerRadius(15)
                                .padding(.horizontal)
                                
                                
                                // Model Seçimi
                                HStack{
                                    Text("Araç Modeli")
                                        .padding(.horizontal)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    
                                    Picker("", selection: $model) {
                                        ForEach(modeller, id: \.self) { model in
                                            
                                            Text(model)
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
                                
                                // Yıl Seçimi (Picker)
                                HStack{
                                    Text("Model Yılı")
                                        .padding(.horizontal)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    
                                    Picker("", selection: $yil) {
                                        ForEach(yilAraligi, id: \.self) { yil in
                                            
                                            Text(yil)
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
                                
                                
                                // Yakıt Tipi Seçimi
                                HStack{
                                    Text("Yakıt Tipi")
                                        .padding(.horizontal)
                                        .foregroundColor(.gray)
                                    Spacer()
                                    
                                    Picker("", selection: $yakit) {
                                        ForEach(yakitTipleri, id: \.self) { yakit in
                                            
                                            Text(yakit)
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
                                
                                
                                TextField("Motor Hacmi (1.0, 1.6, 2.0 vb.)", text: $motor)
                                    .keyboardType(.decimalPad)

                                    .padding()
                                    .background(Color.seaSalt)
                                    .cornerRadius(15)
                                    .padding(.horizontal)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                        .stroke(motorHata ? Color.red : Color.clear, lineWidth: 2)
                                        .padding(.horizontal)
                                    )
                                    .onChange(of: motor) {
                                        if motor.count > 3 {
                                            motor = String(motor.prefix(3))
                                        }
                                        
                                        if !motor.isEmpty {
                                            motorHata = false
                                            let raw = motor.replacingOccurrences(of: ",", with: "")
                                            if let motorInt = Int(raw) {
                                                let formatter = NumberFormatter()
                                                formatter.numberStyle = .decimal
                                                formatter.groupingSeparator = "."
                                                formatter.groupingSize = 1
                                                if let formatted = formatter.string(from: NSNumber(value: motorInt)) {
                                                    motor = formatted
                                                }
                                            }
                                        }
                                    }
                                
                                
                                // Şasi No (17 Karakter Sınırı)
                                TextField("Şasi No (Opsiyonel)", text: $sasiNo)
                                    .padding()
                                    .background(Color.seaSalt)
                                    .cornerRadius(15)
                                    .padding(.horizontal)
                                    .autocapitalization(.none)
                                    .onChange(of: sasiNo) {
                                        if sasiNo.count > 17 {
                                            sasiNo = String(sasiNo.prefix(17))
                                        }
                                    }
                                
                                HStack(spacing: -25){
                                    Button(action: {
                                        withAnimation {
                                            mevcutAsama = 1
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "chevron.left")
                                            Spacer()
                                            Text("Geri")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.clear)
                                        .cornerRadius(15)
                                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.black, lineWidth: 1))
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    
                                    Button(action: {
                                        if motor.isEmpty || motor.count < 3 {
                                            withAnimation {
                                                motorHata = true
                                            }
                                        } else {
                                            withAnimation {
                                                mevcutAsama = 3
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Text("İlerle")
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(hex: "#627b65"))
                                        .cornerRadius(15)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    
                                } //BUTONLAR
                                
                                .onAppear {
                                    markalariGetir()
                                }
                                
                            }
                            
                        case 3:
                            VStack(spacing: 20){
                                // Araç Sahibi Adı
                                TextField("Araç Sahibi Adı", text: $aracSahip)
                                    .padding()
                                    .background(Color.seaSalt)
                                    .cornerRadius(15)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(isimHata ? Color.red : Color.clear, lineWidth: 2)
                                    )
                                    .padding(.horizontal)
                                    .autocapitalization(.words)
                                    .onChange(of: aracSahip) {
                                        if !aracSahip.isEmpty {
                                            isimHata = false
                                        }
                                    }
                                
                                // Telefon Numarası
                                
                                TextField("Araç Sahibi Telefon Numarası", text: $aracSahipTel)
                                    .padding()
                                    .background(Color.seaSalt)
                                    .cornerRadius(15)
                                    .padding(.horizontal)
                                    .keyboardType(.phonePad)
                                
                                    .onChange(of: aracSahipTel) {
                                        let filtered = aracSahipTel.filter { $0.isNumber }
                                        if filtered.count > 10 {
                                            aracSahipTel = String(filtered.prefix(10))
                                        } else {
                                            aracSahipTel = filtered
                                        }
                                    }
                                
                                ZStack(alignment:.topLeading){
                                    if notlar.isEmpty && !duzenleniyor{
                                        Text("Not Ekle...")
                                            .foregroundColor(Color.init(hex: "#bfbfc3"))
                                            .padding(.horizontal, 35)
                                            .padding(.vertical, 25)
                                            .zIndex(1)
                                        
                                    }
                                    
                                    
                                    
                                    TextEditor(text: $notlar)
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
                                }
                                
                                HStack(spacing: -25){
                                    Button(action: {
                                        withAnimation {
                                            mevcutAsama = 2
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "chevron.left")
                                            Spacer()
                                            Text("Geri")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.black)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.clear)
                                        .cornerRadius(15)
                                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.black, lineWidth: 1))
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    
                                    Button(action: {
                                        if aracSahip.isEmpty {
                                            withAnimation {
                                                isimHata = true
                                            }
                                        } else {
                                            klavyeyiGizle()

                                            withAnimation {
                                                aracEkle()
                                            }
                                        }
                                    }) {
                                        HStack {
                                            Text("Aracı Kaydet")
                                            Spacer()
                                            Image(systemName: "checkmark.seal")
                                        }
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(hex: "#627b65"))
                                        .cornerRadius(15)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    
                                }
                                
                                if kaydedildi {
                                    VStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.green)
                                            .symbolEffect(.bounce.up.byLayer, options: .repeat(.periodic(delay: 2.0)))
                                        
                                        Text("Araç Başarıyla Kaydedildi!")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                        
                                    }
                                }
                                
                            }
                            
                            
                        default:
                            EmptyView()
                        }
                    }
                }
                .onTapGesture {
                    klavyeyiGizle()
                }
        }

    
    // MARK: - Yardımcı Fonksiyon: Plaka Formatlama
    func formatPlaka(_ input: String) -> String {
            let filteredValue = input.uppercased().filter { $0.isLetter || $0.isNumber }
            var formattedPlaka = ""

            let letters = CharacterSet.letters
            let digits = CharacterSet.decimalDigits

            var numberPart = ""
            var letterPart = ""
            var lastNumberPart = ""

            var mode = 0 // 0: İlk sayı, 1: Harf, 2: Son sayı

            for char in filteredValue {
                if mode == 0, char.unicodeScalars.allSatisfy(digits.contains) {
                    if numberPart.count < 2 {
                        numberPart.append(char)
                    }
                    if numberPart.count == 2 {
                        formattedPlaka.append(numberPart + " ") // İlk 2 rakamdan sonra boşluk ekle
                        mode = 1
                    }
                } else if mode == 1, char.unicodeScalars.allSatisfy(letters.contains) {
                    if letterPart.count < 3 { // Maksimum 3 harf sınırı
                        letterPart.append(char)
                    }
                    if letterPart.count >= 1 { // En az 1 harf girildiğinde devam etmesine izin ver
                        formattedPlaka = numberPart + " " + letterPart // Harfleri ekle
                    }
                    if letterPart.count == 3 {
                        formattedPlaka.append(" ") // 3 harften sonra boşluk ekle
                        mode = 2
                    }
                } else if mode == 1, char.unicodeScalars.allSatisfy(digits.contains) {
                    // Eğer kullanıcı tekrar rakam girerse otomatik boşluk koy
                    if !letterPart.isEmpty {
                        formattedPlaka.append(letterPart + " ")
                    }
                    lastNumberPart.append(char)
                    mode = 2
                } else if mode == 2, char.unicodeScalars.allSatisfy(digits.contains) {
                    if lastNumberPart.count < 4 { // Maksimum 4 rakam sınırı
                        lastNumberPart.append(char)
                    }
                }
            }

            formattedPlaka = "\(numberPart) \(letterPart) \(lastNumberPart)".trimmingCharacters(in: .whitespaces)

            return formattedPlaka
        }
    
    // MARK: - Firestore: Marka Listesi
    func markalariGetir() {
        db.collection("markalar").getDocuments { snapshot, error in
            if let error = error {
                #if DEBUG
                print("Marka listesi alınamadı. \(error.localizedDescription)")
                #endif
                return
            }
            
            markalar = snapshot?.documents.map { $0.documentID} ?? []
            if markalar.isEmpty {
                #if DEBUG
                print("⚠️ Firestore'dan hiç marka verisi alınamadı!")
                #endif
            } else {
                #if DEBUG
                print("✅ Firestore'dan \(markalar.count) marka alındı.")
                #endif
            }
            
            if let ilkMarka = markalar.first {
                marka = ilkMarka
                modelleriGetir(marka: ilkMarka)
            }
        }
    }

    // MARK: - Firestore: Model Listesi
    func modelleriGetir(marka: String) {
        db.collection("markalar").document(marka).collection("modeller").getDocuments { snapshot, error in
            if let error = error {
                #if DEBUG
                print("Model listesi alınamadı. \(error.localizedDescription)")
                #endif
                return
            }

            var gelenModeller = snapshot?.documents.map { $0.documentID } ?? []

            // Listeyi alfabetik olarak sıralıyoruz
            gelenModeller.sort()

            // Eğer "Diğer" varsa, çıkar ve en sona ekle
            if let index = gelenModeller.firstIndex(of: "Diğer") {
                gelenModeller.remove(at: index)
                gelenModeller.append("Diğer")
            }

            DispatchQueue.main.async {
                modeller = gelenModeller
                model = modeller.first ?? "Model"
            }
        }
    }

    // MARK: - Firestore: Araç Ekleme
    func aracEkle() {
        guard !plaka.isEmpty, !motor.isEmpty else {
            mesaj = "Lütfen zorunlu alanları doldurun!"
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            mesaj = "Kullanıcı oturumu bulunamadı!"
            return
        }

        let temizPlaka = plaka.replacingOccurrences(of: " ", with: "")

        let yeniArac: [String: Any] = [
            "plaka": temizPlaka,
            "marka": marka,
            "model": model,
            "yil": yil,
            "yakit": yakit,
            "motor": motor,
            "sasi_no": sasiNo.isEmpty ? "-" : sasiNo,
            "arac_sahip": aracSahip.isEmpty ? "-" : aracSahip,
            "arac_sahipTel": aracSahipTel.isEmpty ? "-" : aracSahipTel,
            "notlar": notlar.isEmpty ? "-" : notlar,
            "kayit_tarihi": Timestamp(),
            "kayit_durum": 1
        ]

        db.collection("kullaniciAraclar")
            .document(userId)
            .collection("araclar")
            .document(temizPlaka)
            .setData(yeniArac) { error in
                if let error = error {
                    #if DEBUG
                    print("Hata: \(error.localizedDescription)")
                    #endif
                    mesaj = "Hata: \(error.localizedDescription)"
                } else {
                    withAnimation {
                        kaydedildi = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            kaydedildi = false
                            showEklemeSayfasi = false
                        }
                    }
                }
            }
    }
}

#Preview {
    ekranAracEkle(showEklemeSayfasi: .constant(false))
}
