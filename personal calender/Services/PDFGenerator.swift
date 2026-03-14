import Foundation
import UIKit
import CoreGraphics

class PDFGenerator {
    static let shared = PDFGenerator()
    
    // A4 boyutu: 595.2 x 841.8 punto
    private let pageWidth: CGFloat = 595.2
    private let pageHeight: CGFloat = 841.8
    private let margin: CGFloat = 40.0
    
    func generateTimelinePDF(child: ChildProfile, periods: [TimelinePeriod]) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "Personal Calendar App",
            kCGPDFContextAuthor: child.name,
            kCGPDFContextTitle: "\(child.name) - Zaman Tüneli"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(child.name)_Anilar.pdf")
        
        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                var currentY: CGFloat = margin
                
                // Kapak / Başlık Alanı
                currentY = drawTitle(title: "\(child.name)'nin Anı Kitabı", y: currentY, context: context.cgContext)
                currentY += 20
                
                // Anıları Çiz
                let allEntries = periods.flatMap { $0.entries }.sorted { $0.date < $1.date }
                
                if allEntries.isEmpty {
                    currentY = drawText("Henüz hiç anı kaydedilmemiş.", y: currentY, font: .systemFont(ofSize: 14))
                } else {
                    for entry in allEntries {
                        // Sayfa taşma kontrolü
                        if currentY > pageHeight - margin - 50 {
                            context.beginPage()
                            currentY = margin
                        }
                        
                        currentY = drawEntry(entry: entry, y: currentY, context: context.cgContext)
                        currentY += 20
                    }
                }
            }
            return url
        } catch {
            print("PDF oluşturulamadı: \(error)")
            return nil
        }
    }
    
    private func drawTitle(title: String, y: CGFloat, context: CGContext) -> CGFloat {
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedTitle = NSAttributedString(string: title, attributes: titleAttributes)
        let titleStringSize = attributedTitle.size()
        let titleStringRect = CGRect(x: margin, y: y, width: pageWidth - (margin * 2), height: titleStringSize.height)
        
        attributedTitle.draw(in: titleStringRect)
        return y + titleStringSize.height
    }
    
    private func drawText(_ text: String, y: CGFloat, font: UIFont, isBold: Bool = false) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: textAttributes)
        let textBoundingRect = attributedText.boundingRect(with: CGSize(width: pageWidth - (margin * 2), height: 1000), options: .usesLineFragmentOrigin, context: nil)
        
        attributedText.draw(in: CGRect(origin: CGPoint(x: margin, y: y), size: textBoundingRect.size))
        return y + textBoundingRect.height
    }
    
    private func drawEntry(entry: MemoryEntry, y: CGFloat, context: CGContext) -> CGFloat {
        var currentY = y
        
        // Tarih ve Başlık
        let dateString = entry.date.formatted(date: .abbreviated, time: .omitted)
        currentY = drawText("\(dateString) - \(entry.title)", y: currentY, font: .boldSystemFont(ofSize: 16))
        currentY += 5
        
        // Açıklama
        if !entry.description.isEmpty {
            currentY = drawText(entry.description, y: currentY, font: .systemFont(ofSize: 12))
            currentY += 10
        }
        
        // İlk Fotoğrafı Ekle (Sadece 1 tane örnek olarak basıyoruz)
        if let firstImagePath = entry.mediaPaths.first(where: { !$0.hasSuffix(".mp4") }),
           let imageData = StorageManager.shared.loadImage(fileName: firstImagePath),
           let uiImage = UIImage(data: imageData) {
            
            // Boyutlandırma (Genişliği sayfa sınırlarına uydur, oranı koru)
            let maxWidth = pageWidth - (margin * 2)
            let imageRatio = uiImage.size.height / uiImage.size.width
            let targetHeight = maxWidth * imageRatio
            let drawHeight = min(targetHeight, 200) // Çok uzun olmasın
            let drawWidth = drawHeight / imageRatio
            
            // Eğer resim sayfadan taşacaksa iptal et (veya yeni sayfaya geçilebilir, basit tutuyoruz)
            if currentY + drawHeight < pageHeight - margin {
                let imageRect = CGRect(x: margin, y: currentY, width: drawWidth, height: drawHeight)
                uiImage.draw(in: imageRect)
                currentY += drawHeight + 10
            }
        }
        
        // Ayraç
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margin, y: currentY))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
        context.strokePath()
        
        return currentY + 10
    }
}
