//
// ViewController.swift
// AuthenticationApp
//
// Created by Musoni nshuti Nicolas on 16/03/2022
// Copyright © 2022 GHOST TECHNOLOGIES LLC. All rights reserved.
//


import UIKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import FacebookLogin

struct User {
    var id: String
    var firtname: String?
    var lastname: String?
    var email: String?
}
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

struct ValidationService {
    func validateEmail(_ email: String?) throws-> String {
        guard let email = email else {
            throw ValidationError.emailRequired
        }
        // Verify email with regex for invalidemail error
        return email
    }
    func validatePassword(_ password: String?) throws-> String {
        guard let password = password else {
            throw ValidationError.invalidPassword
        }
        // More password verification
        return password
    }
}

class ViewController: UIViewController {
    
    let auth = Auth.auth()
    // Google
    let googleBtn = GIDSignInButton()
    // Apple
    let appleBtn = ASAuthorizationAppleIDButton()
    fileprivate var currentNonce: String?
    // Email and password
    let emailText = UITextField()
    let passwordText = UITextField()
    let validation = ValidationService()
    // facebook
    let loginButton = FBLoginButton()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGreen
        view.addSubview(googleBtn)
        view.addSubview(appleBtn)
        view.addSubview(loginButton)
        
        googleBtn.addTarget(self, action: #selector(googleSignIn), for: .touchUpInside)
        googleBtn.translatesAutoresizingMaskIntoConstraints = false
        googleBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        googleBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        appleBtn.addTarget(self, action: #selector(appleSignIn), for: .touchUpInside)
        appleBtn.translatesAutoresizingMaskIntoConstraints = false
        appleBtn.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 60).isActive = true
        appleBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(appleSignIn), for: .touchUpInside)
        loginButton.topAnchor.constraint(equalTo: appleBtn.bottomAnchor, constant: 20).isActive = true
        loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 60).isActive = true
//        appleBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
}
// MARK: - Google SignIn
extension ViewController {
    // MARK: - Google Sign in
    @objc func googleSignIn() {
        print("Google login")
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let authentication = user?.authentication, let idToken = authentication.idToken else {
                return
            }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
            
            auth.signIn(with: credential) { authResult, error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                guard let userResult = authResult?.user else {
                    print("Unauthenticated")
                    return
                }
                print(userResult)
                let vc = SecondVC()
                vc.modalPresentationStyle = .fullScreen
                present(vc, animated: true, completion: nil)
            }
        }
    }
}

extension ViewController {
    // MARK: - Apple Sign in
    @objc func appleSignIn() {
        let request = createAppleIDRequest()
        let authController = ASAuthorizationController(authorizationRequests: [request])
        
        authController.delegate = self
        authController.presentationContextProvider = self
        
        authController.performRequests()
    }
    private func createAppleIDRequest() -> ASAuthorizationAppleIDRequest {
        let appleProvider = ASAuthorizationAppleIDProvider()
        let request = appleProvider.createRequest()
        request.requestedScopes = [.email, .fullName]
        
        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
        currentNonce = nonce
        return request
    }
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    @available(iOS 13, *)
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
}

extension ViewController: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            // Sign in with Firebase.
            auth.signIn(with: credential) { (authResult, error) in
                if error != nil {
                    // Error. If error.code == .MissingOrInvalidNonce, make sure
                    // you're sending the SHA256-hashed nonce as a hex string with
                    // your request to Apple.
                    print(error!.localizedDescription)
                    return
                }
                print("success")
            }
        }
    }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error)
    }
}

extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }
}

extension ViewController {
    // MARK: - Email Sign in
    @objc func signInWithEmail(email: String, password: String) {
        // Verify email and password
        do {
            let email = try validation.validateEmail(emailText.text)
            let password = try validation.validatePassword(passwordText.text)
            
            auth.signIn(withEmail: email, password: password) { [weak self] authResult, error in
                if let error = error {
                    print(error)
                    return
                }
                // User signed in
                guard let userEmail = self?.auth.currentUser?.email, let username = self?.auth.currentUser?.displayName, let uid = self?.auth.currentUser?.uid else {
                    return
                }
                print("\(username) signed in with \(userEmail) and id of \(uid)")
                // Save to Firestore with UID as key
            }
        } catch let error as NSError {
            print(error)
        }
    }
}

extension ViewController {
    // MARK: - Facebook sign in
    
}



class SecondVC: UIViewController {
    let button = UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemTeal
        view.addSubview(button)
        button.setTitle("Sign out", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(signOut), for: .touchUpInside)
        button.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        button.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }
    // MARK: - Sign Out
    @objc func signOut() {
        do {
            try Auth.auth().signOut()
            dismiss(animated: true, completion: nil)
        } catch let error as NSError {
            print(error)
        }
    }
}

