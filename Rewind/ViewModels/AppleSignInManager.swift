import AuthenticationServices
import CryptoKit
import Supabase
import Foundation
import Combine

class AppleSignInManager: NSObject, ObservableObject {
    var onCompletion: ((Result<(idToken: String, nonce: String, fullName: String?), Error>) -> Void)?
    private var currentNonce: String?

    // Returns a cryptographically secure random string
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { charset[Int($0) % charset.count] }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }

    func startSignInWithAppleFlow(completion: @escaping (Result<(idToken: String, nonce: String, fullName: String?), Error>) -> Void) {
        self.onCompletion = completion
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension AppleSignInManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let _ = currentNonce else {
                onCompletion?(.failure(NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid state: A login callback was received, but no login request was sent."])))
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                onCompletion?(.failure(NSError(domain: "AppleSignIn", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])))
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                onCompletion?(.failure(NSError(domain: "AppleSignIn", code: -3, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string from data"])))
                return
            }

            // Extract Name (Apple only provides this on the very first ever login)
            var extractedName: String? = nil
            if let nameComponents = appleIDCredential.fullName {
                let first = nameComponents.givenName ?? ""
                let last = nameComponents.familyName ?? ""
                let combined = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
                if !combined.isEmpty {
                    extractedName = combined
                }
            }
            
            // We only need the idToken. Supabase handles the rest!
            onCompletion?(.success((idToken: idTokenString, nonce: currentNonce!, fullName: extractedName)))
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onCompletion?(.failure(error))
    }
}

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene ?? scenes.first as? UIWindowScene
        
        if let scene = windowScene {
            return scene.windows.first { $0.isKeyWindow } ?? UIWindow(windowScene: scene)
        }
        
        // Last resort/fallback for non-scene contexts or initialization failures
        return UIWindow(frame: .zero)
    }
}
