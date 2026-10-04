# Build HAM EXAMer for iOS

HAM EXAMer is a native SwiftUI iPhone app. The Xcode project and scheme retain the internal name `TechnicianRadio`; the app's display name is `Radio Study`.

## Requirements

- macOS with Xcode and an installed iOS Simulator runtime.
- iOS 17 or later on the target device.
- An Apple development team for installation on a physical iPhone. Simulator builds do not require signing credentials.

## Run in Xcode

1. Clone this repository.
2. Open `TechnicianRadio.xcodeproj`.
3. Select the `TechnicianRadio` scheme and an installed iPhone Simulator.
4. Run the app.
5. Select English during onboarding to see the English study experience.

For a physical device, select your own development team and a unique bundle identifier in Signing & Capabilities. No signing certificates, provisioning profiles, or distribution archives are included in the repository.

## Command-line build

Keep build caches outside the project and cloud-synced folders. Xcode uses its standard Derived Data location under `~/Library/Developer/Xcode/DerivedData`; command-line builds and tests below use the `HAMExamHelper` directory there. Use the same `-derivedDataPath` option when archiving.

```sh
xcodebuild -project TechnicianRadio.xcodeproj \
  -scheme TechnicianRadio \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath "$HOME/Library/Developer/Xcode/DerivedData/HAMExamHelper" \
  CODE_SIGNING_ALLOWED=NO build
```

## Verify the bundled data

```sh
python3 Tools/validate_data.py
```

This checks question counts, group counts, diagrams, answer mappings, and completeness of all bundled study languages.

## Run the tests

List installed devices with `xcrun simctl list devices available`, then substitute an available iPhone Simulator name below:

```sh
xcodebuild -project TechnicianRadio.xcodeproj \
  -scheme TechnicianRadio \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -derivedDataPath "$HOME/Library/Developer/Xcode/DerivedData/HAMExamHelper" \
  CODE_SIGNING_ALLOWED=NO test
```

## Project layout

| Path | Contents |
| --- | --- |
| `Views/` | Learning, flashcards, mock exams, onboarding, settings, and shared visual components |
| `Models/` | Question, study progress, exam, and persistence models |
| `Services/` | Bundled data loading and app state |
| `Resources/` | Official English Technician pool, diagrams, explanations, and privacy manifest |
| `Assets.xcassets/` | App icons and asset catalog |
| `Tests/` | Data integrity, exam behavior, answer ordering, persistence, and study-flow tests |

## Study languages and local storage

The app includes explanations in English, Chinese, Korean, Vietnamese, and Spanish. Official questions and answer choices remain in English. Optional translations are learning aids; the English pool remains authoritative.

No account or network connection is required. Progress, flashcards, and an in-progress mock exam are stored locally. Live website-account sync is not enabled; see [the integration notes](../BACKEND_INTEGRATION.md).

## Release status

This repository contains the Technician iOS project. General and Amateur Extra assistants are planned and are not implemented in the current build. Build caches, personal Xcode state, signing files, and internal release artifacts are excluded from version control.
