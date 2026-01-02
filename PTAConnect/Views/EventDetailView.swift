//
//  EventDetailView.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//


import SwiftUI

struct EventDetailView: View {
    let event: PTAEvent

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
    }

    private func dateRangeString(start: Date, end: Date) -> String {
        let d = DateFormatter()
        d.dateStyle = .medium
        d.timeStyle = .short
        return "\(d.string(from: start)) – \(d.string(from: end))"
    }
}
