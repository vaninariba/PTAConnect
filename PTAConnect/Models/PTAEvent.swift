//
//  PTAEvent.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//


import Foundation
import FirebaseFirestore

struct PTAEvent: Identifiable {
    let id: String
    let title: String
    let location: String
    let details: String
    let startAt: Date
    let endAt: Date

    init?(doc: QueryDocumentSnapshot) {
        let data = doc.data()

        guard
            let title = data["title"] as? String,
            let location = data["location"] as? String,
            let details = data["details"] as? String,
            let startTS = data["startAt"] as? Timestamp,
            let endTS = data["endAt"] as? Timestamp
        else { return nil }

        self.id = doc.documentID
        self.title = title
        self.location = location
        self.details = details
        self.startAt = startTS.dateValue()
        self.endAt = endTS.dateValue()
    }
}
