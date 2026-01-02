//
//  ProfileView.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/26/25.
//


import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var auth: AuthService
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(Auth.auth().currentUser?.email ?? "—")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    HStack {
                        Text("User ID")
                        Spacer()
                        Text(Auth.auth().currentUser?.uid ?? "—")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        do {
                            try auth.signOut()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}
