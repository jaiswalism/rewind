import SwiftUI
import Supabase
import PhotosUI

// MARK: - Personal Information View

struct PersonalInformationView: View {
    
    // MARK: - Dependencies
    var onBack: () -> Void = {}
    
    // MARK: - State
    @StateObject private var userViewModel = UserViewModel.shared
    @State private var profileImage: UIImage?
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var age: String = ""
    @State private var passwordPlaceholder: String = "••••••••"
    
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    
    @State private var isSaving = false
    @State private var showSuccessAlert = false
    @State private var errorAlertMessage: String?
    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .top) {
            EliteBackgroundView()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                navBar
                    .padding(.top, 60) // accommodate safe area
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .zIndex(10)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        avatarSection
                            .padding(.top, 20)
                        
                        formSection
                        
                        saveButton
                        
                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .task {
            await loadData()
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                    await MainActor.run { profileImage = uiImage }
                }
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Profile updated successfully.")
        }
        .alert("Error", isPresented: .init(
            get: { errorAlertMessage != nil },
            set: { if !$0 { errorAlertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorAlertMessage ?? "")
        }
    }
    
    // MARK: - Subviews
    
    private var navBar: some View {
        HStack {
            Button(action: onBack) {
                Group {
                    if #available(iOS 26, *) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular.interactive(), in: .circle)
                    } else {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .background(.regularMaterial, in: Circle())
                    }
                }
                .overlay(Circle().stroke(Color.secondary.opacity(0.15), lineWidth: 0.5))
            }
            
            Spacer()
            
            Text("Personal Info")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
                .offset(x: -22) // center offset compensation
            
            Spacer()
        }
    }
    
    private var avatarSection: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .stroke(Color.eliteAccentPrimary.opacity(0.35), lineWidth: 2)
                    .frame(width: 140, height: 140)
                
                if let img = profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.eliteAccentPrimary.opacity(0.15))
                        .frame(width: 130, height: 130)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 65))
                                .foregroundStyle(Color.eliteAccentPrimary.opacity(0.6))
                        )
                }
            }
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.eliteAccentPrimary, in: Circle())
                    .overlay(Circle().stroke(Color.eliteBackground, lineWidth: 3))
            }
            .offset(x: -4, y: -4)
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 24) {
            formField(title: "Full Name", icon: "person.fill", text: $name)
            formField(title: "Email Address", icon: "envelope.fill", text: $email, isDisabled: true)
            formField(title: "Age", icon: "person.text.rectangle", text: $age, isNumber: true)
        }
    }
    
    private func formField(title: String, icon: String, text: Binding<String>, isDisabled: Bool = false, isNumber: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.eliteAccentPrimary)
                    .frame(width: 24)
                
                TextField(title, text: text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
                    .disabled(isDisabled)
                    .opacity(isDisabled ? 0.6 : 1.0)
                    .keyboardType(isNumber ? .numberPad : .default)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
            )
        }
    }
    
    private var saveButton: some View {
        Button(action: saveChanges) {
            if isSaving {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(height: 24)
            } else {
                Text("Save Changes")
            }
        }
        .buttonStyle(ElitePrimaryButtonStyle())
        .disabled(isSaving)
    }
    
    // MARK: - Logic
    
    private func loadData() async {
        await userViewModel.fetchProfile()
        if let user = userViewModel.user {
            await MainActor.run {
                name = user.name ?? ""
                email = user.email ?? ""
                if let userAge = user.age {
                    age = String(userAge)
                } else {
                    age = ""
                }
            }
            
            if let urlString = user.profileImageUrl,
               let url = URL(string: urlString),
               let (data, _) = try? await URLSession.shared.data(from: url),
               let image = UIImage(data: data) {
                await MainActor.run { profileImage = image }
            }
        }
    }
    
    private func saveChanges() {
        guard !isSaving else { return }
        isSaving = true
        
        Task {
            do {
                if let item = selectedItem,
                   let data = try await item.loadTransferable(type: Data.self) {
                    _ = try await userViewModel.uploadAvatar(imageData: data)
                }
                
                try await userViewModel.updateProfile(
                    name: name,
                    location: userViewModel.user?.location,
                    age: Int(age)
                )
                
                await MainActor.run {
                    isSaving = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorAlertMessage = error.localizedDescription
                }
            }
        }
    }
}
