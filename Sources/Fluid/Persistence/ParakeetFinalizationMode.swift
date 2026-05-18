import Foundation

enum ParakeetFinalizationMode: String, CaseIterable, Codable, Identifiable {
    case stableFullFinal
    case tokenTimedChunkMerge

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .stableFullFinal:
            return "Normal"
        case .tokenTimedChunkMerge:
            return "Fast"
        }
    }

    var detailText: String {
        switch self {
        case .stableFullFinal:
            return "Most reliable. Best default for everyday dictation."
        case .tokenTimedChunkMerge:
            return "Feels faster, but may be less consistent. Try it if speed matters more."
        }
    }
}
