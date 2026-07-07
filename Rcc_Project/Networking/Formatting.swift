import Foundation

/// Small display helpers for the string dates/amounts the backend returns.
enum DisplayFormat {

    /// `38` → `"38.00"`, `19.5` → `"19.50"`.
    static func money(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    /// Formats a backend date string (`"2026-07-04"` or `"2026-07-04T13:20:05"`)
    /// as e.g. `"04 Jul, 2026"`. Returns the raw string if it can't be parsed.
    static func prettyDate(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "—" }
        let datePart = String(raw.prefix(10))   // yyyy-MM-dd
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: datePart) else { return raw }
        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.dateFormat = "dd MMM, yyyy"
        return out.string(from: date)
    }

    /// The `"yyyy-MM"` prefix used to match a payment/invoice to a selected month.
    static func monthPrefix(year: Int, month: Int) -> String {
        String(format: "%04d-%02d", year, month)
    }

    /// Today's date as `"yyyy-MM-dd"` for request bodies.
    static func today() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    /// Now as `"yyyy-MM-dd'T'HH:mm:ss"` for LocalDateTime request bodies.
    static func nowLocalDateTime() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f.string(from: Date())
    }

    /// `"yyyy-MM-04"` issue date for the given period (invoices are dated the 4th).
    static func issueDate(year: Int, month: Int) -> String {
        String(format: "%04d-%02d-04", year, month)
    }
}
