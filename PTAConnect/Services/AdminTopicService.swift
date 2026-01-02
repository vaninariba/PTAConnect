//
//  AdminTopicService.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging

final class AdminTopicService {
    private let db = Firestore.firestore()

    func refreshAdminSubscription() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        do {
            let snap = try await db.collection("users").document(uid).getDocument()
            let role = (snap.data()?["role"] as? String ?? "parent").lowercased()

            if role == "admin" {
                try await Messaging.messaging().subscribe(toTopic: "admins")
            } else {
                try await Messaging.messaging().unsubscribe(fromTopic: "admins")
            }
        } catch {
            // We intentionally ignore errors here so the app never breaks
            print("Admin topic subscription error:", error.localizedDescription)
        }
    }
}

