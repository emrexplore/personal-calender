import Foundation

struct TipData {
    /// Bebeğin yaşına (ay veya hafta olarak) göre gelişim ipuçları döndürür.
    static func getTipFor(weeks: Int? = nil, months: Int? = nil) -> String? {
        if let w = weeks {
            switch w {
            case 1...2: return "👶 Yenidoğan: Bebeğinizin midesi şu an bir kiraz büyüklüğünde. Sık sık ve azar azar beslenmek isteyecektir."
            case 3...4: return "👀 Gelişen Görüş: Bebeğiniz yavaş yavaş yüzünüze odaklanmaya başlayabilir."
            case 5...8: return "😊 İlk Gülücükler: Önümüzdeki haftalarda bebeğinizin size bilinçli gülümsediğini görebilirsiniz!"
            case 9...12: return "🎵 Sesler Çıkarmaya Başlama: 'Ağu', 'Gugu' gibi mırıldanmalara hazır olun."
            case 13...16: return "🤲 Ellerini Keşfetme: Bebeğiniz artık ellerine bakarak onları tanımaya çalışıyor olabilir."
            case 17...20: return "🙃 Dönme Çabaları: Artık karnından sırtına dönme egzersizleri başlayabilir."
            case 21...26: return "🍏 Ek Gıdaya Hazırlık: Doktorunuzun onayıyla tadım günleri çok yakında başlayabilir."
            case 27...32: return "🪑 Desteksiz Oturma: Bebeğiniz kaslarını güçlendirerek kendi başına oturmaya çalışabilir."
            case 33...40: return "🚼 Emekleme Vakti: Ellerini ve dizlerini kullanarak etrafı keşfetmeye hazırlanın!"
            case 41...52: return "👣 İlk Adımlar: Sıralamaya başlayabilir, ilk adımlarını atması bu dönemde gerçekleşebilir."
            default: return nil
            }
        }
        
        if let m = months {
            switch m {
            case 12...15: return "🎂 1 Yaş Sonrası: Bebekler bu aylarda tek tük kelimeler söylemeye başlayabilir."
            case 16...18: return "🧱 Taklit Oyunları: Etrafındaki yetişkinlerin davranışlarını oyun olarak taklit edebilir."
            case 19...24: return "🗣 Kelime Patlaması: Bu dönemde her gün yeni bir kelime öğrenebilir!"
            case 25...36: return "🎨 Yaratıcı Zeka: Basit yapbozlar oynamak veya kalemle karalama yapmak isteyebilir."
            default: return "🌟 Harika Bir Dönem: Çocuğunuz artık dünyayı kendi gözlerinden daha yetkin keşfediyor."
            }
        }
        
        return nil
    }
}
