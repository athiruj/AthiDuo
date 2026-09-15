# AthiDuo

A personal, local-only macOS utility that folds one in-memory desktop snapshot as a compatible MacBook lid moves.

## What it does

- Uses the built-in lid-angle sensor when the hardware exposes a continuous reading.
- Captures one desktop frame only when a lid gesture starts; it never saves or uploads that frame.
- Holds the transformed frame while the lid is still, then dismisses with a click, `Esc`, or `⌃⌥⌘F`.
- Re-arms once the lid returns near its auto-calibrated reference angle.

## Requirements

- Apple-silicon MacBook with a readable continuous lid-angle sensor.
- macOS 26 or newer.
- Screen Recording permission, requested by macOS only when AthiDuo activates.

## Build

```sh
swift build
swift run AthiDuo --core-check
swift run AthiDuo --render-check
bash build.sh
```

`build.sh` produces `build/AthiDuo.app` and a drag-to-install `build/AthiDuo.dmg`, both with ad-hoc signing. Open the DMG and drag AthiDuo onto the Applications alias. A rebuilt ad-hoc app can require Screen Recording approval again; macOS can also require a Control-click → Open on the first launch because the app is not notarized.

## Load from GitHub

```sh
git clone https://github.com/<your-account>/AthiDuo.git
cd AthiDuo
swift build
swift run AthiDuo --core-check
bash build.sh
```

## Menu-bar controls

The AthiDuo icon in the macOS menu bar provides the everyday controls: activate or pause, choose Soft/Balanced/Bold intensity, hold the image while still, open at login, calibrate the reference angle, and open the full settings window.

## Privacy

The app has no accounts, telemetry, updater, network calls, or analytics. It captures no audio and keeps the active desktop snapshot only in bounded memory.

## Credits

AthiDuo is a personal fork of [DhananjayBhosale/MacDuo](https://github.com/DhananjayBhosale/MacDuo) at `v0.1.14`, released under the MIT License. Upstream copyright and technical attributions are retained in [ATTRIBUTION.md](ATTRIBUTION.md).
