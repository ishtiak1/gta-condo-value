import XCTest
@testable import CondoValuationKit

/// Expected numbers below were produced by running the web tool's own calc() and ltt()
/// (index.html) in Node with the same inputs and the year fixed at 2026, so these tests
/// check that the Swift port gives the same answers as the page.
final class ValuatorTests: XCTestCase {
    let year = 2026

    func assertClose(_ a: Double, _ b: Double, _ msg: String = "", file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(a, b, accuracy: max(1e-6, abs(b) * 1e-9), msg, file: file, line: line)
    }

    // MARK: Area table

    func testAreaTableMatchesWebTool() {
        XCTAssertEqual(Areas.all.count, 25)
        XCTAssertEqual(Areas.regions.map(\.name), ["Toronto", "Peel", "York Region", "Halton", "Durham"])
        XCTAssertEqual(Areas.all.filter(\.toronto).count, 12)
        XCTAssertEqual(Areas.all[2].name, "Yorkville / Annex (C02)")
        XCTAssertEqual(Areas.all[2].psf, 1255)
        XCTAssertEqual(Areas.all[24].name, "Whitby / Oshawa")
        XCTAssertEqual(Areas.area(at: 99).name, "Whitby / Oshawa", "out-of-range index is clamped")
    }

    // MARK: Full valuations

    func testExampleWithThreeComparables() {
        let r = Valuator.value(.example, currentYear: year)
        assertClose(r.value, 788313.6371559476)
        XCTAssertEqual(r.estimate, 788_000)
        XCTAssertEqual(r.low, 749_000)
        XCTAssertEqual(r.high, 828_000)
        assertClose(r.basePSF, 1032.9693650130448)
        XCTAssertEqual(r.baseLabel, "Benchmark 30% · comps 70%")
        assertClose(r.landTransferTax, 24482.545486237905)
        XCTAssertEqual(r.confidence, .higher)
        XCTAssertEqual(r.usableComparables, 3)
        assertClose(r.comparablePSF[0]!, 1070.7042999999999)
        assertClose(r.comparablePSF[1]!, 1054.4254756815226)
        assertClose(r.comparablePSF[2]!, 1035.9548149242564)

        XCTAssertEqual(r.steps.map(\.label), [
            "650 sq ft × $1,033/sq ft", "Den", "Floor 24", "View / exposure", "Transit access",
            "Maintenance $520/mo vs typical $488", "Parking × 1", "Locker",
        ])
        let amounts = [671430.0872584791, 13428.601745169583, 28764.064938153246, 10704.341309127029,
                       14486.541905018581, -6500, 50000, 6000]
        for (step, expected) in zip(r.steps, amounts) { assertClose(step.amount, expected, step.label) }
    }

    func testBenchmarkOnlyPeelOlderBuilding() {
        var s = CondoInput(areaIndex: 12, benchmarkPSF: 0, squareFeet: 900, bedrooms: 2, bathrooms: .two,
                           floor: 5, view: .obstructed, outdoor: .none, condition: .needsUpdating,
                           yearBuilt: 1990, maintenanceFee: 900, parkingSpaces: 2, lockers: 0,
                           fullAmenities: false, nearTransit: false)
        s.comparables = []
        let r = Valuator.value(s, currentYear: year)
        assertClose(r.value, 504951.3300551811)
        XCTAssertEqual(r.estimate, 505_000)
        XCTAssertEqual(r.low, 465_000)
        XCTAssertEqual(r.high, 545_000)
        XCTAssertEqual(r.basePSF, 725, "empty benchmark falls back to the area's")
        XCTAssertEqual(r.baseLabel, "Area benchmark")
        XCTAssertEqual(r.confidence, .benchmarkOnly)
        assertClose(r.landTransferTax, 6574.026601103622)
        XCTAssertEqual(r.steps.map(\.label), [
            "900 sq ft × $725/sq ft", "Larger unit discount per sq ft", "Bedroom count", "Extra bathroom(s)",
            "Floor 5", "View / exposure", "Outdoor space", "Condition", "Building age (36 yrs)",
            "Limited amenities", "Maintenance $900/mo vs typical $675", "Parking × 2",
        ])
        assertClose(r.steps[1].rate!, -0.038298038888257)
        assertClose(r.steps.last!.amount, 59500)
        assertClose(r.steps[10].amount, -45000)
    }

    func testStudioPenthouseOneComparable() {
        let s = CondoInput(areaIndex: 2, benchmarkPSF: 1255, squareFeet: 400, bedrooms: 0, bathrooms: .two,
                           floor: 60, view: .unobstructed, outdoor: .largeTerrace, condition: .renovated,
                           penthouse: true, corner: true, yearBuilt: 2024, maintenanceFee: 0,
                           fullAmenities: true, nearTransit: true, monthlyTrendPercent: 0.5,
                           comparables: [ComparableSale(soldPrice: 560_000, squareFeet: 410, monthsAgo: 3)])
        let r = Valuator.value(s, currentYear: year)
        assertClose(r.value, 779653.7607553373)
        XCTAssertEqual(r.estimate, 780_000)
        XCTAssertEqual(r.low, 729_000)
        XCTAssertEqual(r.high, 830_000)
        XCTAssertEqual(r.baseLabel, "Benchmark 70% · comps 30%")
        XCTAssertEqual(r.confidence, .medium)
        assertClose(r.comparablePSF[0]!, 1386.4440731707314)
        assertClose(r.landTransferTax, 24136.150430213493)
        XCTAssertEqual(r.steps.map(\.label), [
            "400 sq ft × $1,272/sq ft", "Smaller unit premium per sq ft", "Studio layout", "Extra bathroom(s)",
            "Floor 60", "Penthouse level", "Corner unit", "View / exposure", "Outdoor space", "Condition",
            "Building age (2 yrs)", "Transit access",
        ])
        XCTAssertEqual(r.steps[3].rate!, 0.04, accuracy: 1e-12, "studio with 2 baths gets the +1% bonus")
        XCTAssertEqual(r.steps[4].rate!, 0.10, accuracy: 1e-12, "floor premium is capped at 10%")
        XCTAssertFalse(r.steps.contains { $0.label.hasPrefix("Maintenance") }, "blank fee means typical, no step")
    }

    func testLargeUnitTwoUsableComparablesSkipsIncompleteRow() {
        let s = CondoInput(areaIndex: 20, benchmarkPSF: 835, squareFeet: 1200, bedrooms: 3, bathrooms: .threePlus,
                           den: true, floor: 12, yearBuilt: 2005, maintenanceFee: 1100, parkingSpaces: 1, lockers: 1,
                           fullAmenities: true, nearTransit: false,
                           comparables: [
                               ComparableSale(soldPrice: 1_050_000, squareFeet: 1150, monthsAgo: 1, soldWithParking: true),
                               ComparableSale(soldPrice: 0, squareFeet: 900, monthsAgo: 1),
                               ComparableSale(soldPrice: 990_000, squareFeet: 1180, monthsAgo: 6),
                           ])
        let r = Valuator.value(s, currentYear: year)
        assertClose(r.value, 1001359.486742852)
        XCTAssertEqual(r.estimate, 1_001_000)
        XCTAssertEqual(r.low, 936_000)
        XCTAssertEqual(r.high, 1_066_000)
        XCTAssertEqual(r.baseLabel, "Benchmark 50% · comps 50%")
        XCTAssertEqual(r.usableComparables, 2)
        XCTAssertNil(r.comparablePSF[1])
        assertClose(r.comparablePSF[0]!, 873.9130434782609)
        assertClose(r.comparablePSF[2]!, 838.9830508474577)
        assertClose(r.landTransferTax, 16502.189734857042)
        XCTAssertEqual(r.steps.first!.label, "1,200 sq ft × $877/sq ft")
        XCTAssertEqual(r.steps.map(\.label).filter { $0 == "Penthouse level" }.count, 0)
    }

    // MARK: Pieces

    func testLandTransferTax() {
        XCTAssertEqual(Valuator.landTransferTax(price: 50_000, toronto: false), 250, accuracy: 1e-9)
        XCTAssertEqual(Valuator.landTransferTax(price: 500_000, toronto: false), 6_475, accuracy: 1e-9)
        XCTAssertEqual(Valuator.landTransferTax(price: 500_000, toronto: true), 12_950, accuracy: 1e-9)
        XCTAssertEqual(Valuator.landTransferTax(price: 2_500_000, toronto: false), 48_975, accuracy: 1e-9)
        XCTAssertEqual(Valuator.landTransferTax(price: 3_500_000, toronto: true), 152_950, accuracy: 1e-9)
    }

    func testParkingValueTiers() {
        let downtown = Areas.all[0], brampton = Areas.all[15]
        XCTAssertEqual(Valuator.parkingValue(area: downtown, benchmark: 985), 50_000)
        XCTAssertEqual(Valuator.parkingValue(area: downtown, benchmark: 1000), 65_000)
        XCTAssertEqual(Valuator.parkingValue(area: brampton, benchmark: 575), 35_000)
        XCTAssertEqual(Valuator.parkingValue(area: brampton, benchmark: 800), 45_000)
    }

    func testSquareFootageFloorOf250() {
        let a = Valuator.value(CondoInput(squareFeet: 100), currentYear: year)
        let b = Valuator.value(CondoInput(squareFeet: 250), currentYear: year)
        XCTAssertEqual(a.value, b.value)
    }

    func testFormatting() {
        XCTAssertEqual(Format.currency(788_313.6), "$788,314")
        XCTAssertEqual(Format.currency(487.5), "$488")
        XCTAssertEqual(Format.currency(999), "$999")
        XCTAssertEqual(Format.currency(1_000_000), "$1,000,000")
        XCTAssertEqual(Format.signedCurrency(-6500), "−$6,500")
        XCTAssertEqual(Format.signedCurrency(13428.6), "+$13,429")
        XCTAssertEqual(Format.percent(0.042), "+4.2%")
        XCTAssertEqual(Format.percent(-0.03), "-3.0%")
        XCTAssertEqual(Format.number(1200), "1,200")
    }

    func testInputRoundTripsThroughJSON() throws {
        let data = try JSONEncoder().encode(CondoInput.example)
        let back = try JSONDecoder().decode(CondoInput.self, from: data)
        XCTAssertEqual(back, CondoInput.example)
    }
}
