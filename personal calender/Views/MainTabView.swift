import SwiftUI

struct MainTabView: View {
    @Binding var childProfile: ChildProfile?
    @StateObject private var timelineManager = TimelineManager()
    
    var body: some View {
        TabView {
            // SEKM 1: Zaman Tüneli
            HomeTimelineView(childProfile: $childProfile)
                .environmentObject(timelineManager)
                .tabItem {
                    Label("Zaman Tüneli", systemImage: "clock.arrow.circlepath")
                }
            
            // SEKM 2: İlklerim
            MilestonesView()
                .environmentObject(timelineManager)
                .tabItem {
                    Label("İlklerim", systemImage: "star.fill")
                }
            
            // SEKM 3: Grafikler
            NavigationView {
                GrowthChartView()
                    .environmentObject(timelineManager)
            }
            .tabItem {
                Label("Gelişim", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
        .onAppear {
            timelineManager.childID = childProfile?.id
            timelineManager.load()
            if timelineManager.periods.isEmpty {
                if let child = childProfile {
                    timelineManager.generateTimeline(birthDate: child.birthDate)
                }
            } else {
                if let child = childProfile {
                    timelineManager.updateTimelineIfNeeded(birthDate: child.birthDate)
                }
            }
        }
        .onChange(of: childProfile?.id) { newId in
            timelineManager.childID = newId
            timelineManager.load()
            if timelineManager.periods.isEmpty {
                if let child = childProfile {
                    timelineManager.generateTimeline(birthDate: child.birthDate)
                }
            } else {
                if let child = childProfile {
                    timelineManager.updateTimelineIfNeeded(birthDate: child.birthDate)
                }
            }
        }
    }
}

#Preview {
    MainTabView(childProfile: .constant(ChildProfile(name: "Can", birthDate: Date())))
}
