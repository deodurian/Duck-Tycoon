import Foundation

enum NumberFormatStyle: String, CaseIterable, Identifiable {
    case scientific = "Scientifique"
    case suffixes = "Lettres (a, b, c...)"
    var id: String { self.rawValue }
}

let b = BigNumber(100.0)
let b2 = BigNumber(0.0)
let sum = b + b2
print("Sum is \(sum.doubleValue)")
let b3 = BigNumber(1)
let zero = BigNumber.zero

print("zero: \(zero.doubleValue)")
if b == 0 {
    print("b is 0")
}
if b > 0 {
    print("b > 0")
}
print("Done!")
