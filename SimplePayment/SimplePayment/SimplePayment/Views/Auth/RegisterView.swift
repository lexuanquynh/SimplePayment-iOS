//
//  RegisterView.swift
//  SimplePayment
//
//  Registration form
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case name, email, phone, password, confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Enter your full name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }
                }

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
                        .onSubmit { focusedField = .phone }
                }

                // Phone field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextField("Enter your phone", text: $phone)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .focused($focusedField, equals: .phone)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }

                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    SecureField("Create a password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirmPassword }
                }

                // Confirm password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    SecureField("Confirm your password", text: $confirmPassword)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.go)
                        .onSubmit { register() }
                }

                // Error message
                if let error = authViewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Register button
                Button {
                    register()
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
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
    }

    private var isValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        !phone.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword
    }

    private func register() {
        Task {
            await authViewModel.register(
                name: name,
                email: email,
                phone: phone,
                password: password
            )
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthViewModel())
        .padding()
}
