# Glass Todo Note Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a local macOS SwiftUI sticky-note todo app with draggable progress, Liquid Glass styling, completion celebration, and scheduled shake reminders.

**Architecture:** Use SwiftUI for app structure, rows, settings, and animations. Use narrow AppKit interop for transparent/floating window control and window shaking. Keep durable todo state separate from animation state.

**Tech Stack:** Swift, SwiftUI, AppKit interop, XCTest, local JSON or AppStorage persistence.

---

## Task 1: Project Scaffold

- Create a Swift macOS app project or SwiftPM executable app target.
- Add `App`, `Models`, `Stores`, `Views`, `Services`, and `Tests` directories.
- Make `script/build_and_run.sh` build and launch the app bundle.
- Run build and tests.
- Commit with `yuhua0731 <yuhua364@gmail.com>`.

## Task 2: Todo Model And Store

- Implement `TodoItem`, progress clamping, completion state, and `TodoStore`.
- Add persistence for local todo data.
- Add tests for progress, completion transition, deletion, and persistence.
- Commit with `yuhua0731 <yuhua364@gmail.com>`.

## Task 3: Reminder Scheduler

- Implement scheduler logic for minutes `00`, `10`, `20`, `30`, `40`, `50`.
- Ensure it only fires when incomplete tasks remain.
- Add injectable clock/date tests.
- Commit.

## Task 4: Window Controller

- Implement rounded transparent sticky window.
- Implement opacity preference.
- Implement always-on-top preference via AppKit window level.
- Implement deterministic 3-second shake.
- Add narrow unit tests where possible and manual verification notes.
- Commit.

## Task 5: Main Todo UI

- Build note header, list, row editor, add/delete/edit actions, and draggable progress bars.
- Keep controls compact and desktop-native.
- Add settings UI for background, opacity, always-on-top, and reminder shake.
- Build and manually verify interactions.
- Commit.

## Task 6: Completion Animation

- Add row-bounded glass-shatter animation for 100% progress.
- Fade and collapse completed row after animation callback.
- Add bubble celebration from the top edge of the note.
- Add tests around completion/removal timing and manually verify animation.
- Commit.

## Task 7: Polish And Verification

- Verify Light/Dark mode.
- Verify window opacity and floating level.
- Verify shake at forced boundary times.
- Verify no shake for an empty or fully complete list.
- Run full build/test.
- Commit final local state with `yuhua0731 <yuhua364@gmail.com>`.

## Confirmation Gate

Development starts only after user approval of this prototype and plan.
