# DropShelf

A lightweight macOS menubar app that gives you a temporary file shelf — accessible by shaking your mouse while dragging.

## What it does

Drop files onto the shelf while you work, then drag them out later to any folder or app. All files are stacked together so you can move them all at once in a single drag.

## How to use

1. Start dragging a file
2. Shake your mouse horizontally — the shelf appears near your cursor
3. Drop the file onto the shelf
4. Repeat for as many files as you want
5. Drag from the shelf to move all files to their destination at once

## Features

- Shake-to-open gesture detection while dragging
- Stacked card UI — all files treated as one bundle
- Right-click any file for Open / Reveal in Finder / Remove
- Menubar icon with Show/Hide, Clear, and Launch at Login options
- Remembers window position between sessions
- No Dock icon — lives quietly in your menubar

## Requirements

- macOS 13.0 or later
- Apple Silicon or Intel Mac

## Build & Run

```sh
# Build and open
make run

# Install to /Applications
make install

# Clean build artifacts
make clean
No Xcode required. Built with Swift + AppKit, compiled directly with swiftc.

Tech
Swift + AppKit (no SwiftUI, no Xcode)
Global mouse event monitoring via NSEvent
Custom NSCollectionViewLayout for stacked card UI
ServiceManagement for login item registration
