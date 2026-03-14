import SwiftUI

struct AddGrowthDataView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var editingData: GrowthData? = nil
    
    @State private var date: Date = Date()
    @State private var heightString: String = ""
    @State private var weightString: String = ""
    @State private var headCircumferenceString: String = ""
    @State private var notes: String = ""
    
    var onSave: (GrowthData) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tarih")) {
                    DatePicker("Ölçüm Tarihi", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("Ölçümler")) {
                    HStack {
                        Text("Boy")
                        Spacer()
                        TextField("Örn: 50.5", text: $heightString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Kilo")
                        Spacer()
                        TextField("Örn: 3.5", text: $weightString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Baş Çevresi")
                        Spacer()
                        TextField("Örn: 35.0", text: $headCircumferenceString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Notlar (Opsiyonel)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(editingData == nil ? "Yeni Ölçüm Ekle" : "Ölçümü Düzenle")
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Kaydet") {
                    saveData()
                }
                .disabled(heightString.isEmpty && weightString.isEmpty && headCircumferenceString.isEmpty)
            )
            .onAppear {
                if let data = editingData {
                    date = data.date
                    if let h = data.height { heightString = String(h) }
                    if let w = data.weight { weightString = String(w) }
                    if let hc = data.headCircumference { headCircumferenceString = String(hc) }
                    notes = data.notes ?? ""
                }
            }
        }
    }
    
    private func saveData() {
        // Convert strings to double, replacing comma with dot if necessary
        let height = Double(heightString.replacingOccurrences(of: ",", with: "."))
        let weight = Double(weightString.replacingOccurrences(of: ",", with: "."))
        let headCircumference = Double(headCircumferenceString.replacingOccurrences(of: ",", with: "."))
        
        // Eğer editliyorsak eski ID'yi kullan, yoksa yeni üret
        let targetID = editingData?.id ?? UUID()
        
        let newEntry = GrowthData(
            id: targetID,
            date: date,
            height: height,
            weight: weight,
            headCircumference: headCircumference,
            notes: notes.isEmpty ? nil : notes
        )
        
        onSave(newEntry)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AddGrowthDataView(onSave: { _ in })
}
