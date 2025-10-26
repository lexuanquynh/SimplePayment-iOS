//
//  LoginView.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Login form
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        VStack(spacing: 20) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)

                TextField("Enter your email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }
            }

            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)

                SecureField("Enter your password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        login()
                    }
            }

            // Error message
            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Login button
            Button {
                login()
            } label: {
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Log In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isValid ? Color.blue : Color.gray)
            .foregroundStyle(.white)
            .cornerRadius(12)
            .disabled(!isValid || authViewModel.isLoading)
            .padding(.top, 8)
        }
    }

    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }

    private func login() {
        Task {
            await authViewModel.login(email: email, password: password)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
        .padding()
}
