import SwiftUI

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let bodyText: String
    let iconName: String
    let useAsset: Bool
    let caption: String?
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var currentTab = 0
    
    let slides = [
        OnboardingSlide(
            title: "Your training partner.",
            subtitle: "When you train alone, **yeah buddy** has your back.",
            bodyText: "Stay focused on your intensity while we handle the count. No more losing track mid-set.",
            iconName: "logo_neo_pink",
            useAsset: true,
            caption: nil
        ),
        OnboardingSlide(
            title: "When it gets hard, most people stop early.",
            subtitle: nil,
            bodyText: "The real results come from finishing every rep you planned.\n**yeah buddy** keeps you going when it matters most.",
            iconName: "flame.fill",
            useAsset: false,
            caption: nil
        ),
        OnboardingSlide(
            title: "Make a sound. Count the rep.",
            subtitle: nil,
            bodyText: "Make a short sound on every rep.\n**yeah buddy** listens and counts for you — automatically.",
            iconName: "waveform.circle.fill",
            useAsset: false,
            caption: "No buttons. No distractions."
        ),
        OnboardingSlide(
            title: "Headphones recommended.",
            subtitle: nil,
            bodyText: "For the best reaction and motivation, use headphones with a microphone.\n**yeah buddy** reacts instantly to every rep.",
            iconName: "headphones",
            useAsset: false,
            caption: nil
        ),
        OnboardingSlide(
            title: "Train anywhere. Finish strong.",
            subtitle: nil,
            bodyText: "Train at home, at the gym, or anywhere you want.\n**yeah buddy** is your partner — pushing you to complete every rep.",
            iconName: "location.fill",
            useAsset: false,
            caption: nil
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            YBGradients.mainBackground
                .ignoresSafeArea()
            
            VStack {
                // Skip Button
                HStack {
                    Spacer()
                    if currentTab < slides.count - 1 {
                        Button("Skip") {
                            withAnimation {
                                hasCompletedOnboarding = true
                            }
                        }
                        .foregroundColor(YBColors.textSecondary)
                        .padding(.trailing, 20)
                    }
                }
                .padding(.top, 20)
                
                TabView(selection: $currentTab) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        SlideView(slide: slides[index], isLast: index == slides.count - 1) {
                            withAnimation {
                                hasCompletedOnboarding = true
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
        }
    }
}

struct SlideView: View {
    let slide: OnboardingSlide
    let isLast: Bool
    let onFinish: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon / Symbol
            Group {
                if slide.useAsset {
                    Image(slide.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 240)
                } else {
                    Image(systemName: slide.iconName)
                        .font(.system(size: 80))
                }
            }
            .foregroundColor(YBColors.neonPink)
            .shadow(color: YBColors.neonPink.opacity(0.5), radius: 20)
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            
            VStack(spacing: 20) {
                // Title
                Text(slide.title)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(YBColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .offset(y: isVisible ? 0 : 20)
                    .opacity(isVisible ? 1.0 : 0.0)
                
                // Subtitle
                if let subtitle = slide.subtitle {
                    Text(LocalizedStringKey(subtitle))
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(YBColors.neonGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .offset(y: isVisible ? 0 : 20)
                        .opacity(isVisible ? 1.0 : 0.0)
                }
                
                // Body
                Text(LocalizedStringKey(slide.bodyText))
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(YBColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .offset(y: isVisible ? 0 : 20)
                    .opacity(isVisible ? 1.0 : 0.0)
                
                // Caption
                if let caption = slide.caption {
                    Text(caption)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(YBColors.neonPink)
                        .padding(.top, 10)
                        .offset(y: isVisible ? 0 : 20)
                        .opacity(isVisible ? 1.0 : 0.0)
                }
            }
            .animation(.easeOut(duration: 0.8).delay(0.2), value: isVisible)
            
            Spacer()
            
            if isLast {
                Button(action: onFinish) {
                    Text("LET'S TRAIN")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [YBColors.neonPink, YBColors.backgroundStart], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(30)
                        .shadow(color: YBColors.neonPink.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 60)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Spacer().frame(height: 100) // Space for page indicator
            }
        }
        .onAppear {
            isVisible = true
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
