//
//  NewVolunteerTaskView.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//


import SwiftUI

struct NewVolunteerTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var details = ""
    @State private var slotsText = "4"

    let onCreate: (String, String, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("e.g., Face Painting", text: $title)
                    TextField("Details (optional)", text: $details)
                }

                Section("Slots") {
                    TextField("Number of volunteers needed", text: $slotsText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("New Volunteer Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        let d = details.trimmingCharacters(in: .whitespacesAndNewlines)
                        let s = max(1, Int(slotsText) ?? 1)
                        onCreate(t, d, s)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
