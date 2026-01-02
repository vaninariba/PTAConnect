import Foundation
import FirebaseAuth
import FirebaseFirestore

final class AnnouncementService {
    private let db = Firestore.firestore()

    func listenAnnouncements(onChange: @escaping ([Announcement]) -> Void) -> ListenerRegistration {
        db.collection("announcements")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { Announcement(doc: $0) } ?? []
                onChange(items)
            }
    }

    func postAnnouncement(title: String, message: String) async throws {
        guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else { return }

        try await db.collection("announcements").addDocument(data: [
            "title": title,
            "message": message,
            "createdAt": Timestamp(date: Date()),
            "createdBy": uid
        ])
    }

    func fetchCurrentUserRole() async throws -> String {
        guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else { return "parent" }
        let snap = try await db.collection("users").document(uid).getDocument()
        return (snap.data()?["role"] as? String) ?? "parent"
    }
}

