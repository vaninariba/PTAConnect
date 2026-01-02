import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }
            Text("PTA Updates")
                .tabItem { Label("PTAUpdates", systemImage: "house") }

            EventsView()
                .tabItem { Label("Events", systemImage: "calendar") }


            VolunteerView()
                .tabItem { Label("Volunteer", systemImage: "person.3") }


            Text("Messages & Alerts")
                .tabItem { Label("Messages", systemImage: "bell") }
        

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }

        }
    }
}

#Preview {
    MainTabView()
}

