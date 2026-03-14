import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct MemoryDetailView: View {
    @EnvironmentObject var timelineManager: TimelineManager
    @Binding var period: TimelinePeriod
    
    @State private var newNoteTitle: String = ""
    @State private var newNoteDesc: String = ""
    @State private var isAddingNote: Bool = false
    @State private var editingMemory: MemoryEntry? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Tarih Bilgisi
                HStack {
                    Image(systemName: "calendar")
                    Text("\(period.startDate.formatted(date: .abbreviated, time: .omitted)) - \(period.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Anılar Listesi
                if period.entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Henüz bu döneme ait bir anı eklenmedi.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(period.entries) { entry in
                        MemoryCard(
                            entry: entry,
                            onEdit: {
                                editingMemory = entry
                                isAddingNote = true
                            },
                            onDelete: {
                                for path in entry.mediaPaths {
                                    StorageManager.shared.deleteMedia(fileName: path)
                                }
                                
                                if let audioPath = entry.audioPath {
                                    StorageManager.shared.deleteAudio(fileName: audioPath)
                                }
                                
                                period.entries.removeAll(where: { $0.id == entry.id })
                                
                                // KALICI MERKEZİ KAYIT (Value type sync)
                                if let masterIndex = timelineManager.periods.firstIndex(where: { $0.id == period.id }) {
                                    timelineManager.periods[masterIndex] = period
                                }
                                timelineManager.save()
                            }
                        )
                    }
                    .padding(.horizontal)
                }
                

                
                Spacer(minLength: 80) // FAB için boşluk
            }
            .padding(.top)
        }
        .navigationTitle(period.title)
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        editingMemory = nil
                        isAddingNote = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title.weight(.semibold))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 4, x: 0, y: 4)
                    }
                    .padding()
                }
            }
        )
        .sheet(isPresented: $isAddingNote) {
            AddMemorySheet(period: $period, editingEntry: editingMemory)
                .onDisappear {
                    timelineManager.save()
                }
        }
    }
}

struct MemoryCard: View {
    let entry: MemoryEntry
    @EnvironmentObject var timelineManager: TimelineManager
    
    @StateObject private var audioPlayer = AudioPlayer()
    
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if entry.isMilestone {
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.yellow)
                        Text(entry.milestoneType?.rawValue ?? "Kilometre Taşı")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Düzenle", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Sil", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(8)
                }
            }
            
            Text(entry.title)
                .font(.headline)
            
            Text(entry.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            if !entry.mediaPaths.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entry.mediaPaths, id: \.self) { path in
                            if path.hasSuffix(".mp4") {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.black.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                    Image(systemName: "play.rectangle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.blue)
                                }
                            } else if let imageData = StorageManager.shared.loadImage(fileName: path),
                               let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .frame(height: 100)
            }
            
            // Kaydedilmiş Sesli Not Varsa Göster
            if let audioPath = entry.audioPath {
                HStack(spacing: 12) {
                    Button(action: {
                        if audioPlayer.isPlaying {
                            audioPlayer.pauseAudio()
                        } else {
                            if let url = StorageManager.shared.loadAudioURL(fileName: audioPath) {
                                audioPlayer.playAudio(from: url)
                            }
                        }
                    }) {
                        Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sesli Not")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if audioPlayer.isPlaying {
                            ProgressView(value: audioPlayer.playbackProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        }
                    }
                    
                    Spacer()
                }
                .padding(10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
            
            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct AddMemorySheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var timelineManager: TimelineManager
    @Binding var period: TimelinePeriod
    
    var editingEntry: MemoryEntry? = nil
    
    @State private var title = ""
    @State private var desc = ""
    @State private var isMilestone = false
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedMediaData: [SelectedMedia] = []
    @State private var existingMediaPaths: [String] = []
    
    // Audio Kaydı Değişkenleri
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var existingAudioPath: String?
    @State private var newRecordedAudioData: Data?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Anı Detayları")) {
                    TextField("Başlık", text: $title)
                    TextEditor(text: $desc)
                        .frame(height: 100)
                }
                
                Section(header: Text("Fotoğraflar")) {
                    PhotosPicker(selection: $selectedItems, matching: .any(of: [.images, .videos]), photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Yeni Medya (Foto/Video) Ekle")
                        }
                    }
                    .onChange(of: selectedItems) {
                        Task {
                            selectedMediaData.removeAll()
                            for item in selectedItems {
                                let isVideo = item.supportedContentTypes.contains(UTType.movie) || item.supportedContentTypes.contains(UTType.video) || item.supportedContentTypes.contains(UTType.audiovisualContent)
                                if let data = try? await item.loadTransferable(type: Data.self) {
                                    selectedMediaData.append(SelectedMedia(data: data, isVideo: isVideo))
                                }
                            }
                        }
                    }
                    
                    // Önceden eklenmiş fotoğraflar
                    if !existingMediaPaths.isEmpty {
                        Text("Mevcut Fotoğraflar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(existingMediaPaths, id: \.self) { path in
                                    ZStack(alignment: .topTrailing) {
                                        if path.hasSuffix(".mp4") {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.black.opacity(0.1))
                                                    .frame(width: 60, height: 60)
                                                Image(systemName: "play.rectangle.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 30, height: 30)
                                                    .foregroundColor(.blue)
                                            }
                                        } else if let imageData = StorageManager.shared.loadImage(fileName: path),
                                           let uiImage = UIImage(data: imageData) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        
                                        Button(action: {
                                            if let index = existingMediaPaths.firstIndex(of: path) {
                                                existingMediaPaths.remove(at: index)
                                            }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white))
                                        }
                                        .offset(x: 5, y: -5)
                                    }
                                }
                            }
                        }
                        .frame(height: 70)
                    }
                    
                    // Yeni eklenen fotoğraflar
                    if !selectedMediaData.isEmpty {
                        Text("Yeni Seçilenler")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(selectedMediaData) { media in
                                    if media.isVideo {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.black.opacity(0.1))
                                                .frame(width: 60, height: 60)
                                            Image(systemName: "play.rectangle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 30, height: 30)
                                                .foregroundColor(.blue)
                                        }
                                    } else if let uiImage = UIImage(data: media.data) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }
                        .frame(height: 60)
                    }
                }
                
                Section(header: Text("Sesli Not")) {
                    if let existingAudio = existingAudioPath {
                        // Var olan sesi oynat veya sil
                        HStack {
                            Button(action: {
                                if audioPlayer.isPlaying {
                                    audioPlayer.pauseAudio()
                                } else {
                                    if let url = StorageManager.shared.loadAudioURL(fileName: existingAudio) {
                                        audioPlayer.playAudio(from: url)
                                    }
                                }
                            }) {
                                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.blue)
                            }
                            
                            if audioPlayer.isPlaying {
                                ProgressView(value: audioPlayer.playbackProgress)
                                    .progressViewStyle(LinearProgressViewStyle())
                            } else {
                                Text("Kaydedilmiş Sesli Not")
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Silme (kayıt edilene kadar geçici tut)
                                existingAudioPath = nil
                                audioPlayer.stopAudio()
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    } else if newRecordedAudioData != nil {
                        // Yeni kaydedilen sesi onayla / sil
                        HStack {
                            Text("Yeni ses kaydedildi")
                                .foregroundColor(.green)
                            Spacer()
                            Button("Sil") {
                                newRecordedAudioData = nil
                                audioRecorder.discardRecording()
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        // Kayıt arayüzü
                        if !audioRecorder.permissionGranted {
                            Text("Mikrofon izni gerekli.")
                                .foregroundColor(.red)
                                .font(.caption)
                            Button("İzin İste") {
                                audioRecorder.checkPermissions()
                            }
                        } else {
                            HStack {
                                if audioRecorder.isRecording {
                                    Text(String(format: "Kaydediliyor... %.1f sn", audioRecorder.recordingDuration))
                                        .foregroundColor(.red)
                                    Spacer()
                                    Button(action: {
                                        audioRecorder.stopRecording()
                                        if let url = audioRecorder.recordedAudioURL, let data = try? Data(contentsOf: url) {
                                            newRecordedAudioData = data
                                        }
                                    }) {
                                        Image(systemName: "stop.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.red)
                                    }
                                } else {
                                    Button(action: {
                                        audioRecorder.startRecording()
                                    }) {
                                        HStack {
                                            Image(systemName: "mic.circle.fill")
                                                .font(.title)
                                            Text("Kayda Başla")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Toggle("Bu bir Kilometre Taşı mı?", isOn: $isMilestone)
                }
                
                Button("Kaydet") {
                    // Kullanıcı düzenleme sırasında bazı fotoğrafları (X) ile kaldırmışsa o dosyaları fiziksel çöpe atalım.
                    if let oldPaths = editingEntry?.mediaPaths {
                        let deletedPaths = oldPaths.filter { !existingMediaPaths.contains($0) }
                        for path in deletedPaths {
                            StorageManager.shared.deleteMedia(fileName: path)
                        }
                    }
                    
                    var savedPaths: [String] = existingMediaPaths
                    for media in selectedMediaData {
                        if let path = StorageManager.shared.saveMedia(data: media.data, isVideo: media.isVideo) {
                            savedPaths.append(path)
                        }
                    }
                    
                    // Ses kaydetme / Silineni çöpe atma işlemi
                    var finalAudioPath: String? = existingAudioPath
                    
                    if let editingEntry = editingEntry, let oldAudio = editingEntry.audioPath, oldAudio != existingAudioPath {
                        // Eski ses silinmiş
                        StorageManager.shared.deleteAudio(fileName: oldAudio)
                    }
                    
                    if let newAudioData = newRecordedAudioData {
                        // Yeni ses kaydedilmiş
                        if let savedAudio = StorageManager.shared.saveAudio(data: newAudioData) {
                            finalAudioPath = savedAudio
                        }
                    }
                    
                    let targetID = editingEntry?.id ?? UUID()
                    let dateToKeep = editingEntry?.date ?? Date()
                    
                    let newEntry = MemoryEntry(
                        id: targetID,
                        title: title,
                        description: desc,
                        date: dateToKeep,
                        mediaPaths: savedPaths,
                        audioPath: finalAudioPath,
                        isMilestone: isMilestone,
                        milestoneType: isMilestone ? .other : nil
                    )
                    
                    if let editingEntry = editingEntry, let index = period.entries.firstIndex(where: { $0.id == editingEntry.id }) {
                        period.entries[index] = newEntry
                    } else {
                        period.entries.append(newEntry)
                    }
                    
                    if let masterIndex = timelineManager.periods.firstIndex(where: { $0.id == period.id }) {
                        timelineManager.periods[masterIndex] = period
                    }
                    
                    dismiss()
                }
                .disabled(title.isEmpty)
            }
            .navigationTitle(editingEntry == nil ? "Yeni Anı Ekle" : "Anıyı Düzenle")
            .navigationBarItems(leading: Button("İptal") { dismiss() })
            .onAppear {
                if let entry = editingEntry {
                    title = entry.title
                    desc = entry.description
                    isMilestone = entry.isMilestone
                    existingMediaPaths = entry.mediaPaths
                    existingAudioPath = entry.audioPath
                } // İzin kontrolünü recorder initialize olduğunda zaten yapıyor.
            }
        }
    }
}

#Preview {
    MemoryDetailView(period: .constant(TimelinePeriod(type: .week, number: 1, startDate: Date(), endDate: Date())))
}

struct SelectedMedia: Identifiable {
    let id = UUID()
    let data: Data
    let isVideo: Bool
}
