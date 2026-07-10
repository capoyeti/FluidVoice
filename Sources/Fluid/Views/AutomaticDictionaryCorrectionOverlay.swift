import AppKit
import SwiftUI

@MainActor
final class DictionaryCorrectionOverlayController {
    static let shared = DictionaryCorrectionOverlayController()

    private static let displayDurationNanoseconds: UInt64 = 5_000_000_000
    private static let presentationDuration: TimeInterval = 0.05
    private static let dismissalDuration: TimeInterval = 0.05

    private var panel: NSPanel?
    private var hostingView: NSHostingView<AutomaticDictionaryCorrectionOverlayView>?
    private var dismissTask: Task<Void, Never>?
    private var generation: UInt64 = 0

    private init() {}

    func show(
        candidate: AutomaticDictionaryCorrectionCandidate,
        onTrain: @escaping () -> Void
    ) {
        self.generation &+= 1
        let currentGeneration = self.generation
        self.dismissTask?.cancel()

        let rootView = AutomaticDictionaryCorrectionOverlayView(
            candidate: candidate,
            displayDuration: Double(Self.displayDurationNanoseconds) / 1_000_000_000,
            onTrain: { [weak self] in
                self?.hide()
                onTrain()
            },
            onDismiss: { [weak self] in
                self?.hide()
            }
        )

        if let hostingView = self.hostingView {
            hostingView.rootView = rootView
        } else {
            self.createPanel(rootView: rootView)
        }

        guard let panel = self.panel, let hostingView = self.hostingView else { return }
        let fittingSize = hostingView.fittingSize
        hostingView.frame = NSRect(origin: .zero, size: fittingSize)
        panel.setContentSize(fittingSize)
        self.position(panel)

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.presentationDuration
            context.allowsImplicitAnimation = true
            panel.animator().alphaValue = 1
        }

        self.dismissTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: Self.displayDurationNanoseconds)
            guard !Task.isCancelled,
                  let self,
                  self.generation == currentGeneration
            else {
                return
            }
            self.hide()
        }
    }

    func hide() {
        self.generation &+= 1
        self.dismissTask?.cancel()
        self.dismissTask = nil
        guard let panel, panel.isVisible else { return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.dismissalDuration
            context.allowsImplicitAnimation = true
            panel.animator().alphaValue = 0
        } completionHandler: { [weak panel] in
            panel?.orderOut(nil)
            panel?.alphaValue = 1
        }
    }

    private func createPanel(rootView: AutomaticDictionaryCorrectionOverlayView) {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        panel.contentView = hostingView

        self.panel = panel
        self.hostingView = hostingView
    }

    private func position(_ panel: NSPanel) {
        guard let screen = OverlayScreenResolver.screenForCurrentPointer() ?? NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let size = panel.frame.size
        let x = screen.frame.midX - size.width / 2
        let requestedY = visibleFrame.minY + CGFloat(SettingsStore.shared.overlayBottomOffset)
        let y = max(visibleFrame.minY + 10, min(requestedY, visibleFrame.maxY - size.height - 40))
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

private struct AutomaticDictionaryCorrectionOverlayView: View {
    let candidate: AutomaticDictionaryCorrectionCandidate
    let displayDuration: TimeInterval
    let onTrain: () -> Void
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isTrainHovered = false
    @State private var isDismissHovered = false
    @State private var progress: CGFloat = 1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))

                Text("Correction noticed")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))

                Spacer(minLength: 8)

                Button(action: self.onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(self.isDismissHovered ? 0.95 : 0.68))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(self.isDismissHovered ? 0.13 : 0.06))
                        )
                }
                .buttonStyle(.plain)
                .contentShape(Circle())
                .onHover { self.isDismissHovered = $0 }
                .help("Dismiss")
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(self.candidate.heardText)
                            .foregroundStyle(.white.opacity(0.9))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.48))

                        Text(self.candidate.correctedText)
                            .foregroundStyle(.white)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                    Text("Train FluidVoice to remember this?")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: self.onTrain) {
                    Label("Train by Voice", systemImage: "mic.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(self.trainButtonBackground)
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .onHover { self.isTrainHovered = $0 }
                .help("Open Train by Voice")
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .frame(width: 440)
        .background(self.overlayBackground)
        .overlay(alignment: .bottomLeading) {
            GeometryReader { proxy in
                Capsule()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: proxy.size.width * self.progress, height: 2)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 3)
            .allowsHitTesting(false)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            self.startProgressAnimation()
        }
        .onChange(of: self.candidate.id) { _, _ in
            self.startProgressAnimation()
        }
    }

    private func startProgressAnimation() {
        self.progress = 1
        guard !self.reduceMotion else { return }
        DispatchQueue.main.async {
            withAnimation(.linear(duration: self.displayDuration)) {
                self.progress = 0
            }
        }
    }

    private var trainButtonBackground: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(self.isTrainHovered ? Color(red: 0.13, green: 0.13, blue: 0.16) : .black)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(self.isTrainHovered ? 0.38 : 0.24),
                                .white.opacity(self.isTrainHovered ? 0.22 : 0.12),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }

    private var overlayBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.black)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .white.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }
}
