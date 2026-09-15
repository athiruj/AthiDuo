# AthiDuo product specification

## Product boundary

AthiDuo is a personal, local-only Apple-silicon macOS 26+ utility forked from MacDuo `v0.1.14`. It offers one fixed Duo effect only; it has no updater, telemetry, accounts, networking, packaging installer, or Intel support.

## Experience

- The app lives in the menu bar and has one English native settings window.
- The settings window shows a visual preview, activation state, intensity, hold-while-still, and open-at-login. It contains no Advanced section.
- The menu-bar menu exposes everyday adjustments: activation, Soft/Balanced/Bold intensity, hold-while-still, open-at-login, reference-angle calibration, and opening the settings window.
- On first launch, open at login is enabled when macOS accepts the registration. If Screen Recording permission was previously granted, the app auto-activates.

## Fold and privacy behavior

- At the beginning of a lid movement, capture one desktop frame in memory and transform it with the Duo effect.
- Keep the overlay while the lid is still; clicking it, pressing Escape, or pressing Control-Option-Command-F dismisses it.
- After dismissal, do not show the effect again until the lid returns within the reference-angle zone. Calibrate that reference from the current lid angle.
- The app stores no screen images and sends no data off-device.

## Verification

`swift build`, `swift run AthiDuo --core-check`, `swift run AthiDuo --render-check`, and `bash build.sh` must succeed on the supported environment.
