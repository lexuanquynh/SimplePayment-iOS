//
//  QuickActionButton.swift
//  SimplePayment
//
//  Created by Prank on 26/10/25.
//  Quick action button component
//

import SwiftUI

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}

#Preview {
    QuickActionButton(
        title: "Send",
        icon: "arrow.up.circle.fill",
        color: .blue
    ) {}
    .padding()
}
