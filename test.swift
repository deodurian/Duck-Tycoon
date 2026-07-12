import Foundation

struct BigNumber {
    init(_ v: Double) {}
    static func * (lhs: BigNumber, rhs: Double) -> BigNumber { return lhs }
}

func calculateMutationsPerSecond(with duck: Int?, globalBonus: BigNumber = BigNumber(1.0)) -> BigNumber {
    guard let assignedDuck = duck else { return BigNumber(0.0) }
    let baseMutation = BigNumber(Double(assignedDuck)) * 0.01
    return baseMutation
}
