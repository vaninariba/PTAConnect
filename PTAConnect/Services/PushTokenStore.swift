//
//  PushTokenStore.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore

final class PushTokenStore {
    private let db = Firestore.firestore()

    func saveMyToken(_ token: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try? await db.collection("users").document(uid).setData([
            "fcmToken": token
        ], merge: true)
    }
}
