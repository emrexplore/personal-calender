import SwiftUI
import Charts

struct GrowthChartView: View {
    @EnvironmentObject var timelineManager: TimelineManager
    @State private var isAddingData = false
    @State private var editingData: GrowthData? = nil
    
    // Yalnızca grafiği çizebilmek için tüm dönemlerden GrowthData'yı toparlayan computed property
    var growthData: [GrowthData] {
        timelineManager.periods.flatMap { $0.growthData }
    }
    
    var body: some View {
        Group {
            if growthData.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("Henüz büyüme verisi eklenmedi.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Gelişim verilerini anasayfadaki zaman tünelinden haftaların detayına girerek ekleyebilirsiniz.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 30) {
                        // Kilo Grafiği
                        if !growthData.filter({ $0.weight != nil }).isEmpty {
                            VStack(alignment: .leading) {
                                Text("Kilo Gelişimi (kg)")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Chart {
                                    ForEach(growthData.filter { $0.weight != nil }.sorted(by: { $0.date < $1.date })) { data in
                                        if let weight = data.weight {
                                            LineMark(
                                                x: .value("Tarih", data.date),
                                                y: .value("Kilo", weight)
                                            )
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                )
                                            )
                                            
                                            PointMark(
                                                x: .value("Tarih", data.date),
                                                y: .value("Kilo", weight)
                                            )
                                            .foregroundStyle(Color.blue)
                                        }
                                    }
                                }
                                .frame(height: 250)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(radius: 2)
                                .padding(.horizontal)
                            }
                        }
                        
                        // Boy Grafiği
                        if !growthData.filter({ $0.height != nil }).isEmpty {
                            VStack(alignment: .leading) {
                                Text("Boy Gelişimi (cm)")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Chart {
                                    ForEach(growthData.filter { $0.height != nil }.sorted(by: { $0.date < $1.date })) { data in
                                        if let height = data.height {
                                            LineMark(
                                                x: .value("Tarih", data.date),
                                                y: .value("Boy", height)
                                            )
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.green, Color.mint]),
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                )
                                            )
                                            
                                            PointMark(
                                                x: .value("Tarih", data.date),
                                                y: .value("Boy", height)
                                            )
                                            .foregroundStyle(Color.green)
                                        }
                                    }
                                }
                                .frame(height: 250)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(radius: 2)
                                .padding(.horizontal)
                            }
                        }
                        
                        // Baş Çevresi Grafiği
                        if !growthData.filter({ $0.headCircumference != nil }).isEmpty {
                            VStack(alignment: .leading) {
                                Text("Baş Çevresi (cm)")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                Chart {
                                    ForEach(growthData.filter { $0.headCircumference != nil }.sorted(by: { $0.date < $1.date })) { data in
                                        if let headCirc = data.headCircumference {
                                            LineMark(
                                                x: .value("Tarih", data.date),
                                                y: .value("Baş Çevresi", headCirc)
                                            )
                                            .interpolationMethod(.catmullRom)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.orange, Color.yellow]),
                                                    startPoint: .bottom,
                                                    endPoint: .top
                                                )
                                            )
                                            
                                            PointMark(
                                                x: .value("Tarih", data.date),
                                                y: .value("Baş Çevresi", headCirc)
                                            )
                                            .foregroundStyle(Color.orange)
                                        }
                                    }
                                }
                                .frame(height: 250)
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .shadow(radius: 2)
                                .padding(.horizontal)
                            }
                        }

                        // --- GEÇMİŞ ÖLÇÜMLER LİSTESİ ---
                        if !growthData.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Geçmiş Ölçümler")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ForEach(growthData.sorted(by: { $0.date > $1.date })) { data in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(data.date.formatted(date: .abbreviated, time: .omitted))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            HStack(spacing: 12) {
                                                if let h = data.height { Text("Boy: \(h, specifier: "%.1f") cm") }
                                                if let w = data.weight { Text("Kilo: \(w, specifier: "%.1f") kg") }
                                                if let hc = data.headCircumference { Text("Baş: \(hc, specifier: "%.1f") cm") }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Düzenle Butonu
                                        Button(action: {
                                            editingData = data
                                            isAddingData = true
                                        }) {
                                            Image(systemName: "pencil.circle.fill")
                                                .foregroundColor(.orange)
                                                .font(.title3)
                                        }
                                        .padding(.trailing, 8)
                                        
                                        // Sil Butonu
                                        Button(action: {
                                            deleteMeasurement(data)
                                        }) {
                                            Image(systemName: "trash.circle.fill")
                                                .foregroundColor(.red)
                                                .font(.title3)
                                        }
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 20)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("Büyüme Analizi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    editingData = nil
                    isAddingData = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingData) {
            AddGrowthDataView(editingData: editingData) { newData in
                saveMeasurement(newData)
            }
        }
        .onAppear {
            timelineManager.load()
        }
    }
    
    private func saveMeasurement(_ newData: GrowthData) {
        // Find which period this date belongs to
        guard let targetIndex = timelineManager.periods.firstIndex(where: { period in
            newData.date >= period.startDate && newData.date <= period.endDate
        }) else {
            // Fallback: If no strict boundaries found (e.g baby too old/young), append to earliest/latest period possible
            if let first = timelineManager.periods.first, newData.date > first.endDate {
                updateOrAppend(in: 0, newData: newData)
            } else if let last = timelineManager.periods.last, newData.date < last.startDate {
                updateOrAppend(in: timelineManager.periods.count - 1, newData: newData)
            } else {
                print("Could not find matching TimelinePeriod for date \(newData.date)")
            }
            return
        }
        
        // Target period found, update or insert
        updateOrAppend(in: targetIndex, newData: newData)
    }
    
    private func updateOrAppend(in index: Int, newData: GrowthData) {
        // Clean up from ALL other periods to prevent duplicate historical ghosts during edit
        for i in 0..<timelineManager.periods.count {
            timelineManager.periods[i].growthData.removeAll(where: { $0.id == newData.id })
        }
        
        timelineManager.periods[index].growthData.append(newData)
        timelineManager.save()
    }
    
    private func deleteMeasurement(_ data: GrowthData) {
        for i in 0..<timelineManager.periods.count {
            if timelineManager.periods[i].growthData.contains(where: { $0.id == data.id }) {
                timelineManager.periods[i].growthData.removeAll(where: { $0.id == data.id })
            }
        }
        timelineManager.save()
    }
}

#Preview {
    NavigationView {
        GrowthChartView()
            .environmentObject(TimelineManager())
    }
}
