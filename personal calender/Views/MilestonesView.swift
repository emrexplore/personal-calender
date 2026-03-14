import SwiftUI

struct MilestonesView: View {
    @EnvironmentObject var timelineManager: TimelineManager
    @State private var selectedMilestone: MemoryEntry?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        let milestones = timelineManager.periods
                            .flatMap { $0.entries }
                            .filter { $0.isMilestone }
                            .sorted { $0.date > $1.date }
                    
                    if milestones.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "star.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)
                                .opacity(0.8)
                            
                            Text("Henüz bir 'İlklerim' anısı eklenmedi.")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Zaman tüneline anı eklerken 'Bu bir Kilometre Taşı mı?' seçeneğini işaretlerseniz, anılarınız burada toplanır.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .padding(.top, 50)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(milestones) { milestone in
                                MilestoneCard(entry: milestone)
                                    .onTapGesture {
                                        selectedMilestone = milestone
                                    }
                            }
                        }
                        .padding()
                    }
                    }
                }
            }
            .navigationTitle("✨ İlklerim")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedMilestone) { milestone in
                NavigationView {
                    ScrollView {
                        MemoryCard(entry: milestone, isReadOnly: true)
                            .padding()
                    }
                    .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
                    .navigationTitle("Kilometre Taşı Detayı")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarItems(trailing: Button("Kapat") {
                        selectedMilestone = nil
                    })
                }
            }
        }
    }
}

struct MilestoneCard: View {
    let entry: MemoryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let firstMedia = entry.mediaPaths.first {
                if firstMedia.hasSuffix(".mp4") {
                    Color.black.opacity(0.1)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .shadow(radius: 5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if let data = StorageManager.shared.loadImage(fileName: firstMedia), let uiImage = UIImage(data: data) {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .contentShape(Rectangle())
                } else {
                    FallbackImage()
                }
            } else {
                FallbackImage()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct FallbackImage: View {
    var body: some View {
        Color.orange.opacity(0.2)
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    MilestonesView()
        .environmentObject(TimelineManager())
}
