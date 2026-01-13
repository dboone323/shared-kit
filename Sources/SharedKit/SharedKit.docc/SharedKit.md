//
// SharedKit.docc/SharedKit.md
// Step 48: DocC Documentation
//

# SharedKit

Shared utilities and components for iOS applications.

## Overview

SharedKit provides common functionality used across all iOS projects in the Tools-Automation workspace:

- **Accessibility**: Labels and VoiceOver support
- **Localization**: Multi-language string resources
- **Networking**: Common HTTP utilities
- **Security**: Keychain and biometric helpers

## Topics

### Accessibility

- ``AccessibilityLabels``
- ``AccessibilityAnnouncer``

### Localization

Localization strings are provided in `Resources/[lang].lproj/Localizable.strings`.

Supported languages:
- English (en)

### Usage

Add SharedKit as a dependency in your Swift Package:

```swift
dependencies: [
    .package(path: "../Shared-Kit")
]
```

Then import in your code:

```swift
import SharedKit
```

### Example: Accessibility

```swift
Button("Save") {
    // action
}
.accessibleButton(AccessibilityLabels.saveButton)
```

### Example: Localization

```swift
Text(NSLocalizedString("action.save", bundle: .module, comment: ""))
```

## See Also

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Accessibility Best Practices](https://developer.apple.com/accessibility/)
