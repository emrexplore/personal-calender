//
//  ContentView.swift
//  personal calender
//
//  Created by Emre URUL on 23.02.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var childProfile: ChildProfile? = nil
    @State private var isProfileLoaded: Bool = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            if isProfileLoaded {
                if childProfile == nil {
                    OnboardingView(childProfile: $childProfile)
                        .onAppear { print("DEBUG: OnboardingView gösteriliyor.") }
                } else {
                    MainTabView(childProfile: $childProfile)
                        .onAppear { print("DEBUG: MainTabView gösteriliyor.") }
                }
            } else {
                Text("Special for Burcu and Çağrı Yüngeviş")
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                    .onAppear { print("DEBUG: Splash ekranı gösteriliyor.") }
            }
        }
        .onAppear {
            print("DEBUG: ContentView onAppear tetiklendi")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if let savedProfile = StorageManager.shared.loadProfile() {
                    print("DEBUG: Profil bulundu: \(savedProfile.name)")
                    childProfile = savedProfile
                } else {
                    print("DEBUG: Profil bulunamadı, Onboarding'e geçilecek.")
                }
                isProfileLoaded = true
            }
        }
    }
}

#Preview {
    ContentView()
}

