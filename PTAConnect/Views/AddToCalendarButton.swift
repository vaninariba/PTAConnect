//
//  AddToCalendarButton.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/27/25.
//


import SwiftUI
import EventKit

struct AddToCalendarButton: View {
    let title: String
    let location: String
    let notes: String
    let startDate: Date
    let endDate: Date

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        Button("Add to iPhone Calendar") {
            addToCalendar()
        }
        .alert("Calendar", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func addToCalendar() {
        let store = EKEventStore()

        store.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                if let error {
                    alertMessage = error.localizedDescription
                    showAlert = true
                    return
                }

                guard granted else {
                    alertMessage = "Calendar permission was not granted."
                    showAlert = true
                    return
                }

                let event = EKEvent(eventStore: store)
                event.title = title
                event.location = location
                event.notes = notes
                event.startDate = startDate
                event.endDate = endDate
                event.calendar = store.defaultCalendarForNewEvents

                do {
                    try store.save(event, span: .thisEvent)
                    alertMessage = "Added to your calendar."
                    showAlert = true
                } catch {
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}
