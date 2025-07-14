//
//  pdfOlustur.swift
//  Mechanik
//
//  Created by efe arslan on 10.05.2025.
//

import UIKit
import PDFKit
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }

            parent.presentationMode.wrappedValue.dismiss()
        }
    }

    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

func pdfOlustur(islem: Islem, arac: Arac) {
    let pdfMetaData = [
        kCGPDFContextCreator: "Mechänik",
        kCGPDFContextAuthor: "Mechänik App"
    ]
    
    let format = UIGraphicsPDFRendererFormat()
    format.documentInfo = pdfMetaData as [String : Any]
    
    let pageWidth = 595.0
    let pageHeight = 842.0
    let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

    let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

    let data = renderer.pdfData { context in
        // --- İLK SAYFA: İŞLEM BİLGİLERİ ---
        context.beginPage()

        // Logo (arka plan)
        if let logoImage = UIImage(named: "Mechanik") {
            let logoWidth: CGFloat = 580
            let logoHeight: CGFloat = 650
            let logoX = (pageWidth - logoWidth) / 2
            let logoY = (pageHeight - logoHeight) / 2
            let logoRect = CGRect(x: logoX, y: logoY, width: logoWidth, height: logoHeight)
            logoImage.draw(in: logoRect)
        }
        
        // Tarih
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        let formattedDate = formatter.string(from: currentDate)
        
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .paragraphStyle: NSMutableParagraphStyle(),
            .foregroundColor: UIColor.gray
        ]
        
        let dateString = formattedDate
        let textSize = dateString.size(withAttributes: dateAttributes)
        dateString.draw(at: CGPoint(x: pageWidth - 40 - textSize.width, y: 20), withAttributes: dateAttributes)
        
        // Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.black
        ]
        
        let headerText = "İŞLEM BİLGİLERİ"
        let headerSize = headerText.size(withAttributes: headerAttributes)
        headerText.draw(at: CGPoint(x: pageWidth - 40 - headerSize.width, y: 40), withAttributes: headerAttributes)
        
        // Sol başlık: İşlem Türü
        let solBaslikAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.black
        ]
        let solBaslik = islem.islemTuru.uppercased()
        solBaslik.draw(at: CGPoint(x: 40, y: 40), withAttributes: solBaslikAttributes)
        
        // Plaka
        let plakaAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        let plakaText = islem.plaka
        plakaText.draw(at: CGPoint(x: 40, y: 65), withAttributes: plakaAttributes)
        
        // Marka - Model
        let markaModelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        let markaModel = "\(arac.marka) \(arac.model)"
        markaModel.draw(at: CGPoint(x: 40, y: 90), withAttributes: markaModelAttributes)
        
        // Motor - Yakıt - Yıl
        let motorYakitYil = "\(arac.motor) \(arac.yakit) \(arac.yil)"
        motorYakitYil.draw(at: CGPoint(x: 40, y: 105), withAttributes: markaModelAttributes)
        
        // Sahip Bilgileri
        let sahipBaslikAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor.black
        ]
        let sahipDetayAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]

        var yAracSahibi: CGFloat = 140

        let baslikText = "ARAÇ SAHİBİ"
        baslikText.draw(at: CGPoint(x: 40, y: yAracSahibi), withAttributes: sahipBaslikAttributes)

        let sahipAd = arac.arac_sahip
        sahipAd.draw(at: CGPoint(x: 40, y: yAracSahibi + 20), withAttributes: sahipDetayAttributes)

        let sahipTel = arac.arac_sahipTel
        sahipTel.draw(at: CGPoint(x: 40, y: yAracSahibi + 34), withAttributes: sahipDetayAttributes)

        // Tablo
        let tabloBaslikFont = UIFont.boldSystemFont(ofSize: 12)
        let tabloFont = UIFont.systemFont(ofSize: 12)

        let tabloBasliklar = ["NO", "İŞLEM AÇIKLAMASI", "ÜCRET", "ADET", "TOPLAM"]
        let kolonGenislikleri: [CGFloat] = [30, 200, 70, 50, 70]
        let baslangicX: CGFloat = 40
        var y: CGFloat = 260

        var x = baslangicX
        for (index, baslik) in tabloBasliklar.enumerated() {
            let rect = CGRect(x: x, y: y, width: kolonGenislikleri[index], height: 20)
            baslik.draw(in: rect, withAttributes: [.font: tabloBaslikFont])
            x += kolonGenislikleri[index]
        }

        y += 25

        // Tablo Satırları
        for (index, parca) in islem.parcalar.enumerated() {
            x = baslangicX

            let no = "\(index + 1)"
            no.draw(in: CGRect(x: x, y: y, width: kolonGenislikleri[0], height: 20), withAttributes: [.font: tabloFont])
            x += kolonGenislikleri[0]

            let adVeMarka = "\(parca.ad)\n\(parca.marka)"
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 2
            let adMarkaAttr: [NSAttributedString.Key: Any] = [
                .font: tabloFont,
                .paragraphStyle: paragraphStyle
            ]
            adVeMarka.draw(in: CGRect(x: x, y: y, width: kolonGenislikleri[1], height: 34), withAttributes: adMarkaAttr)
            x += kolonGenislikleri[1]

            let fiyat = "\(Int(parca.birimFiyat)) ₺"
            fiyat.draw(in: CGRect(x: x, y: y, width: kolonGenislikleri[2], height: 20), withAttributes: [.font: tabloFont])
            x += kolonGenislikleri[2]

            let adet = "\(parca.adet)"
            adet.draw(in: CGRect(x: x, y: y, width: kolonGenislikleri[3], height: 20), withAttributes: [.font: tabloFont])
            x += kolonGenislikleri[3]

            let toplam = "\(Int(parca.birimFiyat * Double(parca.adet))) ₺"
            toplam.draw(in: CGRect(x: x, y: y, width: kolonGenislikleri[4], height: 20), withAttributes: [.font: tabloFont])

            y += 40
        }
        
        // Sağ Bilgiler
        let bilgiAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]

        let bilgiSatirlari = [
            "İşlem No: \(islem.id ?? "-")",
            "Tarih: \(islem.tarihString)",
            "Kilometre: \(islem.kilometre)"
        ]

        var bilgiYOffset: CGFloat = 65
        for satir in bilgiSatirlari {
            let satirSize = satir.size(withAttributes: bilgiAttributes)
            satir.draw(at: CGPoint(x: pageWidth - 40 - satirSize.width, y: bilgiYOffset), withAttributes: bilgiAttributes)
            bilgiYOffset += 14
        }

        // Toplam ve Notlar Alanı
        let cizgi1 = UIBezierPath()
        cizgi1.move(to: CGPoint(x: pageWidth / 2, y: y))
        cizgi1.addLine(to: CGPoint(x: pageWidth - 40, y: y))
        cizgi1.lineWidth = 1
        UIColor.black.setStroke()
        cizgi1.stroke()

        y += 10

        let toplamFont = UIFont.systemFont(ofSize: 13)
        let boldFont = UIFont.boldSystemFont(ofSize: 13)

        let parcaStr = "Parça Ücreti"
        let parcaDeger = "\(Int(islem.toplamParcaUcreti)) ₺"
        parcaStr.draw(at: CGPoint(x: pageWidth / 2 + 5, y: y), withAttributes: [.font: toplamFont])
        let parcaSize = parcaDeger.size(withAttributes: [.font: toplamFont])
        parcaDeger.draw(at: CGPoint(x: pageWidth - 40 - parcaSize.width, y: y), withAttributes: [.font: toplamFont])

        y += 20

        let iscilikStr = "İşçilik Ücreti"
        let iscilikDeger = islem.iscilikUcreti == 0 ? "-" : "\(Int(islem.iscilikUcreti)) ₺"
        iscilikStr.draw(at: CGPoint(x: pageWidth / 2 + 5, y: y), withAttributes: [.font: toplamFont])
        let iscilikSize = iscilikDeger.size(withAttributes: [.font: toplamFont])
        iscilikDeger.draw(at: CGPoint(x: pageWidth - 40 - iscilikSize.width, y: y), withAttributes: [.font: toplamFont])

        y += 25

        let cizgi2 = UIBezierPath()
        cizgi2.move(to: CGPoint(x: pageWidth / 2, y: y))
        cizgi2.addLine(to: CGPoint(x: pageWidth - 40, y: y))
        cizgi2.lineWidth = 1
        UIColor.black.setStroke()
        cizgi2.stroke()

        y += 10

        let toplamStr = "Toplam Ücret"
        let toplamDeger = "\(Int(islem.toplamTutar)) ₺"
        toplamStr.draw(at: CGPoint(x: pageWidth / 2 + 5, y: y), withAttributes: [.font: boldFont])
        let toplamSize = toplamDeger.size(withAttributes: [.font: boldFont])
        toplamDeger.draw(at: CGPoint(x: pageWidth - 40 - toplamSize.width, y: y), withAttributes: [.font: boldFont])

        // Notlar
        let notBaslik = "İşletme Notları"
        let notText = islem.notlar.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "-" : islem.notlar
        let notAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]
        let notIcerikAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]
        notBaslik.draw(at: CGPoint(x: 40, y: y), withAttributes: notAttrs)
        notText.draw(in: CGRect(x: 40, y: y + 20, width: pageWidth / 2 - 50, height: 100), withAttributes: notIcerikAttrs)

        // En alt bilgilendirme yazısı
        let footerText = "Bu belge Mechänik uygulaması üzerinden oluşturulmuştur.\nMali Değeri Yoktur."
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.gray,
            .paragraphStyle: {
                let style = NSMutableParagraphStyle()
                style.alignment = .left
                return style
            }()
        ]
        footerText.draw(in: CGRect(x: 40, y: pageHeight - 50, width: pageWidth - 80, height: 40), withAttributes: footerAttributes)

        // İşletme bilgileri
        let isletmeAdFont = UIFont.boldSystemFont(ofSize: 12)
        let isletmeSahibiFont = UIFont.systemFont(ofSize: 11)

        let isletmeAdi = islem.isletmeAdi
        let isletmeSahibi = islem.isletmeSahibi ?? "-"
        let adSize = isletmeAdi.size(withAttributes: [.font: isletmeAdFont])
        let sahibiSize = isletmeSahibi.size(withAttributes: [.font: isletmeSahibiFont])

        let adY = pageHeight - 50
        let sahibiY = adY + 16

        isletmeAdi.draw(at: CGPoint(x: pageWidth - 40 - adSize.width, y: adY), withAttributes: [.font: isletmeAdFont])
        isletmeSahibi.draw(at: CGPoint(x: pageWidth - 40 - sahibiSize.width, y: sahibiY), withAttributes: [.font: isletmeSahibiFont])

        // --- İKİNCİ SAYFA: GÖRSELLER (eğer varsa) ---
        if let gorselURLList = islem.gorselURLList, !gorselURLList.isEmpty {
            // URL'lerden UIImage'lara dönüştür
            var gorseller: [UIImage] = []
            for urlString in gorselURLList {
                if let url = URL(string: urlString),
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    gorseller.append(image)
                }
            }
            
            if !gorseller.isEmpty {
                context.beginPage()
                
                // İkinci sayfa başlığı
                let gorselBaslikAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.black
                ]
                
                let gorselBaslik = "İŞLEM GÖRSELLERİ"
                let gorselBaslikSize = gorselBaslik.size(withAttributes: gorselBaslikAttrs)
                gorselBaslik.draw(at: CGPoint(x: (pageWidth - gorselBaslikSize.width) / 2, y: 40), withAttributes: gorselBaslikAttrs)
                
                // İşlem bilgilerini tekrar yazdır (küçük)
                let kucukBilgiAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11),
                    .foregroundColor: UIColor.gray
                ]
                
                let islemBilgi = "\(islem.islemTuru.uppercased()) - \(islem.plaka) - \(islem.tarihString)"
                let islemBilgiSize = islemBilgi.size(withAttributes: kucukBilgiAttrs)
                islemBilgi.draw(at: CGPoint(x: (pageWidth - islemBilgiSize.width) / 2, y: 65), withAttributes: kucukBilgiAttrs)
                
                // Görselleri yerleştir
                let margin: CGFloat = 40
                let availableWidth = pageWidth - (2 * margin)
                let availableHeight = pageHeight - 120 - 40 // Başlık ve alt margin
                
                let gorselSayisi = min(gorseller.count, 5) // Maksimum 5 görsel
                
                // Görsel boyutlarını belirle
                var gorselWidth: CGFloat = 0
                var gorselHeight: CGFloat = 0
                var satirSayisi = 0
                var sutunSayisi = 0
                
                switch gorselSayisi {
                case 1:
                    // Tek görsel - büyük boyut
                    gorselWidth = min(availableWidth * 0.8, 400)
                    gorselHeight = min(availableHeight * 0.8, 300)
                    satirSayisi = 1
                    sutunSayisi = 1
                    
                case 2:
                    // İki görsel - yan yana
                    gorselWidth = (availableWidth - 20) / 2
                    gorselHeight = min(availableHeight * 0.6, 250)
                    satirSayisi = 1
                    sutunSayisi = 2
                    
                case 3:
                    // Üç görsel - üstte 2, altta 1
                    gorselWidth = (availableWidth - 20) / 2
                    gorselHeight = min((availableHeight - 20) / 2, 180)
                    satirSayisi = 2
                    sutunSayisi = 2
                    
                case 4:
                    // Dört görsel - 2x2
                    gorselWidth = (availableWidth - 20) / 2
                    gorselHeight = min((availableHeight - 20) / 2, 160)
                    satirSayisi = 2
                    sutunSayisi = 2
                    
                case 5:
                    // Beş görsel - üstte 2, ortada 2, altta 1
                    gorselWidth = (availableWidth - 20) / 2
                    gorselHeight = min((availableHeight - 40) / 3, 120)
                    satirSayisi = 3
                    sutunSayisi = 2
                    
                default:
                    break
                }
                
                var gorselIndex = 0
                let baslangicY: CGFloat = 100
                
                for satir in 0..<satirSayisi {
                    let satirY = baslangicY + CGFloat(satir) * (gorselHeight + 20)
                    
                    // Son satırda tek görsel varsa ortala
                    let buSatirdakiGorselSayisi: Int
                    if gorselSayisi == 3 && satir == 1 {
                        buSatirdakiGorselSayisi = 1
                    } else if gorselSayisi == 5 && satir == 2 {
                        buSatirdakiGorselSayisi = 1
                    } else {
                        buSatirdakiGorselSayisi = min(sutunSayisi, gorselSayisi - gorselIndex)
                    }
                    
                    let satirGenisligi = CGFloat(buSatirdakiGorselSayisi) * gorselWidth + CGFloat(max(0, buSatirdakiGorselSayisi - 1)) * 20
                    let satirBaslangicX = margin + (availableWidth - satirGenisligi) / 2
                    
                    for sutun in 0..<buSatirdakiGorselSayisi {
                        if gorselIndex >= gorseller.count { break }
                        
                        let gorselX = satirBaslangicX + CGFloat(sutun) * (gorselWidth + 20)
                        let gorselRect = CGRect(x: gorselX, y: satirY, width: gorselWidth, height: gorselHeight)
                        
                        // Görseli çiz
                        let gorsel = gorseller[gorselIndex]
                        // Görselin oranını koru
                        let gorselOrani = gorsel.size.width / gorsel.size.height
                        let hedefOran = gorselWidth / gorselHeight
                        
                        var cizimRect = gorselRect
                        
                        if gorselOrani > hedefOran {
                            // Görsel daha geniş - yüksekliği azalt
                            let yeniYukseklik = gorselWidth / gorselOrani
                            cizimRect = CGRect(x: gorselX,
                                             y: satirY + (gorselHeight - yeniYukseklik) / 2,
                                             width: gorselWidth,
                                             height: yeniYukseklik)
                        } else {
                            // Görsel daha uzun - genişliği azalt
                            let yeniGenislik = gorselHeight * gorselOrani
                            cizimRect = CGRect(x: gorselX + (gorselWidth - yeniGenislik) / 2,
                                             y: satirY,
                                             width: yeniGenislik,
                                             height: gorselHeight)
                        }
                        
                        gorsel.draw(in: cizimRect)
                        
                        // Görsel etrafına çerçeve çiz
                        let cerceve = UIBezierPath(rect: cizimRect)
                        cerceve.lineWidth = 1
                        UIColor.lightGray.setStroke()
                        cerceve.stroke()
                        
                        gorselIndex += 1
                    }
                    
                    if gorselIndex >= gorseller.count { break }
                }
                
                // İkinci sayfa footer
                footerText.draw(in: CGRect(x: 40, y: pageHeight - 50, width: pageWidth - 80, height: 40), withAttributes: footerAttributes)
            }
        }
    }
    
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("islemler.pdf")
    
    do {
        try data.write(to: tempURL)
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = scene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    } catch {
        print("PDF Kaydedilirken hata oluştu: \(error.localizedDescription)")
    }
}
