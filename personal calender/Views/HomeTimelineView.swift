//
//  HomeTimelineView.swift
//  personal calender
//
//  Created by Emre URUL on 23.02.2026.
//

import SwiftUI

struct HomeTimelineView: View {
    @EnvironmentObject var timelineManager: TimelineManager
    @Binding var childProfile: ChildProfile?
    
    @State private var isExportingPDF = false
    @State private var pdfURL: URL? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all)
                
                VStack {
                    if let child = childProfile {
                        HeaderView(child: Binding(
                            get: { child },
                            set: { childProfile = $0 }
                        ), onDelete: {
                            childProfile = StorageManager.shared.loadProfile()
                        })
                        .padding(.top)
                        
                        if let firstPeriod = timelineManager.periods.first,
                           let tip = TipData.getTipFor(
                            weeks: firstPeriod.type == .week ? firstPeriod.number : nil,
                            months: firstPeriod.type == .month ? firstPeriod.number : nil
                           ) {
                            HStack(alignment: .top) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                Text(tip)
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.pink.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.pink.opacity(0.2), radius: 8, x: 0, y: 4)
                            .padding(.horizontal)
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(timelineManager.groupedPeriods) { period in
                                    if period.children != nil && !period.children!.isEmpty {
                                        NavigationLink(destination: PeriodListView(parentPeriod: period).environmentObject(timelineManager)) {
                                            TimelineCardView(period: period)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    } else {
                                        if let index = timelineManager.periods.firstIndex(where: { $0.id == period.id }) {
                                            NavigationLink(destination: MemoryDetailView(period: $timelineManager.periods[index]).environmentObject(timelineManager)) {
                                                TimelineCardView(period: period)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        } else {
                                            NavigationLink(destination: MemoryDetailView(period: .constant(period)).environmentObject(timelineManager)) {
                                                TimelineCardView(period: period)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    } else {
                        Text("Çocuk profili bulunamadı.")
                    }
                }
            }
            .navigationTitle("Zaman Tüneli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let child = childProfile {
                        Button(action: {
                            if let generatedURL = PDFGenerator.shared.generateTimelinePDF(child: child, periods: timelineManager.periods) {
                                pdfURL = generatedURL
                                isExportingPDF = true
                            }
                        }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $isExportingPDF) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
}

#Preview {
    HomeTimelineView(childProfile: .constant(ChildProfile(name: "Can", birthDate: Calendar.current.date(byAdding: .month, value: -6, to: Date())!)))
}
