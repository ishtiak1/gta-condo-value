/// A neighbourhood with its resale $/sq ft benchmark (unit only, excluding parking).
public struct Area: Hashable, Sendable, Identifiable {
    public let region: String
    public let name: String
    /// Approximate 2025–26 resale average, dollars per interior square foot.
    public let psf: Double
    /// True when the City of Toronto municipal land transfer tax applies.
    public let toronto: Bool

    public var id: String { name }

    public init(region: String, name: String, psf: Double, toronto: Bool) {
        self.region = region
        self.name = name
        self.psf = psf
        self.toronto = toronto
    }
}

public struct AreaRegion: Sendable, Identifiable {
    public let name: String
    public let areas: [Area]
    public var id: String { name }
}

/// The benchmark table from the web tool (`AREAS` in index.html), in the same order.
/// Update these numbers from the latest TRREB Market Watch figures.
public enum Areas {
    public static let regions: [AreaRegion] = {
        func group(_ region: String, _ rows: [(String, Double, Bool)]) -> AreaRegion {
            AreaRegion(name: region, areas: rows.map { Area(region: region, name: $0.0, psf: $0.1, toronto: $0.2) })
        }
        return [
            group("Toronto", [
                ("Downtown core (C01 · Entertainment, Financial, CityPlace)", 985, true),
                ("King West / Liberty Village / Queen West", 950, true),
                ("Yorkville / Annex (C02)", 1255, true),
                ("St. Lawrence / Distillery / Corktown", 930, true),
                ("Yonge & Eglinton / Midtown", 930, true),
                ("Leslieville / Riverside / East End", 855, true),
                ("North York Centre / Yonge & Sheppard", 835, true),
                ("Don Mills / Bayview Village", 820, true),
                ("Etobicoke · Humber Bay Shores / Mimico", 800, true),
                ("Etobicoke · Islington-City Centre West", 765, true),
                ("Scarborough", 670, true),
                ("York / Weston / Downsview", 705, true),
            ]),
            group("Peel", [
                ("Mississauga · City Centre (Square One)", 725, false),
                ("Mississauga · Port Credit / Lakeview", 835, false),
                ("Mississauga · other", 660, false),
                ("Brampton", 575, false),
            ]),
            group("York Region", [
                ("Vaughan · VMC / Woodbridge", 790, false),
                ("Markham", 765, false),
                ("Richmond Hill", 745, false),
                ("Newmarket / Aurora", 670, false),
            ]),
            group("Halton", [
                ("Oakville", 835, false),
                ("Burlington", 725, false),
                ("Milton", 650, false),
            ]),
            group("Durham", [
                ("Pickering / Ajax", 630, false),
                ("Whitby / Oshawa", 560, false),
            ]),
        ]
    }()

    /// All areas in display order. `CondoInput.areaIndex` indexes into this list.
    public static let all: [Area] = regions.flatMap { $0.areas }

    /// The area at `index`, clamped into range so a stale saved index never crashes.
    public static func area(at index: Int) -> Area {
        all[min(max(index, 0), all.count - 1)]
    }

    public static func index(of area: Area) -> Int {
        all.firstIndex(of: area) ?? 0
    }
}
