import Foundation

/// One line of the adjustment breakdown. `rate` is set for percentage adjustments.
public struct ValuationStep: Hashable, Sendable {
    public let label: String
    public let amount: Double
    public let rate: Double?
}

public enum Confidence: Sendable, Equatable {
    case benchmarkOnly, medium, higher

    public var label: String {
        switch self {
        case .higher: return "Higher confidence · 3+ comparables"
        case .medium: return "Medium confidence · add more comparables"
        case .benchmarkOnly: return "Benchmark only · add comparables"
        }
    }
}

public struct Valuation: Sendable {
    /// Unrounded value after every adjustment.
    public let value: Double
    /// `value` rounded to the nearest $1,000, as shown in the web tool.
    public let estimate: Double
    public let low: Double
    public let high: Double
    /// Final value per interior square foot.
    public let pricePerSquareFoot: Double
    /// Starting $/sq ft: the benchmark, or the benchmark blended with comparables.
    public let basePSF: Double
    public let baseLabel: String
    public let steps: [ValuationStep]
    public let confidence: Confidence
    /// Ontario LTT, plus Toronto municipal LTT when the area is in the City of Toronto.
    public let landTransferTax: Double
    /// Time-adjusted $/sq ft of each comparable (parking removed), or nil when the row is incomplete.
    public let comparablePSF: [Double?]
    public let usableComparables: Int
}

/// A faithful port of `calc()` and `ltt()` from the web tool's index.html.
public enum Valuator {
    /// Square footage the size curve is centred on.
    static let referenceSize: Double = 650

    static func sizeFactor(_ sqft: Double) -> Double {
        pow(sqft / referenceSize, -0.12)
    }

    /// Value of one parking space for this area and benchmark.
    public static func parkingValue(area: Area, benchmark: Double) -> Double {
        area.toronto ? (benchmark >= 1000 ? 65_000 : 50_000) : (benchmark >= 800 ? 45_000 : 35_000)
    }

    public static func value(_ s: CondoInput,
                             currentYear: Int = Calendar(identifier: .gregorian).component(.year, from: Date())) -> Valuation {
        let area = Areas.area(at: s.areaIndex)
        let sqft = max(250, s.squareFeet)
        let bench = s.benchmarkPSF != 0 ? s.benchmarkPSF : area.psf
        let parkVal = parkingValue(area: area, benchmark: bench)

        // Comparables: time-adjust, remove parking, then size-normalise to 650 sq ft.
        var compPSF: [Double?] = []
        var comps: [Double] = []
        for c in s.comparables {
            if c.soldPrice > 0 && c.squareFeet > 0 {
                let adjusted = (c.soldPrice - (c.soldWithParking ? parkVal : 0))
                    * pow(1 + s.monthlyTrendPercent / 100, c.monthsAgo)
                let raw = adjusted / c.squareFeet
                compPSF.append(raw)
                comps.append(raw / sizeFactor(c.squareFeet) * sizeFactor(referenceSize))
            } else {
                compPSF.append(nil)
            }
        }

        var base = bench
        var baseLabel = "Area benchmark"
        if !comps.isEmpty {
            let avg = comps.reduce(0, +) / Double(comps.count)
            let w = comps.count >= 3 ? 0.7 : comps.count == 2 ? 0.5 : 0.3
            base = bench * (1 - w) + avg * w
            baseLabel = "Benchmark \(Int(jsRound((1 - w) * 100)))% · comps \(Int(jsRound(w * 100)))%"
        }

        var steps: [ValuationStep] = []
        var v = base * sqft
        steps.append(ValuationStep(label: "\(Format.number(sqft)) sq ft × \(Format.currency(base))/sq ft",
                                   amount: v, rate: nil))
        func mult(_ label: String, _ r: Double) {
            guard r != 0, !r.isNaN else { return }
            let d = v * r
            v += d
            steps.append(ValuationStep(label: label, amount: d, rate: r))
        }

        mult(sqft < referenceSize ? "Smaller unit premium per sq ft" : "Larger unit discount per sq ft",
             sizeFactor(sqft) - 1)
        let bedAdj = (s.bedrooms == 0 ? -0.03 : 0) + (s.bedrooms >= 2 ? 0.01 : 0)
        mult(s.bedrooms == 0 ? "Studio layout" : "Bedroom count", bedAdj)
        mult("Den", s.den ? 0.02 : 0)
        let bathAdj = s.bathrooms.adjustment
        mult("Extra bathroom(s)",
             (s.bedrooms == 0 || s.bedrooms == 1) && s.bathrooms.count >= 2 ? bathAdj + 0.01 : bathAdj)
        let fl = s.floor != 0 ? s.floor : 1
        mult("Floor \(fl)", max(-0.03, min(0.10, Double(fl - 10) * 0.003)))
        mult("Penthouse level", s.penthouse ? 0.05 : 0)
        mult("Corner unit", s.corner ? 0.02 : 0)
        mult("View / exposure", s.view.adjustment)
        mult("Outdoor space", s.outdoor.adjustment)
        mult("Condition", s.condition.adjustment)
        let age = currentYear - (s.yearBuilt != 0 ? s.yearBuilt : 2015)
        let ageAdj = age <= 5 ? 0.05 : age <= 15 ? 0 : age <= 30 ? -0.06 : -0.12
        mult("Building age (\(max(0, age)) yrs)", ageAdj)
        mult("Limited amenities", s.fullAmenities ? 0 : -0.02)
        mult("Transit access", s.nearTransit ? 0.02 : 0)

        // Maintenance fee above or below typical, capitalised at 6%, capped at ±10% of value.
        let typical = sqft * 0.75
        let fee = s.maintenanceFee != 0 ? s.maintenanceFee : typical
        var feeD = -(fee - typical) * 12 / 0.06
        feeD = max(-0.1 * v, min(0.1 * v, feeD))
        if abs(feeD) > 50 {
            v += feeD
            steps.append(ValuationStep(label: "Maintenance \(Format.currency(fee))/mo vs typical \(Format.currency(typical))",
                                       amount: feeD, rate: nil))
        }

        let pk = s.parkingSpaces
        if pk != 0 {
            let d = parkVal * Double(pk) * (pk > 1 ? 0.85 : 1)
            v += d
            steps.append(ValuationStep(label: "Parking × \(pk)", amount: d, rate: nil))
        }
        if s.lockers != 0 {
            v += 6_000
            steps.append(ValuationStep(label: "Locker", amount: 6_000, rate: nil))
        }

        let spread = comps.count >= 3 ? 0.05 : !comps.isEmpty ? 0.065 : 0.08
        let confidence: Confidence = comps.count >= 3 ? .higher : !comps.isEmpty ? .medium : .benchmarkOnly

        return Valuation(
            value: v,
            estimate: roundToThousand(v),
            low: roundToThousand(v * (1 - spread)),
            high: roundToThousand(v * (1 + spread)),
            pricePerSquareFoot: v / sqft,
            basePSF: base,
            baseLabel: baseLabel,
            steps: steps,
            confidence: confidence,
            landTransferTax: landTransferTax(price: v, toronto: area.toronto),
            comparablePSF: compPSF,
            usableComparables: comps.count)
    }

    static let provincialBrackets: [(cap: Double, rate: Double)] = [
        (55_000, 0.005), (250_000, 0.01), (400_000, 0.015), (2_000_000, 0.02), (.infinity, 0.025),
    ]
    static let torontoBrackets: [(cap: Double, rate: Double)] = [
        (55_000, 0.005), (250_000, 0.01), (400_000, 0.015), (2_000_000, 0.02), (3_000_000, 0.025),
        (4_000_000, 0.035), (5_000_000, 0.045), (10_000_000, 0.055), (20_000_000, 0.065), (.infinity, 0.075),
    ]

    static func marginalTax(_ price: Double, _ brackets: [(cap: Double, rate: Double)]) -> Double {
        var tax = 0.0
        var prev = 0.0
        for (cap, rate) in brackets {
            if price > prev { tax += (min(price, cap) - prev) * rate }
            prev = cap
        }
        return tax
    }

    /// Ontario land transfer tax, plus the Toronto municipal tax when `toronto` is true.
    /// No first-time buyer rebates are applied, matching the web tool.
    public static func landTransferTax(price: Double, toronto: Bool) -> Double {
        let provincial = marginalTax(price, provincialBrackets)
        return toronto ? provincial + marginalTax(price, torontoBrackets) : provincial
    }

    static func roundToThousand(_ x: Double) -> Double {
        jsRound(x / 1000) * 1000
    }
}

/// JavaScript's Math.round: halves round toward +infinity.
func jsRound(_ x: Double) -> Double {
    (x + 0.5).rounded(.down)
}
