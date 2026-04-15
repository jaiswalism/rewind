import SwiftUI

// MARK: - Health Goal Onboarding View
struct OnboardingHealthGoalView: View {
    @Binding var currentPage: Int
    let totalPages = 4
    let goals = [
        "I wanna reduce stress",
        "I wanna try virtual pet",
        "I want to cope with trauma",
        "I want to be a better person",
        "Just trying out the app, mate!"
    ]
    
    @State private var selectedGoal: String?
    
    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width > 500
            let maxWidth: CGFloat = isIPad ? 520 : geometry.size.width - 48
            
            ZStack {
                Color("colors/Blue&Shades/blue-400")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Page indicator
                            PageIndicator(currentPage: currentPage, totalPages: totalPages)
                                .padding(.top, 20)
                            
                            // Title
                            Text("What's your health goal?")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(Color("colors/Primary/Light"))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 345)
                                .padding(.top, 30)
                            
                            // Goal buttons
                            VStack(spacing: 12) {
                                ForEach(goals, id: \.self) { goal in
                                    Button {
                                        selectedGoal = goal
                                    } label: {
                                        Text(goal)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(selectedGoal == goal ? .white : Color("colors/Blue&Shades/blue-900"))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 50)
                                            .background(
                                                Capsule()
                                                    .fill(selectedGoal == goal ? Color("colors/Blue&Shades/blue-300") : Color("colors/Primary/Light"))
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(selectedGoal == goal ? Color.white : Color.clear, lineWidth: 2)
                                            )
                                            .shadow(color: selectedGoal == goal ? Color.black.opacity(0.3) : .clear, radius: 5, y: 4)
                                    }
                                }
                            }
                            .frame(maxWidth: maxWidth)
                            .padding(.top, 40)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                    
                    // Sticky Next button
                    Button {
                        if let goal = selectedGoal {
                            OnboardingDataManager.shared.healthGoal = goal
                        } else {
                            OnboardingDataManager.shared.healthGoal = "Improve overall well-being"
                        }
                        currentPage += 1
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(Color("colors/Blue&Shades/blue-400"))
                            .frame(width: 85, height: 56)
                            .background(Color("colors/Primary/Light"))
                            .clipShape(Capsule())
                    }
                    .disabled(selectedGoal == nil)
                    .opacity(selectedGoal == nil ? 0.5 : 1.0)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Gender Onboarding View
struct OnboardingGenderView: View {
    @Binding var currentPage: Int
    let totalPages = 4
    
    @State private var selectedGender: String?
    
    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width > 500
            let maxWidth: CGFloat = isIPad ? 520 : geometry.size.width - 48
            
            ZStack {
                Color("colors/Blue&Shades/blue-400")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Back button + Page indicator
                            HStack {
                                Button {
                                    currentPage -= 1
                                } label: {
                                    Image(systemName: "chevron.backward")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color("colors/Primary/Light"))
                                        .frame(width: 48, height: 48)
                                }
                                
                                Spacer()
                                
                                PageIndicator(currentPage: currentPage, totalPages: totalPages)
                                
                                Spacer()
                                
                                Color.clear.frame(width: 48, height: 48)
                            }
                            .padding(.top, 20)
                            
                            // Title
                            Text("What's your\ngender?")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(Color("colors/Primary/Light"))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.top, 30)
                            
                            // Gender cards
                            VStack(spacing: 20) {
                                GenderCard(
                                    title: "I am Male",
                                    imageName: "illustrations/onboarding/Male Unselected",
                                    isSelected: selectedGender == "male",
                                    arrowImage: "illustrations/onboarding/Male arrow"
                                ) {
                                    selectedGender = "male"
                                }
                                
                                GenderCard(
                                    title: "I am Female",
                                    imageName: "illustrations/onboarding/Female Unselected",
                                    isSelected: selectedGender == "female",
                                    arrowImage: "illustrations/onboarding/Female arrow"
                                ) {
                                    selectedGender = "female"
                                }
                            }
                            .frame(maxWidth: maxWidth)
                            .padding(.top, 40)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                    
                    // Sticky Actions
                    VStack(spacing: 20) {
                        // Skip button
                        Button {
                            OnboardingDataManager.shared.gender = "prefer_not_to_say"
                            currentPage += 1
                        } label: {
                            Text("Prefer to skip, thanks")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color("colors/Blue&Shades/blue-400"))
                                .frame(maxWidth: maxWidth)
                                .frame(height: 50)
                                .background(Color("colors/Primary/Light"))
                                .clipShape(Capsule())
                        }
                        
                        // Next button
                        Button {
                            if let gender = selectedGender {
                                OnboardingDataManager.shared.gender = gender
                            }
                            currentPage += 1
                        } label: {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(Color("colors/Blue&Shades/blue-400"))
                                .frame(width: 85, height: 56)
                                .background(Color("colors/Primary/Light"))
                                .clipShape(Capsule())
                        }
                        .disabled(selectedGender == nil)
                        .opacity(selectedGender == nil ? 0.5 : 1.0)
                    }
                    .padding(.bottom, 40)
                    .padding(.horizontal, 24)
                }
            }
        }
    }
}

// MARK: - Gender Card Component
struct GenderCard: View {
    let title: String
    let imageName: String
    let isSelected: Bool
    let arrowImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 155)
                    .clipped()
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: isSelected ? Color.black.opacity(0.3) : .clear, radius: 5, y: 4)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color("colors/Primary/Light"))
                    .padding(.top, 16)
                    .padding(.leading, 16)
                
                Image(arrowImage)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(.leading, 16)
                    .padding(.bottom, 16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Age Onboarding View
struct OnboardingAgeView: View {
    @Binding var currentPage: Int
    let totalPages = 4
    
    @State private var selectedAge: Int = 25
    let ageRange = Array(18...99)
    
    var body: some View {
        GeometryReader { geometry in
            let isIPad = geometry.size.width > 500
            let maxWidth: CGFloat = isIPad ? 520 : geometry.size.width - 48
            
            ZStack {
                Color("colors/Blue&Shades/blue-400")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Back button + Page indicator
                            HStack {
                                Button {
                                    currentPage -= 1
                                } label: {
                                    Image(systemName: "chevron.backward")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color("colors/Primary/Light"))
                                        .frame(width: 48, height: 48)
                                }
                                
                                Spacer()
                                
                                PageIndicator(currentPage: currentPage, totalPages: totalPages)
                                
                                Spacer()
                                
                                Color.clear.frame(width: 48, height: 48)
                            }
                            .padding(.top, 20)
                            
                            // Title
                            Text("What's your\nage?")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(Color("colors/Primary/Light"))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.top, 30)
                            
                            // Age picker
                            AgePicker(selectedAge: $selectedAge)
                                .frame(height: 160)
                                .frame(maxWidth: maxWidth)
                                .padding(.top, 40)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                    
                    // Sticky Next button
                    Button {
                        OnboardingDataManager.shared.age = selectedAge
                        currentPage += 1
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(Color("colors/Blue&Shades/blue-400"))
                            .frame(width: 85, height: 56)
                            .background(Color("colors/Primary/Light"))
                            .clipShape(Capsule())
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Age Picker Component
struct AgePicker: View {
    @Binding var selectedAge: Int
    let ageRange = Array(18...99)
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ageRange, id: \.self) { age in
                        OnboardingAgeCell(age: age, isSelected: age == selectedAge)
                            .id(age)
                            .onTapGesture {
                                withAnimation {
                                    selectedAge = age
                                }
                            }
                    }
                }
                .padding(.horizontal, 100)
            }
            .onAppear {
                proxy.scrollTo(selectedAge, anchor: .center)
            }
            .onChange(of: selectedAge) { _, newAge in
                withAnimation {
                    proxy.scrollTo(newAge, anchor: .center)
                }
            }
        }
    }
}

struct OnboardingAgeCell: View {
    let age: Int
    let isSelected: Bool
    
    var body: some View {
        Text("\(age)")
            .font(.system(size: isSelected ? 48 : 32, weight: isSelected ? .bold : .medium))
            .foregroundColor(isSelected ? .white : Color("colors/Primary/Light").opacity(0.5))
            .frame(width: 80, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color("colors/Blue&Shades/blue-300") : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
    }
}

// MARK: - Professional Help Onboarding View
struct OnboardingProfHelpView: View {
    @Binding var currentPage: Int
    let totalPages = 4
    @State private var isLoading = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("colors/Blue&Shades/blue-400")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // Back button + Page indicator
                            HStack {
                                Button {
                                    currentPage -= 1
                                } label: {
                                    Image(systemName: "chevron.backward")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color("colors/Primary/Light"))
                                        .frame(width: 48, height: 48)
                                }
                                
                                Spacer()
                                
                                PageIndicator(currentPage: currentPage, totalPages: totalPages)
                                
                                Spacer()
                                
                                Color.clear.frame(width: 48, height: 48)
                            }
                            .padding(.top, 20)
                            
                            // Title
                            Text("Have you sought professional help before?")
                                .font(.system(size: 29, weight: .bold))
                                .foregroundColor(Color("colors/Primary/Light"))
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .frame(maxWidth: 345)
                                .padding(.top, 30)
                            
                            // Illustration
                            Image("illustrations/onboarding/Stress")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 286, height: 286)
                                .padding(.top, 40)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                    
                    // Sticky Yes/No buttons
                    HStack(spacing: 60) {
                        Button {
                            submitAnswer(seekingHelp: true)
                        } label: {
                            Text("Yes")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("colors/Blue&Shades/blue-400"))
                                .frame(width: 130, height: 56)
                                .background(Color("colors/Primary/Light"))
                                .clipShape(Capsule())
                        }
                        
                        Button {
                            submitAnswer(seekingHelp: false)
                        } label: {
                            Text("No")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("colors/Blue&Shades/blue-400"))
                                .frame(width: 130, height: 56)
                                .background(Color("colors/Primary/Light"))
                                .clipShape(Capsule())
                        }
                    }
                    .disabled(isLoading)
                    .padding(.bottom, 40)
                    .padding(.horizontal, 24)
                }
            }
            
            if isLoading {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
    }
    
    private func submitAnswer(seekingHelp: Bool) {
        isLoading = true
        OnboardingDataManager.shared.seekingProfessionalHelp = seekingHelp
        
        Task {
            do {
                let _ = try await OnboardingDataManager.shared.submit()
                await MainActor.run {
                    currentPage = totalPages
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Page Indicator Component
struct PageIndicator: View {
    let currentPage: Int
    let totalPages: Int
    
    var body: some View {
        Text("\(currentPage + 1) of \(totalPages)")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Color("colors/Blue&Shades/blue-400"))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.white)
            .clipShape(Capsule())
    }
}

// MARK: - Preview
#Preview {
    OnboardingHealthGoalView(currentPage: .constant(0))
}
