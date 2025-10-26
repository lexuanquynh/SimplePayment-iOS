//
//  MainTabView.swift
//  SimplePayment
//
//  Main tab navigation
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            TransactionHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(NetworkMonitor.shared)
}
