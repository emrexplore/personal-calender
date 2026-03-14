import SwiftUI

// Ana Sayfa Zaman Kartı Modüleri
struct TimelineCardView: View {
    let period: TimelinePeriod
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "tr")
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Sol taraftaki çizgi ve nokta efekti
            VStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 16, height: 16)
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(period.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    EmptyView()
                }
                
                Text("\(dateFormatter.string(from: period.startDate)) - \(dateFormatter.string(from: period.endDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "photo.fill.on.rectangle.fill")
                        .foregroundColor(.blue.opacity(0.8))
                    Text("\(period.entries.count) Anı")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // En son eklenen fotoğrafın önizlemesi
                    if let lastEntry = period.entries.last(where: { !$0.mediaPaths.isEmpty }),
                       let lastImagePath = lastEntry.mediaPaths.last,
                       let imageData = StorageManager.shared.loadImage(fileName: lastImagePath),
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .foregroundColor(.secondary)
                .padding(.top, 4)
            }
            .padding(18)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
