//
//  VolunteerService.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore

final class VolunteerService {
    private let db = Firestore.firestore()

    // Tasks under a specific event
    func listenTasks(eventId: String, onChange: @escaping ([VolunteerTask]) -> Void) -> ListenerRegistration {
        db.collection("events").document(eventId)
            .collection("volunteerTasks")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { snapshot, _ in
                let items = snapshot?.documents.compactMap { VolunteerTask(doc: $0) } ?? []
                onChange(items)
            }
    }

    // Signups under a task
    func listenSignups(eventId: String, taskId: String, onChange: @escaping (Set<String>) -> Void) -> ListenerRegistration {
        db.collection("events").document(eventId)
            .collection("volunteerTasks").document(taskId)
            .collection("signups")
            .addSnapshotListener { snapshot, _ in
                let uids = Set(snapshot?.documents.map { $0.documentID } ?? [])
                onChange(uids)
            }
    }
    func signUp(eventId: String, taskId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        let taskRef = db.collection("events").document(eventId)
            .collection("volunteerTasks").document(taskId)

        let signupRef = taskRef.collection("signups").document(uid)

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let taskSnap = try transaction.getDocument(taskRef)
                let slots = taskSnap.data()?["slots"] as? Int ?? 0
                let filled = taskSnap.data()?["filledCount"] as? Int ?? 0

                // already signed up? do nothing
                if let signupSnap = try? transaction.getDocument(signupRef), signupSnap.exists {
                    return nil
                }

                if filled >= slots {
                    let err = NSError(domain: "PTAConnect", code: 1,
                                      userInfo: [NSLocalizedDescriptionKey: "This task is full."])
                    errorPointer?.pointee = err
                    return nil
                }

                transaction.setData([
                    "createdAt": Timestamp(date: Date())
                ], forDocument: signupRef)

                transaction.updateData([
                    "filledCount": filled + 1
                ], forDocument: taskRef)

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    func cancel(eventId: String, taskId: String) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        let taskRef = db.collection("events").document(eventId)
            .collection("volunteerTasks").document(taskId)

        let signupRef = taskRef.collection("signups").document(uid)

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let taskSnap = try transaction.getDocument(taskRef)
                let filled = taskSnap.data()?["filledCount"] as? Int ?? 0

                let signupSnap = try transaction.getDocument(signupRef)
                if !signupSnap.exists {
                    return nil
                }

                transaction.deleteDocument(signupRef)
                transaction.updateData([
                    "filledCount": max(0, filled - 1)
                ], forDocument: taskRef)

                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }


    // Create task (admin only)
    func createTask(eventId: String, title: String, details: String, slots: Int) async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try await db.collection("events").document(eventId)
            .collection("volunteerTasks")
            .addDocument(data: [
                "title": title,
                "details": details,
                "slots": slots,
                "createdAt": Timestamp(date: Date()),
                "createdBy": uid
            ])
    }
}
