//
//  AuthenticationView.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Main authentication screen
//

import SwiftUI

struct AuthenticationView: View {
    @State private var isLoginMode = true

    var body: some View {
        VStack(spacing: 0) {
            // Logo and title
            VStack(spacing: 16) {
                Image(systemName: "dollarsign.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue)

                Text("SimplePayment")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(isLoginMode ? "Welcome back!" : "Create your account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)

            // Auth form
            if isLoginMode {
                LoginView()
            } else {
                RegisterView()
            }

            Spacer()

            // Toggle mode
            Button {
                withAnimation {
                    isLoginMode.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                        .foregroundStyle(.secondary)
                    Text(isLoginMode ? "Sign Up" : "Log In")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthViewModel())
}
