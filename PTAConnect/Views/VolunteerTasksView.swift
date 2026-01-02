import SwiftUI

struct VolunteerTasksView: View {

    let event: PTAEvent
    @StateObject private var vm: VolunteerTasksVM

    init(event: PTAEvent) {
        self.event = event
        _vm = StateObject(wrappedValue: VolunteerTasksVM(eventId: event.id))
    }

    var body: some View {
        List {

            // Event header
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)

                    Text(vm.eventWhenWhere(event: event))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }

            // My Sign-ups
            let my = vm.myTasks()
            if !my.isEmpty {
                Section("My Sign-ups") {
                    ForEach(my) { task in
                        VolunteerTaskRow(
                            task: task,
                            isAdmin: vm.isAdmin,
                            isSignedUp: true,
                            onSignUp: { },
                            onCancel: { Task { await vm.cancel(taskId: task.id) } },
                            onViewPeople: {
                                SignupListView(eventId: event.id, taskId: task.id)
                            }
                        )
                    }
                }
            }

            // All Tasks
            Section("All Tasks") {

                if vm.isLoading {
                    ProgressView("Loading tasks…")
                }
                else if vm.tasks.isEmpty {
                    Text("No volunteer sign-ups yet.")
                        .foregroundStyle(.secondary)
                }
                else {
                    ForEach(vm.tasks) { task in
                        VolunteerTaskRow(
                            task: task,
                            isAdmin: vm.isAdmin,
                            isSignedUp: vm.isSignedUp(taskId: task.id),
                            onSignUp: { Task { await vm.signUp(taskId: task.id) } },
                            onCancel: { Task { await vm.cancel(taskId: task.id) } },
                            onViewPeople: {
                                SignupListView(eventId: event.id, taskId: task.id)
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle("Volunteer Sign-Ups")
        .toolbar {
            if vm.isAdmin {
                Button {
                    vm.showNewTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $vm.showNewTask) {
            NewVolunteerTaskView { title, details, slots in
                Task { await vm.createTask(title: title, details: details, slots: slots) }
            }
        }
        .onAppear { vm.start() }
        // DO NOT stop on disappear — SwiftUI triggers it when navigating
        //.onDisappear { vm.stop() }

        .alert("Done", isPresented: $vm.showConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.confirmationMessage)
        }
        .alert("Error", isPresented: $vm.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "Unknown error")
        }
    }
}

private struct VolunteerTaskRow<PeopleView: View>: View {

    let task: VolunteerTask
    let isAdmin: Bool
    let isSignedUp: Bool

    let onSignUp: () -> Void
    let onCancel: () -> Void
    let onViewPeople: () -> PeopleView

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Title + badge
            HStack(spacing: 8) {
                Text(task.title)
                    .font(.headline)

                if isSignedUp {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Signed up")
                    }
                    .font(.caption)
                    .foregroundStyle(.green)
                }
            }

            // details
            if !task.details.isEmpty {
                Text(task.details)
                    .foregroundStyle(.secondary)
            }

            // slots filled (safe with your model)
            Text("\(task.filledCount)/\(task.slots) filled")
                .font(.caption)
                .foregroundStyle(.tertiary)

            HStack {

                if isSignedUp {
                    Button(role: .destructive) {
                        onCancel()     // SAFE — no direct vm call
                    } label: {
                        Text("Cancel")
                    }

                } else {
                    Button {
                        onSignUp()     // SAFE
                    } label: {
                        Text("Sign up")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(task.filledCount >= task.slots)
                }

                Spacer()

                if isAdmin {
                    NavigationLink("View people") {
                        onViewPeople() // SAFE — DON’T CALL vm HERE
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

