import Foundation

struct ChildProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var birthDate: Date
    var profileImageData: Data?
}
