import SwiftUI

struct ImageViewerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let imageURLs: [URL]
    @State private var currentIndex: Int = 0
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            Color.black.ignoresSafeArea()
            
            // Image carousel
            VStack {
                // Close button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(16)
                }
                .frame(maxWidth: .infinity, alignment: .topTrailing)
                
                Spacer()
                
                // Image display
                TabView(selection: $currentIndex) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .tint(.white)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                            case .failure:
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.slash")
                                        .font(.system(size: 48))
                                    Text("Image unavailable")
                                        .font(.callout)
                                }
                                .foregroundStyle(.white.opacity(0.6))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Spacer()
                
                // Page indicator and counter
                if imageURLs.count > 1 {
                    HStack(spacing: 12) {
                        ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, _ in
                            Circle()
                                .fill(currentIndex == index ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 8, height: 8)
                        }
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1)/\(imageURLs.count)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

#Preview {
    ImageViewerView(imageURLs: [
        URL(string: "https://via.placeholder.com/400x300")!
    ])
}
