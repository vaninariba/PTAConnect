//
//  LoginView.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/26/25.
//


import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthService

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isCreatingAccount = false

    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                Text("PTA Connect")
                    .font(.largeTitle).bold()

                if isCreatingAccount {
                    TextField("Full name", text: $name)
                        .textContentType(.name)
                        .disableAutocorrection(true)
                        .textFieldStyle(.roundedBorder)

                }

                UIKitTextField(
                    text: $email,
                    placeholder: "Email",
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalizationType: .none,
                    autocorrectionType: .no,
                    isSecure: false
                )


                UIKitTextField(
                    text: $password,
                    placeholder: "Password",
                    keyboardType: .default,
                    textContentType: .password,
                    autocapitalizationType: .none,
                    autocorrectionType: .no,
                    isSecure: true
                )

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await submit() }
                } label: {
                    Text(isCreatingAccount ? "Create account" : "Sign in")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || email.isEmpty || password.isEmpty || (isCreatingAccount && name.isEmpty))

                Button {
                    isCreatingAccount.toggle()
                    errorMessage = nil
                } label: {
                    Text(isCreatingAccount ? "Already have an account? Sign in" : "New here? Create an account")
                        .font(.footnote)
                }

                Spacer()
            }
            .padding()
        }
    }

    private func submit() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            if isCreatingAccount {
                try await auth.signUp(name: name, email: email, password: password)
            } else {
                try await auth.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = friendly(error)
        }
    }

    private func friendly(_ error: Error) -> String {
        let msg = (error as NSError).localizedDescription
        // Keep it simple for now
        return msg
    }
}
