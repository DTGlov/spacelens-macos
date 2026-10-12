import SwiftUI

struct WelcomeView: View {
    let chooseFolder: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            WelcomeBackdrop()

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 38) {
                        hero(for: proxy.size.width)
                        benefits
                    }
                    .frame(maxWidth: 1_140)
                    .padding(.horizontal, 46)
                    .padding(.vertical, 54)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .center)
                }
            }
        }
        .onAppear(perform: startAnimation)
        .onChange(of: reduceMotion) { _, shouldReduceMotion in
            isAnimating = !shouldReduceMotion
        }
    }

    @ViewBuilder
    private func hero(for width: CGFloat) -> some View {
        if width >= 820 {
            HStack(spacing: 56) {
                welcomeCopy
                    .frame(maxWidth: 430, alignment: .leading)
                StorageMapArtwork(mode: .welcome)
                    .frame(maxWidth: 480)
                    .offset(y: isAnimating && !reduceMotion ? -5 : 0)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 4.8).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        } else {
            VStack(spacing: 36) {
                welcomeCopy
                    .frame(maxWidth: 560, alignment: .leading)
                StorageMapArtwork(mode: .welcome)
                    .frame(maxWidth: 520)
                    .offset(y: isAnimating && !reduceMotion ? -5 : 0)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 4.8).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
    }

    private func startAnimation() {
        guard !reduceMotion else { return }
        isAnimating = true
    }

    private var welcomeCopy: some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("SpaceLens", systemImage: "viewfinder")
                .font(.headline)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 14) {
                Text("See where your storage went.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Turn crowded folders into a clear visual map, inspect what is taking space, and remove only what you choose.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: chooseFolder) {
                Label("Choose a folder to scan", systemImage: "folder.badge.plus")
                    .frame(minWidth: 190)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)

            Label("Scans stay on your Mac. Nothing moves unless you confirm it.", systemImage: "lock.shield")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var benefits: some View {
        HStack(alignment: .top, spacing: 30) {
            WelcomeBenefit(
                systemImage: "chart.treemap",
                title: "Spot the space hogs",
                description: "A visual map makes unusually large files and folders stand out."
            )
            WelcomeBenefit(
                systemImage: "checkmark.shield",
                title: "Review with context",
                description: "See file details and conservative deletion guidance before acting."
            )
            WelcomeBenefit(
                systemImage: "trash.slash",
                title: "Stay in control",
                description: "SpaceLens never cleans automatically and only moves confirmed items to Trash."
            )
        }
    }
}

private struct WelcomeBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            LinearGradient(
                colors: [
                    Color.blue.opacity(colorScheme == .dark ? 0.20 : 0.16),
                    Color.indigo.opacity(colorScheme == .dark ? 0.12 : 0.08),
                    Color.purple.opacity(colorScheme == .dark ? 0.18 : 0.12),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.cyan.opacity(colorScheme == .dark ? 0.16 : 0.20),
                    Color.clear,
                ],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 720
            )
            .scaleEffect(isAnimating && !reduceMotion ? 1.08 : 0.96, anchor: .topTrailing)

            RadialGradient(
                colors: [
                    Color.purple.opacity(colorScheme == .dark ? 0.18 : 0.13),
                    Color.clear,
                ],
                center: .bottomLeading,
                startRadius: 40,
                endRadius: 640
            )

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height

                WelcomeBackdropBlock(
                    color: .blue,
                    size: CGSize(width: width * 0.24, height: height * 0.20)
                )
                .rotationEffect(.degrees(isAnimating && !reduceMotion ? -5 : -8))
                .position(
                    x: width * 0.08 + (isAnimating && !reduceMotion ? 18 : 0),
                    y: height * 0.15 + (isAnimating && !reduceMotion ? -10 : 0)
                )

                WelcomeBackdropBlock(
                    color: .purple,
                    size: CGSize(width: width * 0.18, height: height * 0.30)
                )
                .rotationEffect(.degrees(isAnimating && !reduceMotion ? 4 : 7))
                .position(
                    x: width * 0.96 + (isAnimating && !reduceMotion ? -14 : 0),
                    y: height * 0.28 + (isAnimating && !reduceMotion ? 16 : 0)
                )

                WelcomeBackdropBlock(
                    color: .teal,
                    size: CGSize(width: width * 0.20, height: height * 0.16)
                )
                .rotationEffect(.degrees(isAnimating && !reduceMotion ? 8 : 5))
                .position(
                    x: width * 0.88 + (isAnimating && !reduceMotion ? -16 : 0),
                    y: height * 0.90 + (isAnimating && !reduceMotion ? -12 : 0)
                )

                WelcomeBackdropBlock(
                    color: .indigo,
                    size: CGSize(width: width * 0.13, height: height * 0.18)
                )
                .rotationEffect(.degrees(isAnimating && !reduceMotion ? -3 : -6))
                .position(
                    x: width * 0.05 + (isAnimating && !reduceMotion ? 12 : 0),
                    y: height * 0.78 + (isAnimating && !reduceMotion ? 14 : 0)
                )
            }
            .blur(radius: 1.5)
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 7.5).repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            guard !reduceMotion else { return }
            isAnimating = true
        }
        .onChange(of: reduceMotion) { _, shouldReduceMotion in
            isAnimating = !shouldReduceMotion
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct WelcomeBackdropBlock: View {
    let color: Color
    let size: CGSize

    var body: some View {
        RoundedRectangle(cornerRadius: 34, style: .continuous)
            .fill(color.opacity(0.055))
            .overlay {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .strokeBorder(color.opacity(0.12), lineWidth: 1)
            }
            .frame(width: max(size.width, 120), height: max(size.height, 90))
    }
}

private struct WelcomeBenefit: View {
    let systemImage: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28, height: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.primary.opacity(0.07))
        }
    }
}
