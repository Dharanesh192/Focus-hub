## 📌 About Focus Hub

Focus Hub is a **Flutter Web PWA task management app**, built primarily as a learning project to master Flutter fundamentals while shipping a real/production-level web application.

What started as a simple to-do list evolved into a fully offline-first, cross-device synced task manager — backed by a real database, real-time WebSocket sync, Google authentication.

This project demonstrates how a modern Flutter Web app can:
- Work fully offline using local storage
- Sync data live across multiple devices in real time
- Authenticate users securely via OAuth
- Deploy as a PWA with a proper CI/CD pipeline

Instead of only working with local state, this app talks to a real backend (Supabase) and keeps local and remote data in sync automatically — making it lightweight for the user (works offline) and reliable (auto-syncs when back online).

---

## Tech Stack

- **Frontend:** Flutter Web (Dart)
- **Local Storage:** Sembast (wraps IndexedDB on web)
- **Backend / DB:** Supabase (PostgreSQL + Realtime WebSockets)
- **Auth:** Google OAuth via Supabase Auth
- **Deployment:** Vercel (auto-builds from `main` branch via `build.sh`)
- **Core Concept:** Offline-first architecture with background sync

---

## Project Overview

This project focuses on building an offline-first, cross-device task manager using Flutter Web.

The system connects:
- **Sembast** — for instant local reads/writes, so the app works even with no internet
- **Supabase** — as the source of truth once the user is online and logged in
- **Realtime channel** — to push live updates (insert/update/delete) to every open device instantly

The Flutter app acts as a bridge between:

```
Local UI (Flutter Web) ⇄ Sembast (offline cache) ⇄ Supabase (Postgres + Realtime)
```

Main objectives of this project:
- Understand offline-first architecture and local-vs-remote data reconciliation
- Learn real-time sync using WebSockets (Supabase Realtime)
- Implement secure OAuth login on Flutter Web
- Build and ship a working PWA with a real deployment pipeline

This project is ideal for people who want to understand:
- Offline-first app design (local DB + remote DB reconciliation)
- Realtime data sync using WebSockets
- OAuth authentication flows on the web
- Environment variable handling in compiled web apps
- Push notification delivery for a PWA

---

## Features

- ✅ Add, edit, delete, and complete tasks
- 📶 Fully offline-first — works with no internet, syncs automatically when reconnected
- 🔄 Live cross-device sync via Supabase Realtime (WebSockets)
- 🔐 Google OAuth login (guest mode also supported)
- 🔍 Search and filter by priority, category, or deadline
- 📱 Responsive layout (mobile + desktop breakpoints)
- ⚡ Tab-visibility aware refresh (handles browser tab throttling)
- 🎨 Clean dark-themed UI with a neon green accent

---

## How to Run the Code

- Clone the repository:
  ```
  git clone https://github.com/Dharanesh192/Flutter-Todo-List.git
  cd Flutter-Todo-List
  ```
- Get Flutter packages:
  ```
  flutter pub get
  ```
- Run locally with your own Supabase credentials replace the existing one with yours 

- You may want to set up your own Supabase project and schema, and Google OAuth credentials to fully test all features locally.

---

## Requirements

- Install **Flutter SDK** (stable channel)
- A **Supabase** project (free tier works) — for the database, auth, and Realtime
- A **Google Cloud OAuth Client** — for Google Sign-In
- (Optional) **Vercel** account — for deployment

---

## Project Structure

```
Flutter-Todo-List/
├── lib/
│   ├── main.dart              # App entry point, auth state listener
│   ├── models/
│   │   └── task_model.dart    # TaskModel with Sembast/Supabase mappers
│   ├── repository/
│   │   └── task_repository.dart  # All local + remote data operations
│   └── Screen/
│       ├── task_view.dart     # Task list UI + Realtime listener
│       ├── add_task.dart      # Add task bottom sheet
│       ├── edit_screen.dart   # Edit task bottom sheet
│       └── widget.dart        # Shared widgets, snackbars, auth screens
├── build.sh                   # Custom Vercel build script
└── pubspec.yaml
```

---

## What is Offline-First Architecture?

- Think of the local database (Sembast) as your **primary source**, and the remote database (Supabase) as the **backup and sync layer**
- Every write goes to Sembast **first**, so the UI updates instantly regardless of network status
- An `isSynced` flag on each task tracks whether it has been pushed to Supabase yet
- When the internet reconnects, all pending (`isSynced: false`) tasks are automatically pushed
- Supabase Realtime pushes back any changes made from *other* devices, keeping every open session consistent

---

## System Architecture

```
        Flutter Web UI
              ⇅
     Sembast (Local/IndexedDB)
              ⇅
   Supabase (Postgres + Realtime)
              ⇅
        Google OAuth       
```

---

## How It Works

1️⃣ User adds/edits/completes a task → written to **Sembast** instantly (UI updates immediately)

2️⃣ If online, the same task is pushed (upserted) to **Supabase** in the background

3️⃣ **Supabase Realtime** broadcasts the change over a WebSocket channel to every other device logged into the same account

4️⃣ Each connected device receives the change and updates its local Sembast copy, keeping all devices in sync without manual refresh

5️⃣ If a device goes offline, all local changes are queued (`isSynced: false`) and automatically retried once connectivity returns

6️⃣ On login, any tasks created as a guest can be optionally synced and merged into the user's account

---

## Status

This is a **live learning project**, not a finished product — actively being improved as new Flutter concepts are learned and applied.
