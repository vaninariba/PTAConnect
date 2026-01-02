import SwiftUI
import Combine
import FirebaseFirestore

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()

    var body: some View {
        NavigationStack {
            List {
                if vm.announcements.isEmpty {
                    Text("No announcements yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.announcements) { a in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(a.title).font(.headline)
                            Text(a.message)
                                .foregroundStyle(.secondary)
                            Text(vm.dateString(a.createdAt))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("PTA Updates")
            .toolbar {
                if vm.isAdmin {
                    Button {
                        vm.showNewAnnouncement = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $vm.showNewAnnouncement) {
                NewAnnouncementView { title, message in
                    Task { await vm.createAnnouncement(title: title, message: message) }
                }
            }
            .onAppear { vm.start() }
            .onDisappear { vm.stop() }
            .alert("Error", isPresented: $vm.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(vm.errorMessage ?? "Unknown error")
            }
        }
    }
}

final class HomeViewModel: ObservableObject {
    @Published var announcements: [Announcement] = []
    @Published var isAdmin: Bool = false
    @Published var showNewAnnouncement: Bool = false
    @Published var showError: Bool = false

    var errorMessage: String?

    private let service = AnnouncementService()
    private var listener: ListenerRegistration? = nil

    func start() {
        if listener != nil { return }

        listener = service.listenAnnouncements { [weak self] items in
            DispatchQueue.main.async {
                self?.announcements = items
            }
        }

        Task {
            do {
                let role = try await service.fetchCurrentUserRole()
                await MainActor.run {
                    self.isAdmin = (role.lowercased() == "admin")
                }
            } catch {
                await MainActor.run { self.isAdmin = false }
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func createAnnouncement(title: String, message: String) async {
        do {
            try await service.postAnnouncement(title: title, message: message)
            await MainActor.run { self.showNewAnnouncement = false }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }

    func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

struct NewAnnouncementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var message = ""

    let onPost: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g., Spirit Wear Pickup", text: $title)
                }
                Section("Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 140)
                }
            }
            .navigationTitle("New Announcement")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        onPost(title.trimmingCharacters(in: .whitespacesAndNewlines),
                               message.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
