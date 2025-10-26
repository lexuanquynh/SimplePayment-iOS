//
//  ProfileView.swift
//  SimplePayment
//
//  User profile screen
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        NavigationView {
            List {
                // User info section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                            .overlay {
                                Text(initials)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(authViewModel.currentUser?.name ?? "User")
                                .font(.headline)

                            Text(authViewModel.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Settings section
                Section("Settings") {
                    NavigationLink {
                        Text("Account Settings")
                    } label: {
                        Label("Account Settings", systemImage: "person.circle")
                    }

                    NavigationLink {
                        Text("Security")
                    } label: {
                        Label("Security", systemImage: "lock.shield")
                    }

                    NavigationLink {
                        Text("Notifications")
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                }

                // App info section
                Section("App Info") {
                    HStack {
                        Label("Network Status", systemImage: "wifi")
                        Spacer()
                        Text(networkMonitor.connectionType.description)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }

                // Logout section
                Section {
                    Button(role: .destructive) {
                        authViewModel.logout()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private var initials: String {
        guard let name = authViewModel.currentUser?.name else {
            return "U"
        }

        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first?.uppercased() ?? ""
        let lastInitial = components.count > 1 ? components.last?.first?.uppercased() ?? "" : ""

        return "\(firstInitial)\(lastInitial)"
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
        .environmentObject(NetworkMonitor.shared)
}
