//
//  NewEventView.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//


import SwiftUI

struct NewEventView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var location = ""
    @State private var details = ""
    @State private var startAt = Date()
    @State private var endAt = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()

    let onCreate: (String, String, String, Date, Date) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("e.g., PTA Meeting", text: $title)
                }

                Section("Location") {
                    TextField("e.g., Library", text: $location)
                }

                Section("When") {
                    DatePicker("Start", selection: $startAt, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End", selection: $endAt, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Details") {
                    TextEditor(text: $details)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(
                            title.trimmingCharacters(in: .whitespacesAndNewlines),
                            location.trimmingCharacters(in: .whitespacesAndNewlines),
                            details.trimmingCharacters(in: .whitespacesAndNewlines),
                            startAt,
                            endAt
                        )
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || endAt <= startAt)
                }
            }
        }
    }
}
