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

## Table of Contents
 
- [The tech stack used in this project](#tech-stack)
- [Project Overview](#project-overview)
- [Features offered](#️features)
- [Requirements](#requirements)
- [Project Structure](#️project-structure)
- [What is Offline-First Architecture?](#what-is-offline-first-architecture)
- [Why These Are Used](#why-these-are-used)
- [Security & Risks](#️security-&-risks)
- [System Architecture](#️system-architecture)
- [How It Works](#how-it-works)


---

### Tech Stack

- **Frontend:** Flutter Web (Dart)
- **Local Storage:** Sembast (wraps IndexedDB on web)
- **Backend / DB:** Supabase (PostgreSQL + Realtime WebSockets)
- **Auth:** Google OAuth via Supabase Auth
- **Deployment:** Vercel (auto-builds from `main` branch via `build.sh`)
- **Core Concept:** Offline-first architecture with background sync

---

### Project Overview

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

### Features

- ✅ Add, edit, delete, and complete tasks
- 📶 Fully offline-first — works with no internet, syncs automatically when reconnected
- 🔄 Live cross-device sync via Supabase Realtime (WebSockets)
- 🔐 Google OAuth login (guest mode also supported)
- 🔍 Search and filter by priority, category, or deadline
- 📱 Responsive layout (mobile + desktop breakpoints)
- ⚡ Tab-visibility aware refresh (handles browser tab throttling)
- 🎨 Clean dark-themed UI with a neon green accent

---

### Requirements

- Install **Flutter SDK** (stable channel)
- A **Supabase** project (free tier works) — for the database, auth, and Realtime
- A **Google Cloud OAuth Client** — for Google Sign-In
- (Optional) **Vercel** account — for deployment

---

### Project Structure

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

### What is Offline-First Architecture?

- Think of the local database (Sembast) as your **primary source**, and the remote database (Supabase) as the **backup and sync layer**
- Every write goes to Sembast **first**, so the UI updates instantly regardless of network status
- An `isSynced` flag on each task tracks whether it has been pushed to Supabase yet
- When the internet reconnects, all pending (`isSynced: false`) tasks are automatically pushed
- Supabase Realtime pushes back any changes made from *other* devices, keeping every open session consistent

---

### Why These Are Used
 
**Supabase:**
- Used as the **remote source of truth** for tasks once a user is logged in — every task eventually lands here so it's never lost even if local storage is cleared
- **Realtime (WebSockets)** is used instead of manual polling so that a task added on your phone shows up instantly on your laptop, without refreshing
- `REPLICA IDENTITY FULL` is required on the table specifically because Postgres's default replication only sends the primary key on `DELETE` events — full row data is needed so the app knows *which* task was deleted, not just its ID
- Chosen over a custom backend because it gives Postgres + Auth + Realtime + Edge Functions in one place — ideal for a solo learning project where building your own backend from scratch isn't the point

**Google OAuth:**
- Used so a user's tasks can follow them across devices instead of being trapped in one browser's local storage
- Chosen over building custom email/password auth because OAuth offloads password security, session handling, and account recovery to Google — letting the focus stay on Flutter itself, not reinventing auth
- Supabase Auth sits in front of Google OAuth so the same `user.id` can be used consistently across the database, Realtime filters, and OneSignal targeting — one identity, three systems

---

### Security & Risks
 
This project's Supabase **Project URL** and **anon (public) key** are visible in the client-side code and compiled JS bundle. This is intentional and expected — Supabase is designed so the anon key can be public, the same way a website's domain name isn't a secret. That said, it's worth understanding exactly what that does and doesn't expose.
 
**What the anon key + URL alone cannot do:**
- Cannot bypass Row Level Security (RLS) — that requires the `service_role` key, a completely separate and far more dangerous secret that must never appear in any client-side code
- Cannot access the Supabase dashboard, billing, or project settings
- Cannot run arbitrary SQL against the database

**What the anon key *can* do — and why RLS is the real safeguard:**
- Anyone with the anon key can call the REST API directly (no app required — a simple `curl` request works)
- If Row Level Security is **disabled**, or a policy is too permissive (e.g. `USING (true)`), that request could read or modify **any row in the table**, not just the caller's own data
- The actual security boundary is the RLS policy on the `focus_hub` table, which restricts every operation to `auth.uid() = "User_id"` — the key being public is irrelevant as long as this policy is correct

**Other secrets in this project and how they're protected:**
- The Supabase **service role key** is never used in this project's Flutter code at all — only the anon key, which is safe by design under RLS

**Planned improvement:** migrating from the legacy anon key format to Supabase's newer `sb_publishable_...` key before the 2026 deprecation deadline — a value swap only, with no change to the security model above.

---

### System Architecture

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

### How It Works

1️⃣ User adds/edits/completes a task → written to **Sembast** instantly (UI updates immediately)

2️⃣ If online, the same task is pushed (upserted) to **Supabase** in the background

3️⃣ **Supabase Realtime** broadcasts the change over a WebSocket channel to every other device logged into the same account

4️⃣ Each connected device receives the change and updates its local Sembast copy, keeping all devices in sync without manual refresh

5️⃣ If a device goes offline, all local changes are queued (`isSynced: false`) and automatically retried once connectivity returns

6️⃣ On login, any tasks created as a guest can be optionally synced and merged into the user's account

---

### Status

This is a **live learning project**, not a finished product — actively being improved as new Flutter concepts are learned and applied.
