//
//  LogInViewController.swift
//  SignInWithAppleDemo
//
//  Created by Vineet Choudhary on 05/06/19.
//  Copyright © 2019 Developer Insider. All rights reserved.
//

import UIKit
import AuthenticationServices

class LogInViewController: UIViewController {

    @IBOutlet weak private var loginProviderStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLoginProviderView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        performExistingAccountSetupFlows()
    }
    
    private func setupLoginProviderView() {
        // Set button style based on device theme
        let isDarkTheme = view.traitCollection.userInterfaceStyle == .dark
        let style: ASAuthorizationAppleIDButton.Style = isDarkTheme ? .white : .black
        
        // Create and Setup Apple ID Authorization Button
        let authorizationButton = ASAuthorizationAppleIDButton(type: .default, style: style)
        authorizationButton.addTarget(self, action: #selector(handleLogInWithAppleIDButtonPress), for: .touchUpInside)
        
        // Add Height Constraint
        let heightConstraint = authorizationButton.heightAnchor.constraint(equalToConstant: 44)
        authorizationButton.addConstraint(heightConstraint)
        
        //Add Apple ID authorization button into the stack view
        loginProviderStackView.addArrangedSubview(authorizationButton)
    }
    
    private func performExistingAccountSetupFlows() {
        // Prepare requests for both Apple ID and password providers.
        let requests = [ASAuthorizationAppleIDProvider().createRequest(), ASAuthorizationPasswordProvider().createRequest()]
        
        // Create an authorization controller with the given requests.
        let authorizationController = ASAuthorizationController(authorizationRequests: requests)
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    @objc private func handleLogInWithAppleIDButtonPress() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension LogInViewController : ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            // Create an account in your system.
            // For the purpose of this demo app, store the these details in the keychain.
            KeychainItem.currentUserIdentifier = appleIDCredential.user
            KeychainItem.currentUserFirstName = appleIDCredential.fullName?.givenName
            KeychainItem.currentUserLastName = appleIDCredential.fullName?.familyName
            KeychainItem.currentUserEmail = appleIDCredential.email
            
            print("User Id - \(appleIDCredential.user)")
            print("User Name - \(appleIDCredential.fullName?.description ?? "N/A")")
            print("User Email - \(appleIDCredential.email ?? "N/A")")
            print("Real User Status - \(appleIDCredential.realUserStatus.rawValue)")
            
            if let identityTokenData = appleIDCredential.identityToken,
                let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
                print("Identity Token \(identityTokenString)")
            }
            
            //Show Home View Controller
            HomeViewController.Push()
        } else if let passwordCredential = authorization.credential as? ASPasswordCredential {
            // Sign in using an existing iCloud Keychain credential.
            let username = passwordCredential.user
            let password = passwordCredential.password
            
            // For the purpose of this demo app, show the password credential as an alert.
            DispatchQueue.main.async {
                let message = "The app has received your selected credential from the keychain. \n\n Username: \(username)\n Password: \(password)"
                let alertController = UIAlertController(title: "Keychain Credential Received",
                                                        message: message,
                                                        preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
}

extension LogInViewController : ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
