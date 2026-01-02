//
//  EventService.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore

final class EventService {
    private let db = Firestore.firestore()

    func listenEvents(onChange: @escaping ([PTAEvent]) -> Void) -> ListenerRegistration {
        db.collection("events")
            .order(by: "startAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { PTAEvent(doc: $0) } ?? []
                onChange(items)
            }
    }

    func createEvent(title: String, location: String, details: String, startAt: Date, endAt: Date) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        try await db.collection("events").addDocument(data: [
            "title": title,
            "location": location,
            "details": details,
            "startAt": Timestamp(date: startAt),
            "endAt": Timestamp(date: endAt),
            "createdAt": Timestamp(date: Date()),
            "createdBy": uid
        ])
    }

    func fetchCurrentUserRole() async throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else { return "parent" }
        let snap = try await db.collection("users").document(uid).getDocument()
        return (snap.data()?["role"] as? String) ?? "parent"
    }
}
