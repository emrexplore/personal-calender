import SwiftUI
import PhotosUI

// Başlık ve Profil Kartı
struct HeaderView: View {
    @Binding var child: ChildProfile
    var onDelete: (() -> Void)? = nil
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var isAddingNewProfile = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack {
            PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 66, height: 66)
                    
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 60, height: 60)
                    
                    if let imageData = child.profileImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                            .opacity(0.5)
                    }
                }
            }
            .onChange(of: selectedItem) {
                Task {
                    if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                        child.profileImageData = data
                        StorageManager.shared.saveProfile(child)
                    }
                }
            }
            
            Menu {
                ForEach(StorageManager.shared.loadProfiles()) { profile in
                    Button {
                        child = profile
                        StorageManager.shared.saveSelectedProfileID(profile.id)
                    } label: {
                        if profile.id == child.id {
                            Label(profile.name, systemImage: "checkmark")
                        } else {
                            Text(profile.name)
                        }
                    }
                }
                Divider()
                Button(action: { isAddingNewProfile = true }) {
                    Label("Yeni Çocuk Ekle", systemImage: "plus.circle")
                }
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Label("Bu Profili Sil", systemImage: "trash")
                }
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(child.name)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.down.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    
                    let ageString = calculateAgeString(from: child.birthDate)
                    Text(ageString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
        .padding(.horizontal)
        .alert("Profili Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                StorageManager.shared.deleteProfile(child.id)
                onDelete?()
            }
        } message: {
            Text("\(child.name) adlı çocuğun tüm anıları ve verileri fiziksel olarak cihazınızdan silinecektir. Bu işlem geri alınamaz. Onaylıyor musunuz?")
        }
        .sheet(isPresented: $isAddingNewProfile) {
            OnboardingView(childProfile: Binding(
                get: { nil },
                set: { newProfile in
                    if let p = newProfile {
                        child = p
                    }
                }
            ))
        }
    }
    
    // Küçük bir yardımcı fonksiyon. Yaş hesaplaması için
    private func calculateAgeString(from date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .weekOfYear], from: date, to: Date())
        
        let targetYear = components.year ?? 0
        let targetMonth = components.month ?? 0
        let targetWeek = components.weekOfYear ?? 0
        
        if targetYear > 0 {
            return "\(targetYear) Yaş \(targetMonth) Ay"
        } else if targetMonth > 0 {
            return "\(targetMonth) Aylık"
        } else {
            return "\(targetWeek) Haftalık"
        }
    }
}
