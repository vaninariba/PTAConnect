import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class VolunteerTasksVM: ObservableObject {

    // MARK: - UI State
    @Published var tasks: [VolunteerTask] = []
    @Published var isAdmin: Bool = false
    @Published var showNewTask: Bool = false

    @Published var showError: Bool = false
    @Published var errorMessage: String?

    @Published var showConfirmation: Bool = false
    @Published var confirmationMessage: String = ""

    @Published var isLoading: Bool = true   // 🔑 prevents “everything disappeared”

    // MARK: - Private
    private let eventId: String
    private let service = VolunteerService()
    private let roleService = EventService()

    private var tasksListener: ListenerRegistration?
    private var signupListeners: [String: ListenerRegistration] = [:]

    // IMPORTANT: never clear this during navigation
    private var signupUIDsByTask: [String: Set<String>] = [:]

    // MARK: - Init
    init(eventId: String) {
        self.eventId = eventId
    }

    // MARK: - Lifecycle
    func start() {
        if tasksListener != nil { return }

        isLoading = true

        tasksListener = service.listenTasks(eventId: eventId) { [weak self] items in
            guard let self else { return }
            self.tasks = items
            self.ensureSignupListeners(for: items)
            self.isLoading = false
        }

        Task {
            do {
                let role = try await roleService.fetchCurrentUserRole()
                self.isAdmin = (role.lowercased() == "admin")
            } catch {
                self.isAdmin = false
            }
        }
    }

    // MARK: - Helpers
    func isSignedUp(taskId: String) -> Bool {
        guard let uid = Auth.auth().currentUser?.uid else { return false }
        return signupUIDsByTask[taskId]?.contains(uid) ?? false
    }

    func myTasks() -> [VolunteerTask] {
        tasks.filter { isSignedUp(taskId: $0.id) }
    }

    func eventWhenWhere(event: PTAEvent) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        let when = "\(f.string(from: event.startAt)) – \(f.string(from: event.endAt))"
        return event.location.isEmpty ? when : "\(when) • \(event.location)"
    }

    // MARK: - Actions
    func signUp(taskId: String) async {
        do {
            try await service.signUp(eventId: eventId, taskId: taskId)
            confirmationMessage = "You're signed up! Thank you for volunteering 🙌"
            showConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func cancel(taskId: String) async {
        do {
            try await service.cancel(eventId: eventId, taskId: taskId)
            confirmationMessage = "Your signup was removed."
            showConfirmation = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    func createTask(title: String, details: String, slots: Int) async {
        do {
            try await service.createTask(
                eventId: eventId,
                title: title,
                details: details,
                slots: slots
            )
            showNewTask = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Signup listeners (CRITICAL FIX)
    private func ensureSignupListeners(for tasks: [VolunteerTask]) {
        let activeTaskIDs = Set(tasks.map { $0.id })

        // Remove listeners ONLY (do NOT delete signup data)
        for (taskId, listener) in signupListeners where !activeTaskIDs.contains(taskId) {
            listener.remove()
            signupListeners.removeValue(forKey: taskId)
            // ❌ DO NOT remove signupUIDsByTask[taskId]
        }

        // Add listeners for new tasks
        for task in tasks where signupListeners[task.id] == nil {
            let listener = service.listenSignups(
                eventId: eventId,
                taskId: task.id
            ) { [weak self] uids in
                guard let self else { return }
                self.signupUIDsByTask[task.id] = uids   // ✅ overwrite only when Firestore sends data
            }

            signupListeners[task.id] = listener
        }
    }
}

