# Glass Todo Note Rules

## Product Goal

Build a small macOS desktop todo sticky note.

## Required Behavior

- The app shows a rounded-rectangle sticky note window on the desktop.
- Each todo row shows task text and a progress bar.
- Users can drag a task progress bar to update completion progress.
- When a task reaches 100%, only that row plays a glass-shatter completion animation and the task fades away.
- After a task completes, soap bubbles rise from the top of the sticky note as a celebration effect.
- If any incomplete tasks remain, the whole sticky note window shakes for 3 seconds every 10 minutes at wall-clock minutes `00`, `10`, `20`, `30`, `40`, and `50`.

## Window and Style

- Target macOS 26 visual style with SwiftUI Liquid Glass where available.
- Prefer native SwiftUI/macOS materials and controls before custom blur.
- The sticky note has a rounded-rectangle shape.
- Users can configure background appearance, transparency, and whether the window floats above other windows.
- The app must support Light and Dark mode.
- Settings should be desktop-native, not hidden behind gesture-only UI.

## Engineering Rules

- Use SwiftUI first.
- Use AppKit only for window-level behavior SwiftUI cannot express cleanly, such as always-on-top, frameless shaping, or controlled window shaking.
- Keep files small and split by responsibility from the start.
- Use `@AppStorage` for user preferences.
- Use an observable store for todo state.
- Keep animation state separate from durable todo data.
- Add tests for progress completion, removal timing, reminder scheduling, and persistence behavior before broad UI work.

## Constraints

- Do not implement browser, cloud sync, accounts, notifications, collaboration, or iOS support in the first version.
- Use `yuhua0731 <yuhua364@gmail.com>` for commits and pushes.
- No confirmation is needed before local commits or pushes.
- Commit and push as appropriate for each development step.
