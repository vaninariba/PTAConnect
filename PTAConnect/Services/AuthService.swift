import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

final class AuthService: ObservableObject {

    @Published var user: FirebaseAuth.User?
    private var listener: AuthStateDidChangeListenerHandle?

    init() {
        self.user = Auth.auth().currentUser

        // Attach listener AFTER init completes (prevents objectWillChange init error)
        DispatchQueue.main.async { [weak self] in
            self?.attachAuthListener()
        }
    }

    deinit {
        if let listener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func attachAuthListener() {
        if listener != nil { return }

        listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await MainActor.run { self.user = result.user }
    }

    func signUp(name: String, email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        await MainActor.run { self.user = result.user }

        let uid = result.user.uid
        try await Firestore.firestore()
            .collection("users")
            .document(uid)
            .setData([
                "name": name,
                "email": email,
                "role": "parent",
                "createdAt": Timestamp(date: Date())
            ], merge: true)
    }

    func signOut() throws {
        try Auth.auth().signOut()
        DispatchQueue.main.async { self.user = nil }
    }
    func Tasyncask() async { await AdminTopicService().refreshAdminSubscription() }

}

