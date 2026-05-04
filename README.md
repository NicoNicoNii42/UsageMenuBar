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
open .build/UsageMenuBar.app
```

The packaged app sets `LSUIElement=true`, so it does not appear in the Dock or Cmd-Tab switcher.
