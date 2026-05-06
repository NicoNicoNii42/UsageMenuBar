# UsageMenuBar

UsageMenuBar is a private macOS menu bar utility for monitoring Codex usage windows.

It reads live rate-limit data from the local Codex app-server JSON-RPC protocol and shows:

- current 5-hour usage
- weekly 7-day usage
- reset countdowns
- percentage of time left in each reset window

<img width="392" height="399" alt="image" src="https://github.com/user-attachments/assets/5434deb8-0345-4761-b8b2-2706a2a68784" />


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

Release builds are ad-hoc signed, which does not require an Apple Developer
account. They are not notarized, so macOS may still block the downloaded app
because it came from the internet.

If you trust the source and downloaded release, remove the quarantine attribute
after extracting the ZIP:

```sh
xattr -dr com.apple.quarantine ~/Applications/UsageMenuBar.app
open ~/Applications/UsageMenuBar.app
```

Building locally with `Scripts/package_app.sh` is the preferred install path for
developers.

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
