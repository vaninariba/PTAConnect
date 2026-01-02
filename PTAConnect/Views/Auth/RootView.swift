//
//  RootView.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/26/25.
//


import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthService

    var body: some View {
        if auth.user == nil {
            LoginView()
        } else {
            MainTabView()
        }
    }
}
