//
//  VolunteerTask.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//

import Foundation
import FirebaseFirestore

struct VolunteerTask: Identifiable {
    let id: String
    let title: String
    let details: String
    let slots: Int
    let filledCount: Int
    let createdAt: Date

    init?(doc: QueryDocumentSnapshot) {
        let data = doc.data()
        guard
            let title = data["title"] as? String,
            let details = data["details"] as? String,
            let slots = data["slots"] as? Int
        else { return nil }

        let ts = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let filled = data["filledCount"] as? Int ?? 0

        self.id = doc.documentID
        self.title = title
        self.details = details
        self.slots = slots
        self.filledCount = filled
        self.createdAt = ts
    }
}
