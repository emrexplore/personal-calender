import SwiftUI

struct PeriodListView: View {
    @EnvironmentObject var timelineManager: TimelineManager
    let parentPeriod: TimelinePeriod
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if let children = parentPeriod.children {
                    ForEach(children) { child in
                        if child.children != nil && !child.children!.isEmpty {
                            // Eğer alt kırılımları varsa (Yıl -> Ay gibi), tekrar PeriodListView'e git
                            NavigationLink(destination: PeriodListView(parentPeriod: child).environmentObject(timelineManager)) {
                                TimelineCardView(period: child)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // Eğer en alt kırılımsa (Ay -> Hafta gibi), MemoryDetailView'e git
                            if let index = timelineManager.periods.firstIndex(where: { $0.id == child.id }) {
                                NavigationLink(destination: MemoryDetailView(period: $timelineManager.periods[index]).environmentObject(timelineManager)) {
                                    TimelineCardView(period: child)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                NavigationLink(destination: MemoryDetailView(period: .constant(child)).environmentObject(timelineManager)) {
                                    TimelineCardView(period: child)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                } else {
                    Text("Bu döneme ait anı bulunmuyor.")
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle(parentPeriod.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
