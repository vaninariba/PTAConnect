import SwiftUI
import FirebaseFirestore
import UIKit

struct SignupListView: View {
    let eventId: String
    let taskId: String

    @State private var uids: [String] = []
    @State private var people: [String: UserProfile] = [:]

    @State private var signupsListener: ListenerRegistration?
    @State private var usersListeners: [String: ListenerRegistration] = [:]

    @State private var showCopied = false
    @State private var showShare = false
    @State private var shareItems: [Any] = []

    @State private var showError = false
    @State private var errorMessage: String?

    @State private var isLoading = true   // 🔑 FIX

    var body: some View {
        List {

            // 🔑 Loading state (prevents “everything canceled” illusion)
            if isLoading {
                ProgressView("Loading sign-ups…")
                    .frame(maxWidth: .infinity, alignment: .center)

            } else if uids.isEmpty {
                Text("No sign-ups yet.")
                    .foregroundStyle(.secondary)

            } else {
                ForEach(uids, id: \.self) { uid in
                    if let p = people[uid] {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(p.name.isEmpty ? "Unnamed" : p.name)
                                .font(.headline)
                            Text(p.email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        // Partial loading per user
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Loading…")
                                .foregroundStyle(.secondary)
                            Text(uid)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Signed up")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {

                Button {
                    copyToClipboard()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .disabled(exportText.isEmpty)

                Button {
                    shareItems = [exportText]
                    showShare = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(exportText.isEmpty)
            }
        }
        .sheet(isPresented: $showShare) {
            ActivityView(activityItems: shareItems)
        }
        .alert("Copied", isPresented: $showCopied) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Volunteer list copied to clipboard.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .onAppear { start() }
        .onDisappear { stop() }
    }

    // MARK: - Export text

    private var exportText: String {
        uids.compactMap { uid in
            guard let p = people[uid] else { return nil }
            let name = p.name.isEmpty ? "Unnamed" : p.name
            return "\(name) — \(p.email)"
        }
        .joined(separator: "\n")
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = exportText
        showCopied = true
    }

    // MARK: - Firestore listeners

    private func start() {
        if signupsListener != nil { return }

        isLoading = true

        let db = Firestore.firestore()
        signupsListener = db
            .collection("events").document(eventId)
            .collection("volunteerTasks").document(taskId)
            .collection("signups")
            .addSnapshotListener { snapshot, error in

                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.showError = true
                        self.isLoading = false
                    }
                    return
                }

                let ids = snapshot?.documents.map { $0.documentID } ?? []

                DispatchQueue.main.async {
                    self.uids = ids.sorted()
                    self.ensureUserListeners(for: ids)
                    self.isLoading = false   // 🔑 only here
                }
            }
    }

    private func ensureUserListeners(for ids: [String]) {
        let current = Set(ids)

        // Remove listeners only (do NOT clear list globally)
        for (uid, listener) in usersListeners where !current.contains(uid) {
            listener.remove()
            usersListeners.removeValue(forKey: uid)
            people.removeValue(forKey: uid)
        }

        let db = Firestore.firestore()
        for uid in ids where usersListeners[uid] == nil {
            let l = db.collection("users").document(uid)
                .addSnapshotListener { snap, error in

                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage = error.localizedDescription
                            self.showError = true
                        }
                        return
                    }

                    guard let data = snap?.data() else { return }

                    let profile = UserProfile(
                        uid: uid,
                        name: data["name"] as? String ?? "",
                        email: data["email"] as? String ?? ""
                    )

                    DispatchQueue.main.async {
                        self.people[uid] = profile
                    }
                }

            usersListeners[uid] = l
        }
    }

    private func stop() {
        signupsListener?.remove()
        signupsListener = nil

        usersListeners.values.forEach { $0.remove() }
        usersListeners.removeAll()

        // ❌ DO NOT clear uids or people here
    }
}

struct UserProfile {
    let uid: String
    let name: String
    let email: String
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
