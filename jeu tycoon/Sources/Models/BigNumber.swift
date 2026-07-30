import Foundation

/// A structure representing arbitrarily large numbers using mantissa + exponent notation.
/// `value = mantissa × 10^exponent` where mantissa is in [1.0, 10.0) or is 0.
/// This allows numbers far beyond Double's 1.79e308 limit.
struct BigNumber: Codable, Equatable, Hashable, Sendable {
    
    /// The significant digits (between 1.0 and 9.999... or 0)
    var mantissa: Double
    /// The power of 10
    var exponent: Int
    
    // MARK: - Constants
    
    nonisolated static let zero = BigNumber(mantissa: 0.0, exponent: 0)
    nonisolated static let one = BigNumber(mantissa: 1.0, exponent: 0)
    
    // MARK: - Initialization
    
    nonisolated init(mantissa: Double, exponent: Int) {
        if mantissa == 0.0 || mantissa.isNaN || mantissa.isInfinite {
            self.mantissa = 0.0
            self.exponent = 0
        } else {
            self.mantissa = mantissa
            self.exponent = exponent
            self.normalize()
        }
    }
    
    /// Create a BigNumber from a regular Double
    nonisolated init(_ value: Double) {
        if value == 0.0 || value.isNaN || value.isInfinite {
            self.mantissa = 0.0
            self.exponent = 0
        } else {
            let negative = value < 0.0
            let absValue = abs(value)
            let exp = Int(floor(log10(absValue)))
            let man = absValue / Foundation.pow(10.0, Double(exp))
            self.mantissa = negative ? -man : man
            self.exponent = exp
            self.normalize()
        }
    }
    
    /// Create a BigNumber from an Int
    nonisolated init(_ value: Int) {
        self.init(Double(value))
    }
    
    // MARK: - Normalization
    
    nonisolated private mutating func normalize() {
        if mantissa == 0.0 || mantissa.isNaN || mantissa.isInfinite {
            mantissa = 0.0
            exponent = 0
            return
        }
        
        let negative = mantissa < 0.0
        var absMantissa = abs(mantissa)
        
        if absMantissa >= 10.0 || absMantissa < 1.0 {
            let shift = Int(floor(log10(absMantissa)))
            absMantissa /= Foundation.pow(10.0, Double(shift))
            exponent += shift
        }
        
        // Handle floating point edge cases
        if absMantissa < 1e-10 {
            mantissa = 0.0
            exponent = 0
            return
        }
        
        mantissa = negative ? -absMantissa : absMantissa
        
        // Easter Egg: Cap at 10^10_000_000_000
        if exponent >= 10_000_000_000 {
            exponent = 10_000_000_000
            mantissa = mantissa > 0 ? 9.999999999999999 : -9.999999999999999
        } else if exponent <= -10_000_000_000 {
            exponent = 0
            mantissa = 0.0
        }
    }
    
    // MARK: - Conversion
    
    /// Convert back to Double (may overflow to infinity for very large numbers)
    var doubleValue: Double {
        if mantissa == 0.0 { return 0.0 }
        if exponent > 307 { return mantissa > 0.0 ? .infinity : -.infinity }
        if exponent < -307 { return 0.0 }
        return mantissa * Foundation.pow(10.0, Double(exponent))
    }
    
    /// Convert to Int (clamped to Int range)
    var intValue: Int {
        let d = doubleValue
        if d >= Double(Int.max) { return Int.max }
        if d <= Double(Int.min) { return Int.min }
        return Int(d)
    }
    
    /// Whether this number is effectively zero
    nonisolated var isZero: Bool {
        return mantissa == 0.0
    }
    
    /// Whether this number is negative
    nonisolated var isNegative: Bool {
        return mantissa < 0.0
    }
    
    /// Natural logarithm (ln)
    nonisolated var ln: Double {
        if isZero || isNegative { return .nan }
        return log(mantissa) + Double(exponent) * log(10.0)
    }
    
    // MARK: - Formatting
    
    nonisolated var asDouble: Double {
        return mantissa * Foundation.pow(10.0, Double(exponent))
    }
    
    /// Style de formatage mis en cache.
    ///
    /// `formattedString()` est appelé des milliers de fois par seconde par l'interface (chaque prix,
    /// chaque compteur, chaque cellule de liste) et lisait `UserDefaults` à CHAQUE appel : verrou,
    /// pont NSString→String et allocation. Le réglage ne changeant que depuis les Paramètres,
    /// on le lit une fois et on le rafraîchit explicitement via `refreshFormatStyle()`.
    nonisolated(unsafe) static var cachedFormatStyle: NumberFormatStyle = readFormatStyleFromDefaults()

    nonisolated static func readFormatStyleFromDefaults() -> NumberFormatStyle {
        let styleString = UserDefaults.standard.string(forKey: "numberFormatStyle") ?? NumberFormatStyle.scientific.rawValue
        return NumberFormatStyle(rawValue: styleString) ?? .scientific
    }

    /// À appeler quand le joueur change le format des nombres dans les Paramètres.
    nonisolated static func refreshFormatStyle() {
        cachedFormatStyle = readFormatStyleFromDefaults()
    }

    nonisolated func formattedString() -> String {
        let style = BigNumber.cachedFormatStyle

        if isZero { return "0" }
        if exponent >= 10_000_000_000 { return isNegative ? "-inf" : "inf" }
        
        let isNeg = isNegative
        let absMantissa = abs(mantissa)
        let absExponent = exponent
        
        // For small numbers (< 1000), display normally
        if absExponent < 3 {
            let value = absMantissa * Foundation.pow(10.0, Double(absExponent))
            let prefix = isNeg ? "-" : ""
            if value < 1 {
                return "\(prefix)\(String(format: "%.2f", value))"
            }
            return "\(prefix)\(String(format: "%.0f", value))"
        }
        
        switch style {
        case .suffixes:
            return formatWithSuffixes(absMantissa: absMantissa, absExponent: absExponent, isNegative: isNeg)
        case .scientific:
            return formatScientific(absMantissa: absMantissa, absExponent: absExponent, isNegative: isNeg)
        }
    }
    
    /// Suffixes par tranche de 3 zéros, partagés par l'affichage normal et les compteurs animés.
    nonisolated fileprivate static let suffixArray = [
        "k", "M", "Md", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
        "Dc", "UDc", "DDc", "TDc", "QaDc", "QiDc", "SxDc", "SpDc", "OcDc", "NoDc",
        "Vg", "UVg", "DVg", "TVg", "QaVg", "QiVg", "SxVg", "SpVg", "OcVg", "NoVg",
        "Tg", "UTg", "DTg"
    ]

    nonisolated private func formatWithSuffixes(absMantissa: Double, absExponent: Int, isNegative: Bool) -> String {
        let suffixArray = Self.suffixArray

        let order = absExponent / 3  // Which group of 3 zeros
        let index = order - 1
        let prefix = isNegative ? "-" : ""

        if index >= 0 && index < suffixArray.count {
            let remainder = absExponent % 3
            let displayValue = absMantissa * Foundation.pow(10.0, Double(remainder))
            if floor(displayValue) == displayValue {
                return "\(prefix)\(String(format: "%.0f", displayValue))\(suffixArray[index])"
            } else {
                return "\(prefix)\(String(format: "%.1f", displayValue))\(suffixArray[index])"
            }
        } else {
            // Beyond suffix range: fallback to scientific notation
            return formatScientific(absMantissa: absMantissa, absExponent: absExponent, isNegative: isNegative)
        }
    }
    
    nonisolated private func formatScientific(absMantissa: Double, absExponent: Int, isNegative: Bool) -> String {
        let prefix = isNegative ? "-" : ""
        return "\(prefix)\(String(format: "%.2f", absMantissa))e\(absExponent)"
    }

    /// Étape d'un compteur qui défile vers ce montant (écran de retour en ligne).
    ///
    /// `progress` est la fraction affichée : 0 → 1 pendant le décompte, et jusqu'à 2 quand on
    /// anime un ×2. L'unité (k, M, e42…) et le nombre de décimales sont **verrouillés sur le
    /// montant final** : les chiffres roulent sans que le suffixe ni la largeur ne sautent
    /// d'une image à l'autre. À `progress == 1`, le rendu est exactement `formattedString()`.
    nonisolated func countingString(progress: Double) -> String {
        let p = max(0.0, progress)
        if p == 1.0 { return formattedString() }
        if isZero { return "0" }
        if exponent >= 10_000_000_000 { return isNegative ? "-inf" : "inf" }

        let style = BigNumber.cachedFormatStyle

        let prefix = isNegative ? "-" : ""
        let finalMantissa = abs(mantissa)
        let currentMantissa = finalMantissa * p

        // Petits montants (< 1000) : valeur brute, comme formattedString().
        if exponent < 3 {
            let scale = Foundation.pow(10.0, Double(exponent))
            let decimals = (finalMantissa * scale) < 1.0 ? 2 : 0
            return "\(prefix)\(String(format: "%.\(decimals)f", currentMantissa * scale))"
        }

        switch style {
        case .scientific:
            return "\(prefix)\(String(format: "%.2f", currentMantissa))e\(exponent)"
        case .suffixes:
            let index = exponent / 3 - 1
            guard index >= 0, index < Self.suffixArray.count else {
                return "\(prefix)\(String(format: "%.2f", currentMantissa))e\(exponent)"
            }
            let scale = Foundation.pow(10.0, Double(exponent % 3))
            let finalDisplay = finalMantissa * scale
            let decimals = floor(finalDisplay) == finalDisplay ? 0 : 1
            return "\(prefix)\(String(format: "%.\(decimals)f", currentMantissa * scale))\(Self.suffixArray[index])"
        }
    }
}

// MARK: - Comparable

extension BigNumber: Comparable {
    nonisolated static func < (lhs: BigNumber, rhs: BigNumber) -> Bool {
        // Handle zero cases
        if lhs.isZero && rhs.isZero { return false }
        if lhs.isZero { return !rhs.isNegative }
        if rhs.isZero { return lhs.isNegative }
        
        // Handle different signs
        if lhs.isNegative && !rhs.isNegative { return true }
        if !lhs.isNegative && rhs.isNegative { return false }
        
        // Both positive
        if !lhs.isNegative {
            if lhs.exponent != rhs.exponent {
                return lhs.exponent < rhs.exponent
            }
            return lhs.mantissa < rhs.mantissa
        }
        
        // Both negative (reverse comparison)
        if lhs.exponent != rhs.exponent {
            return lhs.exponent > rhs.exponent
        }
        return lhs.mantissa < rhs.mantissa
    }
    
    nonisolated static func > (lhs: BigNumber, rhs: BigNumber) -> Bool {
        return rhs < lhs
    }
    
    nonisolated static func <= (lhs: BigNumber, rhs: BigNumber) -> Bool {
        return !(rhs < lhs)
    }
    
    nonisolated static func >= (lhs: BigNumber, rhs: BigNumber) -> Bool {
        return !(lhs < rhs)
    }
}

// MARK: - Arithmetic Operators

extension BigNumber {
    
    nonisolated static func + (lhs: BigNumber, rhs: BigNumber) -> BigNumber {
        if lhs.isZero { return rhs }
        if rhs.isZero { return lhs }
        
        // Align exponents to the larger one
        let maxExp = max(lhs.exponent, rhs.exponent)
        let lhsAdjusted = lhs.mantissa * Foundation.pow(10.0, Double(lhs.exponent - maxExp))
        let rhsAdjusted = rhs.mantissa * Foundation.pow(10.0, Double(rhs.exponent - maxExp))
        
        let sumMantissa = lhsAdjusted + rhsAdjusted
        
        if sumMantissa == 0.0 { return .zero }
        
        return BigNumber(mantissa: sumMantissa, exponent: maxExp)
    }
    
    nonisolated static func - (lhs: BigNumber, rhs: BigNumber) -> BigNumber {
        return lhs + BigNumber(mantissa: -rhs.mantissa, exponent: rhs.exponent)
    }
    
    nonisolated static func * (lhs: BigNumber, rhs: BigNumber) -> BigNumber {
        if lhs.isZero || rhs.isZero { return .zero }
        return BigNumber(mantissa: lhs.mantissa * rhs.mantissa, exponent: lhs.exponent + rhs.exponent)
    }
    
    nonisolated static func / (lhs: BigNumber, rhs: BigNumber) -> BigNumber {
        if rhs.isZero { return .zero } // Avoid division by zero
        if lhs.isZero { return .zero }
        return BigNumber(mantissa: lhs.mantissa / rhs.mantissa, exponent: lhs.exponent - rhs.exponent)
    }
    
    // MARK: - Compound Assignment
    
    nonisolated static func += (lhs: inout BigNumber, rhs: BigNumber) {
        lhs = lhs + rhs
    }
    
    nonisolated static func -= (lhs: inout BigNumber, rhs: BigNumber) {
        lhs = lhs - rhs
    }
    
    nonisolated static func *= (lhs: inout BigNumber, rhs: BigNumber) {
        lhs = lhs * rhs
    }
    
    nonisolated static func /= (lhs: inout BigNumber, rhs: BigNumber) {
        lhs = lhs / rhs
    }
    
    // MARK: - Operators with Double (convenience)
    
    nonisolated static func * (lhs: BigNumber, rhs: Double) -> BigNumber {
        return lhs * BigNumber(rhs)
    }
    
    nonisolated static func * (lhs: Double, rhs: BigNumber) -> BigNumber {
        return BigNumber(lhs) * rhs
    }
    
    nonisolated static func / (lhs: BigNumber, rhs: Double) -> BigNumber {
        return lhs / BigNumber(rhs)
    }
    
    nonisolated static func + (lhs: BigNumber, rhs: Double) -> BigNumber {
        return lhs + BigNumber(rhs)
    }
    
    nonisolated static func + (lhs: Double, rhs: BigNumber) -> BigNumber {
        return BigNumber(lhs) + rhs
    }
    
    nonisolated static func - (lhs: BigNumber, rhs: Double) -> BigNumber {
        return lhs - BigNumber(rhs)
    }
    
    nonisolated static func *= (lhs: inout BigNumber, rhs: Double) {
        lhs = lhs * BigNumber(rhs)
    }
    
    nonisolated static func += (lhs: inout BigNumber, rhs: Double) {
        lhs = lhs + BigNumber(rhs)
    }
    
    // MARK: - Comparison with Double (convenience)
    
    nonisolated static func < (lhs: BigNumber, rhs: Double) -> Bool {
        return lhs < BigNumber(rhs)
    }
    
    nonisolated static func > (lhs: BigNumber, rhs: Double) -> Bool {
        return BigNumber(rhs) < lhs
    }
    
    nonisolated static func >= (lhs: BigNumber, rhs: Double) -> Bool {
        return !(lhs < BigNumber(rhs))
    }
    
    nonisolated static func <= (lhs: BigNumber, rhs: Double) -> Bool {
        return !(BigNumber(rhs) < lhs)
    }
    
    nonisolated static func < (lhs: Double, rhs: BigNumber) -> Bool {
        return BigNumber(lhs) < rhs
    }
    
    nonisolated static func > (lhs: Double, rhs: BigNumber) -> Bool {
        return rhs < BigNumber(lhs)
    }
    
    nonisolated static func >= (lhs: Double, rhs: BigNumber) -> Bool {
        return !(BigNumber(lhs) < rhs)
    }
    
    nonisolated static func == (lhs: BigNumber, rhs: Double) -> Bool {
        return lhs == BigNumber(rhs)
    }
    
    // MARK: - Comparison with Int (convenience)
    
    nonisolated static func >= (lhs: BigNumber, rhs: Int) -> Bool {
        return lhs >= Double(rhs)
    }
    
    nonisolated static func < (lhs: BigNumber, rhs: Int) -> Bool {
        return lhs < Double(rhs)
    }
    
    // MARK: - Power function
    
    /// Compute self raised to the power of exp
    nonisolated static func pow(_ base: BigNumber, _ exp: Double) -> BigNumber {
        if base.isZero { return .zero }
        if exp == 0.0 { return .one }
        if exp == 1.0 { return base }
        
        // log10(base) = log10(mantissa) + exponent
        let log10Base = log10(abs(base.mantissa)) + Double(base.exponent)
        let newLog10 = log10Base * exp
        
        let newExponent = Int(floor(newLog10))
        var newMantissa = Foundation.pow(10.0, newLog10 - Double(newExponent))
        
        if base.isNegative && floor(exp) == exp && Int(exp) % 2 != 0 {
            newMantissa = -newMantissa
        }
        
        return BigNumber(mantissa: newMantissa, exponent: newExponent)
    }

    /// Compute self raised to an integer power
    nonisolated static func pow(_ base: BigNumber, _ exp: Int) -> BigNumber {
        return pow(base, Double(exp))
    }
}

extension Double {
    nonisolated func safeInt() -> Int {
        if self >= Double(Int.max) || self.isInfinite || self.isNaN {
            return Int.max
        } else if self <= Double(Int.min) {
            return Int.min
        }
        return Int(self)
    }
}

extension Int {
    nonisolated mutating func addReportingOverflow(_ value: Int) {
        let (newVal, overflow) = self.addingReportingOverflow(value)
        self = overflow ? Int.max : newVal
    }
}

// MARK: - Removed ExpressibleByIntegerLiteral & ExpressibleByFloatLiteral to prevent infinite recursion on operators

// MARK: - CustomStringConvertible

extension BigNumber: CustomStringConvertible {
    var description: String {
        return formattedString()
    }
}

// MARK: - Codable with backward compatibility

extension BigNumber {
    enum CodingKeys: String, CodingKey {
        case mantissa, exponent
    }
    
    nonisolated init(from decoder: Decoder) throws {
        // Try to decode as BigNumber first (new format)
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            if let m = try? container.decode(Double.self, forKey: .mantissa),
               let e = try? container.decode(Int.self, forKey: .exponent) {
                self.init(mantissa: m, exponent: e)
                return
            }
        }
        
        // Fallback: decode as a raw Double (old save format)
        if let singleValue = try? decoder.singleValueContainer(),
           let doubleValue = try? singleValue.decode(Double.self) {
            self.init(doubleValue)
            return
        }
        
        // Default to zero
        self = .zero
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mantissa, forKey: .mantissa)
        try container.encode(exponent, forKey: .exponent)
    }
    
    // MARK: - Equatable
    
    nonisolated static func == (lhs: BigNumber, rhs: BigNumber) -> Bool {
        return lhs.mantissa == rhs.mantissa && lhs.exponent == rhs.exponent
    }
}

extension BigNumber {
    nonisolated static func * (lhs: BigNumber, rhs: Int) -> BigNumber {
        return lhs * BigNumber(Double(rhs))
    }
    nonisolated static func * (lhs: Int, rhs: BigNumber) -> BigNumber {
        return BigNumber(Double(lhs)) * rhs
    }
    nonisolated static func + (lhs: BigNumber, rhs: Int) -> BigNumber {
        return lhs + BigNumber(Double(rhs))
    }
    nonisolated static func + (lhs: Int, rhs: BigNumber) -> BigNumber {
        return BigNumber(Double(lhs)) + rhs
    }
    nonisolated static func - (lhs: BigNumber, rhs: Int) -> BigNumber {
        return lhs - BigNumber(Double(rhs))
    }
    nonisolated static func / (lhs: BigNumber, rhs: Int) -> BigNumber {
        return lhs / BigNumber(Double(rhs))
    }
}
