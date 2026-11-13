import SwiftUI
import CondoValuationKit

struct ContentView: View {
    @EnvironmentObject private var store: ValuationStore

    var body: some View {
        let result = store.valuation
        NavigationStack {
            Form {
                Section {
                    ResultCard(result: result, toronto: store.area.toronto)
                }
                locationSection
                unitSection
                positionSection
                buildingSection
                ComparablesSection(result: result)
                BreakdownSection(result: result)
                Section {
                    Text("A planning estimate, not an appraisal. Area benchmarks are approximate 2025–26 resale averages, not a live feed. Confirm values with a REALTOR® CMA or a licensed appraiser.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("GTA Condo Value")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Load example", systemImage: "arrow.counterclockwise") { store.resetToExample() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
        }
    }

    // MARK: Sections

    private var locationSection: some View {
        Section("Location") {
            Picker("Area", selection: Binding(get: { store.input.areaIndex }, set: { store.selectArea($0) })) {
                ForEach(Areas.regions) { region in
                    Section(region.name) {
                        ForEach(region.areas) { area in
                            Text(area.name).tag(Areas.index(of: area))
                        }
                    }
                }
            }
            .pickerStyle(.navigationLink)
            NumberRow(title: "Benchmark $/sq ft", value: $store.input.benchmarkPSF)
        }
    }

    private var unitSection: some View {
        Section("Unit") {
            NumberRow(title: "Interior size (sq ft)", value: $store.input.squareFeet)
            Picker("Bedrooms", selection: $store.input.bedrooms) {
                Text("Studio").tag(0)
                Text("1").tag(1)
                Text("2").tag(2)
                Text("3+").tag(3)
            }
            Picker("Bathrooms", selection: $store.input.bathrooms) {
                ForEach(BathroomOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Den", isOn: $store.input.den)
        }
    }

    private var positionSection: some View {
        Section("Position and finish") {
            Stepper(value: $store.input.floor, in: 1...90) {
                LabeledContent("Floor", value: "\(store.input.floor)")
            }
            Picker("View / exposure", selection: $store.input.view) {
                ForEach(ViewOption.allCases) { Text($0.label).tag($0) }
            }
            Picker("Outdoor space", selection: $store.input.outdoor) {
                ForEach(OutdoorOption.allCases) { Text($0.label).tag($0) }
            }
            Picker("Condition", selection: $store.input.condition) {
                ForEach(ConditionOption.allCases) { Text($0.label).tag($0) }
            }
            Toggle("Penthouse / sub-PH level", isOn: $store.input.penthouse)
            Toggle("Corner unit", isOn: $store.input.corner)
        }
    }

    private var buildingSection: some View {
        Section("Building and extras") {
            IntRow(title: "Year built", value: $store.input.yearBuilt)
            NumberRow(title: "Monthly maintenance ($)", value: $store.input.maintenanceFee)
            Picker("Parking spaces", selection: $store.input.parkingSpaces) {
                ForEach(0...2, id: \.self) { Text("\($0)").tag($0) }
            }
            Picker("Lockers", selection: $store.input.lockers) {
                ForEach(0...1, id: \.self) { Text("\($0)").tag($0) }
            }
            Toggle("Full amenities (gym, pool, concierge)", isOn: $store.input.fullAmenities)
            Toggle("Steps to subway, LRT or GO", isOn: $store.input.nearTransit)
        }
    }
}

// MARK: - Result

struct ResultCard: View {
    let result: Valuation
    let toronto: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Estimated market value")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(Format.currency(result.estimate))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("Likely range \(Format.currency(result.low)) – \(Format.currency(result.high))")
                .font(.subheadline)
            Label(result.confidence.label, systemImage: confidenceIcon)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(confidenceColor)
            Divider()
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow {
                    Text("Value per sq ft").foregroundStyle(.secondary)
                    Text(Format.currency(result.pricePerSquareFoot)).monospacedDigit()
                }
                GridRow {
                    Text("Starting $/sq ft").foregroundStyle(.secondary)
                    Text(Format.currency(result.basePSF)).monospacedDigit()
                }
                GridRow {
                    Text(toronto ? "Land transfer tax (ON + Toronto)" : "Land transfer tax (Ontario)")
                        .foregroundStyle(.secondary)
                    Text(Format.currency(result.landTransferTax)).monospacedDigit()
                }
            }
            .font(.subheadline)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }

    private var confidenceIcon: String {
        switch result.confidence {
        case .higher: return "checkmark.seal"
        case .medium: return "chart.bar"
        case .benchmarkOnly: return "exclamationmark.triangle"
        }
    }

    private var confidenceColor: Color {
        switch result.confidence {
        case .higher: return .green
        case .medium: return .orange
        case .benchmarkOnly: return .red
        }
    }
}

// MARK: - Comparables

struct ComparablesSection: View {
    @EnvironmentObject private var store: ValuationStore
    let result: Valuation

    var body: some View {
        Section {
            ForEach($store.input.comparables) { $comp in
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Address", text: $comp.address)
                        .font(.body.weight(.medium))
                    HStack {
                        LabeledField(title: "Sold price", value: $comp.soldPrice)
                        LabeledField(title: "Sq ft", value: $comp.squareFeet)
                        LabeledField(title: "Months ago", value: $comp.monthsAgo)
                    }
                    HStack {
                        Toggle("Sold with parking", isOn: $comp.soldWithParking)
                            .font(.subheadline)
                    }
                    if let psf = adjustedPSF(for: comp.id) {
                        Text("Adjusted \(Format.currency(psf))/sq ft")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .onDelete(perform: store.removeComparables)

            Button("Add comparable", systemImage: "plus.circle") { store.addComparable() }

            NumberRow(title: "Market change since sale (% / month)", value: $store.input.monthlyTrendPercent)
        } header: {
            Text("Recent comparables (optional)")
        } footer: {
            Text("Sold units in the same or nearby buildings. Prices are moved to today's market with the monthly change, parking is taken out, and the result is blended with the benchmark: 30% for one sale, 50% for two, 70% for three or more.")
        }
    }

    private func adjustedPSF(for id: UUID) -> Double? {
        guard let i = store.input.comparables.firstIndex(where: { $0.id == id }),
              i < result.comparablePSF.count else { return nil }
        return result.comparablePSF[i]
    }
}

// MARK: - Breakdown


struct BreakdownSection: View {
    let result: Valuation

    var body: some View {
        Section("How we got there") {
            ForEach(Array(result.steps.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.label)
                        if let r = step.rate {
                            Text(Format.percent(r)).font(.caption).foregroundStyle(.secondary).monospacedDigit()
                        }
                        if i == 0 {
                            Text(result.baseLabel).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(i == 0 ? Format.currency(step.amount) : Format.signedCurrency(step.amount))
                        .monospacedDigit()
                        .foregroundStyle(i == 0 ? Color.primary : step.amount >= 0 ? Color.green : Color.red)
                }
                .font(.subheadline)
            }
            HStack {
                Text("Estimated value").bold()
                Spacer()
                Text(Format.currency(result.value)).bold().monospacedDigit()
            }
        }
    }
}

// MARK: - Inputs

struct NumberRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        LabeledContent(title) {
            TextField(title, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
    }
}

struct IntRow: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        LabeledContent(title) {
            TextField(title, value: $value, format: .number.grouping(.never))
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
    }
}

struct LabeledField: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField(title, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .monospacedDigit()
        }
    }
}

#Preview {
    ContentView().environmentObject(ValuationStore())
}
