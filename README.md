# UsageMenuBar

UsageMenuBar is a private macOS menu bar utility for monitoring Codex usage windows.

It reads live rate-limit data from the local Codex app-server JSON-RPC protocol and shows:

- current 5-hour usage
- weekly 7-day usage
- reset countdowns
- percentage of time left in each reset window

## Build and Test

```sh
swift test
swift build
```

## Package as a Menu Bar App

```sh
Scripts/package_app.sh
open ~/Applications/UsageMenuBar.app
```

The packaged app sets `LSUIElement=true`, so it does not appear in the Dock or Cmd-Tab switcher.
The script also installs it to `~/Applications/UsageMenuBar.app` so Spotlight can find it.

To install somewhere else:

```sh
INSTALL_DIR=/Applications Scripts/package_app.sh
```

The script also writes release artifacts to `.build/dist/`:

- `UsageMenuBar-<version>-macos.zip`

The app is intentionally unsigned. This repository is meant for developers who
can inspect the source and build locally, or download the unsigned release
artifact with the usual macOS Gatekeeper warning tradeoff.

For a GitHub release:

```sh
APP_VERSION=0.1.0 BUILD_NUMBER=1 Scripts/package_app.sh
gh release create v0.1.0 \
  .build/dist/UsageMenuBar-0.1.0-macos.zip \
  --title "UsageMenuBar 0.1.0" \
  --generate-notes \
  --verify-tag \
  --draft
```
