# GTA Condo Value for iOS

A native SwiftUI port of the web tool in `../index.html`. Same 25 area benchmarks, same adjustments, same comparable-sales blend, value range and land transfer tax.

## Layout

- `CondoValuationKit/` is a Swift package with all of the valuation logic (`Valuator.swift`, `Areas.swift`, `CondoInput.swift`, `Format.swift`) and its unit tests. It has no UI and runs on macOS, iOS and Linux.
- `GTACondoValue/` is the SwiftUI app: a single form with the estimate at the top, inputs grouped like the web page, comparables you can add and swipe to delete, and the line-by-line breakdown. Inputs are saved between launches.
- `GTACondoValue.xcodeproj` is the Xcode project. It uses the local package above.

## Run it

You need a Mac with Xcode 16 or later (the project uses Xcode 16's folder-synced groups). iOS 17 or later.

1. Clone the repo and open `ios/GTACondoValue.xcodeproj` in Xcode.
2. Pick an iPhone simulator in the toolbar and press Run (⌘R).
3. To run on your own iPhone: select the **GTACondoValue** target, open **Signing & Capabilities**, choose your Team (a free Apple ID works for personal installs), and change the bundle identifier from `com.example.GTACondoValue` to something unique such as `com.yourname.GTACondoValue`. Plug in the phone, select it as the destination, and press Run.

## Tests

The tests check the Swift port against numbers produced by the web page's own `calc()` and `ltt()` for four different condos, plus the tax brackets, parking tiers and formatting.

- In Xcode: Product → Test (⌘U) with the GTACondoValue scheme.
- From a terminal: `swift test --package-path ios/CondoValuationKit`

GitHub Actions runs both the tests and an app build on every push that touches `ios/` (see `.github/workflows/ios.yml`).

## Keeping it in step with the web tool

The benchmarks live in `CondoValuationKit/Sources/CondoValuationKit/Areas.swift`. When you update the `AREAS` table in `index.html`, update the same numbers there. Any change to the formulas in `calc()` needs the matching change in `Valuator.swift`.
