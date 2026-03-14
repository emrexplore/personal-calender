import SwiftUI
import PhotosUI

struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var childProfile: ChildProfile?
    
    @State private var name: String = ""
    @State private var birthDate: Date = Date()
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var profileImageData: Data? = nil
    
    // For a nice spring animation appearance
    @State private var isAppearing = false
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // Header Section
                    VStack(spacing: 16) {
                        // Photo Picker
                        PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                            ZStack(alignment: .bottomTrailing) {
                                if let data = profileImageData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(LinearGradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 120, height: 120)
                                        
                                        Image(systemName: "face.smiling")
                                            .font(.system(size: 50, weight: .light))
                                            .foregroundColor(.white)
                                    }
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                }
                                
                                // Plus Badge
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 36, height: 36)
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.blue)
                                    )
                                    .offset(x: 0, y: 0)
                            }
                            .padding(.top, 40)
                        }
                        .onChange(of: selectedItem) { _, _ in
                            Task {
                                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                    withAnimation(.spring()) {
                                        profileImageData = data
                                    }
                                }
                            }
                        }
                        
                        VStack(spacing: 8) {
                            Text("Bebek Gelişimine\nHoş Geldiniz")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                            
                            Text("Bebeğinizin en özel anlarını ve büyüme serüvenini ömür boyu güvenle saklayın.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                    }
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 20)
                    
                    // Form Section
                    VStack(spacing: 24) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BEBEĞİNİZİN ADI")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "person.text.rectangle")
                                    .foregroundColor(.blue.opacity(0.7))
                                    .frame(width: 24)
                                TextField("Adı", text: $name)
                                    .font(.body)
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        
                        // Date Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DOĞUM TARİHİ")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue.opacity(0.7))
                                    .frame(width: 24)
                                DatePicker("", selection: $birthDate, in: ...Date(), displayedComponents: .date)
                                    .labelsHidden()
                                    .environment(\.locale, Locale(identifier: "tr"))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                            .background(Color(UIColor.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(24)
                    .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
                    .cornerRadius(24)
                    .padding(.horizontal, 20)
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 20)
                    
                    // Start Button
                    Button(action: {
                        let profile = ChildProfile(
                            name: name.isEmpty ? "Bebeğim" : name,
                            birthDate: birthDate,
                            profileImageData: profileImageData
                        )
                        StorageManager.shared.saveProfile(profile)
                        NotificationManager.shared.scheduleSmartNotification(birthDate: birthDate)
                        withAnimation(.easeInOut) {
                            childProfile = profile
                        }
                        dismiss()
                    }) {
                        HStack {
                            Text("Serüven Başlasın")
                                .font(.headline)
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.blue, .purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                    .opacity(isAppearing ? 1 : 0)
                    .offset(y: isAppearing ? 0 : 20)
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAppearing = true
            }
        }
    }
}

#Preview {
    OnboardingView(childProfile: .constant(nil))
}
