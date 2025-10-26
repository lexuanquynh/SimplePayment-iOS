//
//  TransactionError.swift
//  SimplePayment
//
//  Transaction-related errors
//

import Foundation

enum TransactionError: LocalizedError {
    case featureRestricted(reason: String)
    case insufficientBalance
    case invalidAmount
    case invalidRecipient
    case networkError(Error)
    case serverError(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .featureRestricted(let reason):
            return reason
        case .insufficientBalance:
            return "Insufficient balance to complete this transaction."
        case .invalidAmount:
            return "Invalid transaction amount."
        case .invalidRecipient:
            return "Invalid recipient information."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .featureRestricted:
            return "This feature is restricted for security reasons. Please use a non-jailbroken device to access all features."
        case .insufficientBalance:
            return "Please add funds to your wallet before sending money."
        case .invalidAmount:
            return "Please enter a valid amount greater than zero."
        case .invalidRecipient:
            return "Please verify the recipient information and try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .serverError:
            return "Please try again later or contact support if the problem persists."
        case .unknownError:
            return "Please try again or contact support if the problem persists."
        }
    }
}
