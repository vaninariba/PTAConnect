//
//  EventsView.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//


import SwiftUI
import Combine
import FirebaseFirestore

struct EventsView: View {
    @StateObject private var vm = EventsViewModel()

    var body: some View {
        NavigationStack {
            List {
                if vm.events.isEmpty {
                    Text("No events yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.events) { event in
                        NavigationLink {
                            EventDetailView(event: event)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(event.title).font(.headline)
                                Text(vm.dateRangeString(start: event.startAt, end: event.endAt))
                                    .foregroundStyle(.secondary)
                                if !event.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text(event.location)
                                        .font(.footnote)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Events")
            .toolbar {
                if vm.isAdmin {
                    Button { vm.showNewEvent = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $vm.showNewEvent) {
                NewEventView { title, location, details, startAt, endAt in
                    Task { await vm.createEvent(title: title, location: location, details: details, startAt: startAt, endAt: endAt) }
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

final class EventsViewModel: ObservableObject {
    @Published var events: [PTAEvent] = []
    @Published var isAdmin: Bool = false
    @Published var showNewEvent: Bool = false
    @Published var showError: Bool = false
    var errorMessage: String?

    private let service = EventService()
    private var listener: ListenerRegistration? = nil

    func start() {
        if listener != nil { return }

        listener = service.listenEvents { [weak self] items in
            DispatchQueue.main.async {
                self?.events = items
            }
        }

        Task {
            do {
                let role = try await service.fetchCurrentUserRole()
                await MainActor.run { self.isAdmin = (role.lowercased() == "admin") }
            } catch {
                await MainActor.run { self.isAdmin = false }
            }
        }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func createEvent(title: String, location: String, details: String, startAt: Date, endAt: Date) async {
        do {
            try await service.createEvent(title: title, location: location, details: details, startAt: startAt, endAt: endAt)
            await MainActor.run { self.showNewEvent = false }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }

    func dateRangeString(start: Date, end: Date) -> String {
        let d = DateFormatter()
        d.dateStyle = .medium
        d.timeStyle = .short
        return "\(d.string(from: start)) – \(d.string(from: end))"
    }
}
