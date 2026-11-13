import Foundation

/// View / exposure options, valued as a percentage adjustment.
public enum ViewOption: String, CaseIterable, Codable, Sendable, Identifiable {
    case unobstructed, openSouthOrWest, typical, obstructed
    public var id: String { rawValue }
    public var adjustment: Double {
        switch self {
        case .unobstructed: return 0.04
        case .openSouthOrWest: return 0.015
        case .typical: return 0
        case .obstructed: return -0.03
        }
    }
    public var label: String {
        switch self {
        case .unobstructed: return "Unobstructed lake or skyline"
        case .openSouthOrWest: return "Open south or west"
        case .typical: return "Typical"
        case .obstructed: return "Obstructed / faces another tower"
        }
    }
}

public enum OutdoorOption: String, CaseIterable, Codable, Sendable, Identifiable {
    case none, balcony, largeTerrace
    public var id: String { rawValue }
    public var adjustment: Double {
        switch self {
        case .none: return -0.03
        case .balcony: return 0
        case .largeTerrace: return 0.05
        }
    }
    public var label: String {
        switch self {
        case .none: return "None"
        case .balcony: return "Balcony"
        case .largeTerrace: return "Large terrace"
        }
    }
}

public enum ConditionOption: String, CaseIterable, Codable, Sendable, Identifiable {
    case renovated, average, needsUpdating
    public var id: String { rawValue }
    public var adjustment: Double {
        switch self {
        case .renovated: return 0.04
        case .average: return 0
        case .needsUpdating: return -0.06
        }
    }
    public var label: String {
        switch self {
        case .renovated: return "Recently renovated"
        case .average: return "Average / original"
        case .needsUpdating: return "Needs updating"
        }
    }
}

public enum BathroomOption: String, CaseIterable, Codable, Sendable, Identifiable {
    case one, oneAndHalf, two, threePlus
    public var id: String { rawValue }
    public var count: Double {
        switch self {
        case .one: return 1
        case .oneAndHalf: return 1.5
        case .two: return 2
        case .threePlus: return 3
        }
    }
    /// Base adjustment before the extra bonus for studios and one-beds with 2+ baths.
    public var adjustment: Double {
        switch self {
        case .one: return 0
        case .oneAndHalf: return 0.015
        case .two: return 0.03
        case .threePlus: return 0.04
        }
    }
    public var label: String {
        switch self {
        case .one: return "1"
        case .oneAndHalf: return "1.5"
        case .two: return "2"
        case .threePlus: return "3+"
        }
    }
}

/// A recent sale used to calibrate the benchmark.
public struct ComparableSale: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var address: String
    public var soldPrice: Double
    public var squareFeet: Double
    public var monthsAgo: Double
    public var soldWithParking: Bool

    public init(id: UUID = UUID(), address: String = "", soldPrice: Double = 0, squareFeet: Double = 0,
                monthsAgo: Double = 0, soldWithParking: Bool = false) {
        self.id = id
        self.address = address
        self.soldPrice = soldPrice
        self.squareFeet = squareFeet
        self.monthsAgo = monthsAgo
        self.soldWithParking = soldWithParking
    }
}

/// Everything the user enters. Zero in `benchmarkPSF`, `floor`, `yearBuilt` or
/// `maintenanceFee` means "not entered", matching the web tool's fallbacks.
public struct CondoInput: Codable, Hashable, Sendable {
    public var areaIndex: Int
    public var benchmarkPSF: Double
    public var squareFeet: Double
    /// 0 = studio, 3 = 3+.
    public var bedrooms: Int
    public var bathrooms: BathroomOption
    public var den: Bool
    public var floor: Int
    public var view: ViewOption
    public var outdoor: OutdoorOption
    public var condition: ConditionOption
    public var penthouse: Bool
    public var corner: Bool
    public var yearBuilt: Int
    public var maintenanceFee: Double
    /// 0–2.
    public var parkingSpaces: Int
    /// 0–1.
    public var lockers: Int
    public var fullAmenities: Bool
    public var nearTransit: Bool
    /// Market change since sale, percent per month (applied to comparables).
    public var monthlyTrendPercent: Double
    public var comparables: [ComparableSale]

    public init(areaIndex: Int = 0, benchmarkPSF: Double = 0, squareFeet: Double = 650, bedrooms: Int = 1,
                bathrooms: BathroomOption = .one, den: Bool = false, floor: Int = 10,
                view: ViewOption = .typical, outdoor: OutdoorOption = .balcony,
                condition: ConditionOption = .average, penthouse: Bool = false, corner: Bool = false,
                yearBuilt: Int = 2015, maintenanceFee: Double = 0, parkingSpaces: Int = 0, lockers: Int = 0,
                fullAmenities: Bool = true, nearTransit: Bool = false, monthlyTrendPercent: Double = 0,
                comparables: [ComparableSale] = []) {
        self.areaIndex = areaIndex
        self.benchmarkPSF = benchmarkPSF
        self.squareFeet = squareFeet
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.den = den
        self.floor = floor
        self.view = view
        self.outdoor = outdoor
        self.condition = condition
        self.penthouse = penthouse
        self.corner = corner
        self.yearBuilt = yearBuilt
        self.maintenanceFee = maintenanceFee
        self.parkingSpaces = parkingSpaces
        self.lockers = lockers
        self.fullAmenities = fullAmenities
        self.nearTransit = nearTransit
        self.monthlyTrendPercent = monthlyTrendPercent
        self.comparables = comparables
    }

    /// The example the web tool loads on first open (a 650 sq ft downtown one-bed plus den).
    public static let example = CondoInput(
        areaIndex: 0, benchmarkPSF: 985, squareFeet: 650, bedrooms: 1, bathrooms: .one, den: true, floor: 24,
        view: .openSouthOrWest, outdoor: .balcony, condition: .average, penthouse: false, corner: false,
        yearBuilt: 2016, maintenanceFee: 520, parkingSpaces: 1, lockers: 1, fullAmenities: true, nearTransit: true,
        monthlyTrendPercent: -0.2,
        comparables: [
            ComparableSale(address: "Example · 15 Fort York Blvd #2105", soldPrice: 738_000, squareFeet: 640,
                           monthsAgo: 2, soldWithParking: true),
            ComparableSale(address: "Example · 15 Fort York Blvd #1408", soldPrice: 659_000, squareFeet: 620,
                           monthsAgo: 4, soldWithParking: false),
            ComparableSale(address: "Example · 10 Navy Wharf Ct #3302", soldPrice: 772_000, squareFeet: 690,
                           monthsAgo: 5, soldWithParking: true),
        ])
}
