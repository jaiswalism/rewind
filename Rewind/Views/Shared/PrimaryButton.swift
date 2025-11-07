//
//  PrimaryButton.swift
//  Rewind
//
//  Created by Shyam on 06/11/25.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("baseBlue")) // Uses your app's color
            .cornerRadius(16)
    }
}

#Preview {
    PrimaryButton(title: "Create account")
        .padding()
}
