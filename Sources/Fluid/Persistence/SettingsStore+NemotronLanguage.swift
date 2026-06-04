import Foundation

extension SettingsStore {
    struct NemotronLanguage: RawRepresentable, CaseIterable, Identifiable, Codable, Hashable {
        let rawValue: String

        var id: String { self.rawValue }

        init(rawValue: String) {
            self.rawValue = rawValue
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.rawValue = try container.decode(String.self)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(self.rawValue)
        }

        static let english = Self(rawValue: "en")

        static let allCases: [Self] = [
            "auto", "af-ZA", "am-ET", "ar", "ar-AR", "ay-BO", "az-AZ", "bg", "bg-BG", "bn-IN",
            "cs", "cs-CZ", "da", "da-DK", "de", "de-DE", "el", "el-GR", "en", "en-GB",
            "en-US", "enGB", "es", "es-ES", "es-US", "esES", "et", "et-EE", "fa-IR", "fi",
            "fi-FI", "fr", "fr-CA", "fr-FR", "gn-PY", "gu-IN", "ha-NG", "haw-US", "he-IL",
            "hi", "hi-HI", "hi-IN", "hr", "hr-HR", "hu", "hu-HU", "hy-AM", "id-ID", "ig-NG",
            "it", "it-IT", "ja-JA", "ja-JP", "ka-GE", "km-KH", "kn-IN", "ko", "ko-KO", "ko-KR",
            "ku-TR", "ky-KG", "ln-CD", "lt", "lt-LT", "lv", "lv-LV", "mi-NZ", "ml-IN", "mr-IN",
            "ms-MY", "mt-MT", "nah-MX", "nb", "nb-NO", "ne-NP", "nl", "nl-NL", "nn", "nn-NO",
            "no", "no-NO", "ny-MW", "or-KE", "pl", "pl-PL", "pt", "pt-BR", "pt-PT", "qu-PE",
            "ro", "ro-RO", "ru", "ru-RU", "rw-RW", "si-LK", "sk", "sk-SK", "sl", "sl-SI",
            "sm-WS", "so-SO", "sv", "sv-SE", "sw-KE", "ta-IN", "te-IN", "tg-TJ", "th-TH", "to-TO",
            "tr", "tr-TR", "uk", "uk-UA", "ur-PK", "uz-UZ", "vi-VN", "yo-NG", "zh-CN", "zh-TW",
            "zh-ZH", "zu-ZA",
        ].map(Self.init(rawValue:))

        var displayName: String {
            if self.rawValue == "auto" {
                return "Auto Detect"
            }

            let normalized = Self.normalizedIdentifier(self.rawValue)
            let localized = Locale.current.localizedString(forIdentifier: normalized)
                ?? Locale(identifier: "en_US").localizedString(forIdentifier: normalized)
            if let localized, localized.isEmpty == false {
                return "\(localized) (\(self.rawValue))"
            }
            return self.rawValue
        }

        private static func normalizedIdentifier(_ identifier: String) -> String {
            switch identifier {
            case "enGB": return "en-GB"
            case "esES": return "es-ES"
            default: return identifier
            }
        }
    }
}
