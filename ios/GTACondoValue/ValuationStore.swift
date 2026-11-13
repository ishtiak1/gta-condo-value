import Foundation
import CondoValuationKit

/// Holds the user's inputs, saves them between launches, and exposes the current valuation.
@MainActor
final class ValuationStore: ObservableObject {
    private static let storageKey = "gta-condo"

    @Published var input: CondoInput {
        didSet { save() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(CondoInput.self, from: data) {
            input = saved
        } else {
            input = .example
        }
    }

    private let defaults: UserDefaults

    var valuation: Valuation { Valuator.value(input) }
    var area: Area { Areas.area(at: input.areaIndex) }

    /// Picking a new area resets the benchmark to that area's figure, as the web tool does.
    func selectArea(_ index: Int) {
        input.areaIndex = index
        input.benchmarkPSF = Areas.area(at: index).psf
    }

    func addComparable() {
        input.comparables.append(ComparableSale())
    }

    func removeComparables(at offsets: IndexSet) {
        input.comparables.remove(atOffsets: offsets)
    }

    func resetToExample() {
        input = .example
    }

    private func save() {
        if let data = try? JSONEncoder().encode(input) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }
}
