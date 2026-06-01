# Glass Todo Note Design

## Objective

Build a small macOS desktop sticky-note todo app. The first version is local-only, fast to launch, visually glassy on macOS 26, and focused on task progress.

## Text Prototype

The main window is a compact rounded rectangle floating on the desktop. It has a translucent glass background, a short header with app controls, and a vertical list of todo rows.

Each row contains:

- a task title
- a draggable progress bar
- an optional percentage value
- lightweight row actions for edit and delete

Settings are available from a small toolbar button and include:

- background style
- opacity
- always-on-top
- reminder shake enabled

Completion flow:

1. User drags a row progress bar to 100%.
2. That row enters a locked completing state.
3. A glass-shatter animation plays inside the row bounds.
4. The row fades and collapses out of the list.
5. Soap bubbles rise from the note's top edge.

Reminder flow:

1. The app checks wall-clock time.
2. At minutes `00`, `10`, `20`, `30`, `40`, and `50`, if incomplete tasks remain, it shakes the sticky note window for 3 seconds.
3. Completed or empty lists do not shake.

## Architecture

Use a Swift Package or Xcode project with a SwiftUI app target. Prefer SwiftUI for scenes, controls, animation layers, settings, and state flow. Use narrow AppKit interop for window behavior that SwiftUI does not cover: floating level, transparent shaped window, and deterministic window shaking.

Core modules:

- `App`: app entry point and scene configuration
- `Models`: todo item, progress value, preferences
- `Stores`: todo persistence and preference binding
- `Views`: note window, task row, settings, animation overlays
- `Services`: reminder scheduler and window controller
- `Tests`: model, store, scheduler, and completion state tests

## Data Flow

`TodoStore` owns the list of todos and durable persistence. Views mutate progress through explicit store methods. When progress reaches 100%, the store marks the item as completing instead of deleting it immediately. The UI animation layer observes the completing item, plays the shatter animation, then calls the store to remove it.

`ReminderScheduler` receives the current date and incomplete-task count, then decides whether a shake should fire. The window controller performs the shake.

## Visual Approach

Use system materials and Liquid Glass APIs when available. Keep the main shape a rounded rectangle. The row shatter effect can start as a deterministic SwiftUI particle-like overlay using clipped shards and opacity/offset animation, then be upgraded only if needed. Bubbles should be lightweight SwiftUI circles with glass-like highlights and upward motion.

## Testing

Add tests before implementation for:

- progress clamping from 0...100
- completion transition when progress reaches 100
- removal after animation callback
- scheduler firing only at exact 10-minute boundaries
- no shake when no incomplete todos remain
- preference persistence keys

UI verification later must include launch, opacity setting, always-on-top behavior, row completion animation, bubble celebration, and boundary-minute shake behavior.

## Out Of Scope

- cloud sync
- accounts
- browser UI
- mobile targets
- remote services or accounts
