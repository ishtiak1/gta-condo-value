import Foundation

/// Locale-independent formatting that matches the web tool's en-CA output,
/// so labels and tests are identical on every device and on Linux.
public enum Format {
    /// "$788,000". Negative values render as "-$1,234".
    public static func currency(_ n: Double) -> String {
        let r = jsRound(n)
        return (r < 0 ? "-$" : "$") + grouped(abs(r))
    }

    /// A signed amount for the breakdown, e.g. "+$13,429" or "−$6,500".
    public static func signedCurrency(_ n: Double) -> String {
        (n >= 0 ? "+" : "−") + currency(abs(n))
    }

    /// "+4.2%" style percentage, one decimal.
    public static func percent(_ r: Double) -> String {
        (r > 0 ? "+" : "") + String(format: "%.1f", r * 100) + "%"
    }

    /// Whole numbers get thousands separators ("1,200"); fractional values are shown as is.
    public static func number(_ n: Double) -> String {
        if n == n.rounded(), abs(n) < 1e15 {
            return (n < 0 ? "-" : "") + grouped(abs(n))
        }
        return String(n)
    }

    static func grouped(_ n: Double) -> String {
        let digits = String(Int64(n))
        var out = ""
        for (i, ch) in digits.enumerated() {
            if i > 0 && (digits.count - i) % 3 == 0 { out.append(",") }
            out.append(ch)
        }
        return out
    }
}
