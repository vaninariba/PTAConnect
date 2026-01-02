//
//  EventDetailView.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//


import SwiftUI
import Combine

struct EventDetailView: View {
    let event: PTAEvent
    @StateObject private var vm: EventDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(event: PTAEvent) {
        self.event = event
        _vm = StateObject(wrappedValue: EventDetailViewModel(event: event))
    }

    var body: some View {
        List {
            Section("When") {
                Text(dateRangeString(start: event.startAt, end: event.endAt))
            }

            if !event.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Where") {
                    Text(event.location)
                }
            }

            if !event.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Details") {
                    Text(event.details)
                }
            }

            Section {
                AddToCalendarButton(title: event.title,
                                    location: event.location,
                                    notes: event.details,
                                    startDate: event.startAt,
                                    endDate: event.endAt)
            }
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if vm.isAdmin {
                Button(role: .destructive) {
                    vm.showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .alert("Delete Event?", isPresented: $vm.showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    if await vm.deleteEvent() {
                        dismiss()
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .alert("Error", isPresented: $vm.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "Unknown error")
        }
        .onAppear { vm.start() }
    }

    private func dateRangeString(start: Date, end: Date) -> String {
        let d = DateFormatter()
        d.dateStyle = .medium
        d.timeStyle = .short
        return "\(d.string(from: start)) – \(d.string(from: end))"
    }
}

final class EventDetailViewModel: ObservableObject {
    @Published var isAdmin: Bool = false
    @Published var showDeleteConfirmation: Bool = false
    @Published var showError: Bool = false
    var errorMessage: String?

    private let event: PTAEvent
    private let service = EventService()

    init(event: PTAEvent) {
        self.event = event
    }

    func start() {
        Task {
            do {
                let role = try await service.fetchCurrentUserRole()
                await MainActor.run { self.isAdmin = (role.lowercased() == "admin") }
            } catch {
                await MainActor.run { self.isAdmin = false }
            }
        }
    }

    func deleteEvent() async -> Bool {
        do {
            try await service.deleteEvent(eventId: event.id)
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
            return false
        }
    }
}
