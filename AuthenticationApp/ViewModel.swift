//
//  ViewModel.swift
//  AuthenticationApp
//
//  Created by Jonathan Sack on 3/17/22.
//

import Foundation
import Resolver
import FirebaseAuth

enum ValidationError: LocalizedError {
    case emailRequired
    case invalidEmail
    case invalidPassword
    
    var errorDescription: String {
        switch self {
        case .emailRequired:
            return "Email address is required"
        case .invalidEmail:
            return "Email must be valid"
        case .invalidPassword:
            return "Your password is inavlid"
        }
    }
}

/*
 Regarding the `Validation Service` we can make use of protocols here to inject the dependency
 We'll have a `ValidationProtcol` instead of `ValidationService`.
 In a separate module we'll now be able to do all sorts of validations.
 */

//struct ValidationService {
//    func validateEmail(_ email: String?) throws-> String {
//        guard let email = email else {
//            throw ValidationError.emailRequired
//        }
//        // Verify email with regex for invalidemail error
//        return email
//    }
//    func validatePassword(_ password: String?) throws-> String {
//        guard let password = password else {
//            throw ValidationError.invalidPassword
//        }
//        // More password verification
//        return password
//    }
//}

protocol ValidationProtocol {
    func validate(email: String?) throws -> String
    func validate(password: String?) throws -> String
}

protocol LoginService {
    func saveToDatabase(_ user: User)
}

// MARK: - ViewModel
class ViewModel {

    // MARK: - Dependencies
    @Injected private var validation: ValidationProtocol
    @Injected private var service: LoginService
    private let auth = Auth.auth()

    // MARK: - Sign In
    public func signIn(email: String?, password: String?, completion: @escaping (Result<Bool, Error>) -> ()) {

        do {
            // Validate inputs
            let email = try validation.validate(email: email)
            let password = try validation.validate(password: password)

            // Authentication
            auth.signIn(withEmail: email, password: password) { [weak self] authResult, error in
                
                guard let weakSelf = self else {
                    // Pass it default failure case
                    var systemError: Error!
                    completion(.failure(systemError))
                    return
                }
                
                // Handle error
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // User signed in
                guard let userEmail = self?.auth.currentUser?.email,
                      let username = self?.auth.currentUser?.displayName,
                      let uid = self?.auth.currentUser?.uid
                else { return }
                print("\(username) signed in with \(userEmail) and id of \(uid)")
                // Save to Firestore with UID as key
                
                // Format to `User` model
                var user: User!
                
                // Then save to DB
                weakSelf.service.saveToDatabase(user)
            }

        } catch {
            completion(.failure(error))
        }

    }
}
