//
//  PTAConnectApp.swift
//  PTAConnect
//
//  Created by Vanina Riba on 12/26/25.
//


import SwiftUI

@main
struct PTAConnectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var auth = AuthService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)   // ✅ THIS FIXES THE CRASH
                .onReceive(NotificationCenter.default.publisher(for: .didGetFCMToken)) { note in
                    if let token = note.object as? String {
                        Task { await PushTokenStore().saveMyToken(token) }
                    }
                }
        }
    }
}
