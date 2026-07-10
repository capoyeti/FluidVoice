import Foundation

struct DictionaryTrainingPrefill: Equatable, Identifiable {
    let id = UUID()
    let intendedText: String
    let capturedVariants: [String]
}

enum AppNavigationDestination {
    case aiEnhancements
    case history
    case customDictionaryTraining(DictionaryTrainingPrefill)
}

@MainActor
final class AppNavigationRouter {
    static let shared = AppNavigationRouter()

    private var pendingDestination: AppNavigationDestination?
    private var presentMainWindow: (() -> Void)?

    private init() {}

    func configureWindowPresenter(_ presenter: @escaping () -> Void) {
        self.presentMainWindow = presenter
    }

    func request(_ destination: AppNavigationDestination, presentsMainWindow: Bool = false) {
        self.pendingDestination = destination
        if presentsMainWindow {
            self.presentMainWindow?()
        }
        NotificationCenter.default.post(name: .appNavigationRequested, object: nil)
    }

    func consumePendingDestination() -> AppNavigationDestination? {
        let destination = self.pendingDestination
        self.pendingDestination = nil
        return destination
    }
}

extension Notification.Name {
    static let appNavigationRequested = Notification.Name("AppNavigationRequested")
    static let dictationPromptShortcutsChanged = Notification.Name("DictationPromptShortcutsChanged")
    static let newPromptShortcutRecorded = Notification.Name("NewPromptShortcutRecorded")
}
