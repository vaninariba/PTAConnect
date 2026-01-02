//
//  Announcement.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/26/25.
//


import Foundation
import FirebaseFirestore

struct Announcement: Identifiable {
    let id: String
    let title: String
    let message: String
    let createdAt: Date

    init?(doc: QueryDocumentSnapshot) {
        let data = doc.data()
        guard
            let title = data["title"] as? String,
            let message = data["message"] as? String
        else { return nil }

        let ts = data["createdAt"] as? Timestamp
        self.id = doc.documentID
        self.title = title
        self.message = message
        self.createdAt = ts?.dateValue() ?? Date()
    }
}
