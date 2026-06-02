## 1.0.1+vendored

Forked from upstream 1.0.1 and vendored into this repo (consumed via a path
dependency). Changes:

* 🎨 Themed the built-in app picker to the host app via `colorScheme.primary`
* 🔧 Removed the deprecated manifest `package=` attribute (AGP 8 `namespace`)
* 🧹 Stripped `example/`, tests, screenshots and unused plugin boilerplate
* 🚫 `publish_to: "none"` — internal only

## 1.0.1

* 🏷️ Added `topics` for better pub.dev search discoverability
* 🔗 Updated homepage URL

## 1.0.0

* 🎉 Initial release
* ✨ Beautiful built-in UPI app picker bottom sheet
* 🔒 NPCI-compliant `upi://pay` URL construction
* ✅ VPA validator with regex-based validation
* 📱 Full Android + iOS support
* 🤖 Android 11+ ready with `<queries>` manifest support
* 🌙 Dark mode support in app picker
* 🧪 Type-safe models: `UpiPayment`, `UpiResponse`, `UpiApp`
* 📦 Zero bloated dependencies
