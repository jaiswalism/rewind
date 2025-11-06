//
//  SocialLoginButton.swift
//  Rewind
//
//  Created by Shyam on 06/11/25.
//

import SwiftUI

struct SocialLoginButton: View {
    let imageName: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(imageName) // You'll need to add "google" and "apple" icons to Assets
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(Color("baseBlue")) // Uses your app's color
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VStack {
        SocialLoginButton(imageName: "googleLogo", title: "Continue with Google")
        SocialLoginButton(imageName: "appleLogo", title: "Continue with Apple")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
