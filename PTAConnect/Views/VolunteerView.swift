//
//  VolunteerView.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//


import SwiftUI
import Combine
import FirebaseFirestore

struct VolunteerView: View {
    @StateObject private var vm = VolunteerEventsVM()

    var body: some View {
        NavigationStack {
            List {
                if vm.events.isEmpty {
                    Text("No upcoming events yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(vm.events) { e in
                        NavigationLink {
                            VolunteerTasksView(event: e)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(e.title).font(.headline)
                                Text(vm.dateString(e.startAt))
                                    .foregroundStyle(.secondary)
                                if !e.location.isEmpty {
                                    Text(e.location)
                                        .font(.footnote)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Volunteer")
            .onAppear { vm.start() }
            .onDisappear { vm.stop() }
        }
    }
}

final class VolunteerEventsVM: ObservableObject {
    @Published var events: [PTAEvent] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func start() {
        if listener != nil { return }
        listener = db.collection("events")
            .order(by: "startAt", descending: false)
            .addSnapshotListener { [weak self] snap, _ in
                let items = snap?.documents.compactMap { PTAEvent(doc: $0) } ?? []
                DispatchQueue.main.async { self?.events = items }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
