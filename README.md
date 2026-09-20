# 🚀 SmartEve & Stage Flow
### *"Your Mission-Critical Live Event Co-Pilot"*

> **SmartEve** is an enterprise-grade live event coordination and stage management platform featuring a deterministic schedule reflow engine, real-time multi-device synchronization, direct Neon PostgreSQL database integration, quad-tier fail-safe AI anchor assistance, and a modern light-themed UI.

---

## 📌 1. Project Overview

During live events (conferences, auditoriums, summits, product launches), schedule shifts are inevitable: keynote presentations run overtime, VIP speakers arrive late, or impromptu stage announcements are required. Traditional paper agendas and manual chat channels fail under high-pressure scenarios, causing cascading delays and audience confusion.

**SmartEve solves this by providing:**
1. **Deterministic Schedule Reflow Engine**: When a session runs overtime or an organizer triggers a time adjustment (e.g., `+15m`), the system instantly recalculates downstream start times across the entire agenda while preserving hard stops (e.g., lunch breaks, venue closures) and safety buffer breaks.
2. **Direct Neon PostgreSQL Integration**: Real-time database sync over TLS with automatic schema provisioning, ENUM status compatibility, and fallback error handling.
3. **Multi-Role Tailored Interfaces**:
   - **Organizer Control Room**: Instant oversight of live session timers, speaker arrival statuses, and delay controls.
   - **Anchor Teleprompter & Dashboard**: Equips stage hosts with AI-generated speaker intros, stage talking points, auto-scrolling teleprompter, and built-in Text-to-Speech (TTS) read-aloud capabilities.
   - **Public Stage Display**: High-contrast, oversized countdown billboard tailored for stage projectors and backstage monitors.
   - **Interactive Agenda View**: Timeline of all event sessions, speaker profiles, and live status tags.
4. **Quad-Tier Fail-Safe AI Assistant**: Generates professional stage prose and emergency announcements with automatic cascading across multiple LLM inference providers (**Google Gemini → Groq Llama 3.3 → Nvidia NIM → OpenRouter → Offline Templates**) to guarantee 100% stage uptime.

---

## 🛠️ 2. Technology Stack

### **Frontend (Flutter Mobile App)**
- **Framework**: Flutter SDK (Dart)
- **State Management**: Provider (`provider: ^6.1.2`) using `ChangeNotifier` for reactive UI updates and real-time countdown tickers
- **Design System & Theme**: Custom Slate Light Theme (`#F8FAFC` background, `#FFFFFF` card surfaces, `#2563EB` Royal Blue accents, `#10B981` Live Green, `#0F172A` Slate 900 typography) with Google Fonts (`Inter`)
- **Database Client**: `postgres` package for direct serverless PostgreSQL communication
- **Speech Synthesis**: `flutter_tts` for on-device script read-aloud and anchor practice
- **Media CDN**: `cached_network_image` and `image_picker` integrated with Cloudinary CDN
- **Push Alerts**: `firebase_messaging` & `flutter_local_notifications`

### **Backend (API Server)**
- **Runtime & Language**: Node.js & TypeScript (`.ts`)
- **HTTP Framework**: Express.js
- **Validation**: Zod schema validation
- **Testing**: Vitest unit test suite

### **Database & Cloud Infrastructure**
- **Primary Database**: **[Neon.tech](https://neon.tech)** Serverless PostgreSQL with TLS connection pooling
- **Authentication**: **Firebase Authentication** with resilient direct Neon DB user fallback (`AuthService`)
- **Push Notifications**: **Firebase Cloud Messaging (FCM)** for instant stage alerts
- **Media Optimization**: **Cloudinary CDN** with face-detection auto-cropping for speaker avatars

### **AI Inference Pipeline**
- **Tier 1**: Google Gemini API
- **Tier 2**: Groq Cloud (Llama 3.3 70B Versatile)
- **Tier 3**: Nvidia NIM Microservices API
- **Tier 4**: OpenRouter Universal Gateway
- **Tier 5 (Offline Guarantee)**: Pre-compiled local stage script templates

---

## 📈 3. Comprehensive Project Progress (Work Completed)

### 🐘 A. Direct Neon PostgreSQL Database Integration & ENUM Fixes
- **Serverless PostgreSQL Engine (`lib/core/services/neon_database_service.dart`)**:
  - Replaced legacy mock/dummy data with direct PostgreSQL queries over TLS.
  - Implemented auto-migration procedures (`_ensureAgendaTable`, `_ensureSpeakersTable`, `_ensureQnaTable`, `_ensureStageNotificationsTable`, `_ensureEventAnchorsTable`).
  - Auto-provisioned single active default event and default stage agenda items when DB is empty.
- **PostgreSQL ENUM Compatibility Fix (`agenda_item_status`)**:
  - Resolved `Severity.error 22P02: invalid input value for enum agenda_item_status: "live"` error by implementing two-way status mappers:
    - **UI $\rightarrow$ DB**: Maps `'live'` $\rightarrow$ `'in_progress'`, `'done'` $\rightarrow$ `'completed'`.
    - **DB $\rightarrow$ UI**: Maps `'in_progress'` / `'ongoing'` $\rightarrow$ `'live'`, `'completed'` $\rightarrow$ `'done'`.

### 🧹 B. Full Dummy Data Eradication Project-Wide
- Stripped hardcoded static datasets across all core files:
  - [`anchor_provider.dart`](file:///c:/Users/romal/Desktop/SmartEve/mobile/lib/providers/anchor_provider.dart) (cleared mock invitations, upcoming, and completed lists).
  - [`scripts_provider.dart`](file:///c:/Users/romal/Desktop/SmartEve/mobile/lib/providers/scripts_provider.dart) (set default seeded scripts to empty dynamic list).
  - [`neon_database_service.dart`](file:///c:/Users/romal/Desktop/SmartEve/mobile/lib/core/services/neon_database_service.dart) (removed hardcoded demo anchor accounts).
  - [`auth_service.dart`](file:///c:/Users/romal/Desktop/SmartEve/mobile/lib/core/services/auth_service.dart) (removed email shortcuts, issued real Neon DB user UUIDs).
  - [`role_selection_screen.dart`](file:///c:/Users/romal/Desktop/SmartEve/mobile/lib/features/auth/role_selection_screen.dart) and [`app_constants.dart`](file:///c:/Users/romal/Desktop/SmartEve/mobile/lib/core/constants/app_constants.dart).
  - [`event_details_screen.dart`](file:///c:/Users/romal/Desktop/SmartEve/mobile/lib/features/events/event_details_screen.dart).

### 🎨 C. StagePilot Dashboard & Control Room Rebranding & UI Redesign
- **SmartEve Rebranding**: Removed all legacy "StagePilot AI" logos and replaced them with official SmartEve visual branding (`assets/trans_icon.png`) and tagline *"Your Event's Co-Pilot"*.
- **Dynamic Live Cards**: Connected dashboard live cards (Live Session, Up Next, Later, Progress Bar, Countdown Ticker) directly to `EventProvider` state fetched from Neon DB.
- **Dashboard Header Cleanup**: Removed `"Good Morning! 👋"` greeting header and organizer avatar block above Live Stage Keynote card.
- **Control Room Screen Header**: Redesigned header bar to match the exact light-theme aesthetic system used across the app.

### 📅 D. Agenda Screen & Timeline View Redesign
- **Overhauled Agenda Layout**: Redesigned Agenda tab view in [`stagepilot_dashboard_screen.dart`](file:///c:/Users/romal/Desktop/SmartEve/mobile/lib/features/dashboard/stagepilot_dashboard_screen.dart) and [`agenda_screen.dart`](file:///c:/Users/romal/Desktop/SmartEve/mobile/lib/features/agenda/agenda_screen.dart).
- **Eliminated Column Text Wrapping**: Fixed rigid width constraints that caused text squishing (e.g. `Welco me & Regist ration`).
- **Modern Card Architecture**:
  - Full-width title wrapping with `GoogleFonts.inter` typography.
  - `#order` and session type badges (`KEYNOTE`, `TALK`, `PANEL`, `WORKSHOP`, `BREAK`).
  - Status tags (`NOW LIVE`, `UPCOMING`, `COMPLETED`).
  - Schedule time range (`09:00 AM - 09:15 AM`), duration pill (`15 min`), and `BUFFER` tags.
  - Interactive **Add / Edit / Delete Session Modal** connected directly to `EventProvider` and Neon DB.

### 🔐 E. Role-Based Auth Routing & Anchor Invitation System
- **Host Role Navigation Fix**: Resolved routing issue where users logging in as Host landed on the Organiser screen instead of the Anchor Teleprompter/Dashboard.
- **Anchor Invitation Workflow**: Created `event_anchors` table in Neon DB to handle event invitation binding, accept/decline flows, and real-time host status.

### 📱 F. Native Branding & Password Reset Flow
- Generated native launcher icons (`assets/smartEVE-icon.png`) via `flutter_launcher_icons`.
- Configured transparent status bar notification icons (`assets/trans_icon.png`) across native Android drawable directories and `AndroidManifest.xml`.
- Extended `AuthService` with interactive `sendPasswordResetEmail` modal bottom sheet.

### 🎯 G. Static Analysis & Zero-Error Quality Assurance
- Resolved all syntax, type, and layout issues.
- Executed `flutter analyze`: **No issues found!**

---

## ⏳ 4. Current Status & Remaining Tasks

### **Current Status**
- All feature requests, UI redesigns, database connections, and bug fixes are **100% complete and tested locally**.
- Static analysis clean: `flutter analyze` reports **0 errors and 0 warnings**.

### **Remaining Tasks**
1. **Push to Remote Git Repository**:
   > *Note: Changes are currently held on local main/develop branch per user instructions (`do not push now`). Ready to push upon user confirmation.*
2. **Production App Build Verification**:
   - Execute `flutter build apk --release` for release deployment testing.

---

## 🔮 5. Future Scope & Roadmap

1. **Real-Time WebSocket Sync Engine**:
   - Transition from polling-based DB queries to low-latency WebSockets (via Socket.io / Supabase Realtime / AWS AppSync) for sub-100ms stage synchronization across 100+ concurrent organizer, anchor, and projector devices.
2. **Offline PWA & Local SQLite Sync (Hive Engine)**:
   - Implement local SQLite / Hive caching so stage hosts and teleprompters function seamlessly even in zero-connectivity venue basements.
3. **Multi-Stage & Multi-Track Concurrent Coordination**:
   - Extend the Schedule Reflow Engine to manage multi-track mega-conferences with parallel halls (Main Stage, Track 1, Track 2) from a unified master Control Room.
4. **AI Voice Cloning for Stage Announcements**:
   - Integrate ElevenLabs / Coqui TTS for custom voice-cloned automated announcements in the voice of the primary event host.
5. **QR Code Biometric Speaker & Anchor Check-In**:
   - Instant QR code scanning for stage speakers at backstage entry, automatically updating speaker status from `'expected'` to `'arrived'` in the Control Room.

---

## 🏗️ 6. Repository Architecture

```
SmartEve/
│
├── backend/                      # Express + TypeScript Standalone API
│   ├── src/
│   │   ├── config/               # Database & Firebase configuration
│   │   ├── db/                   # Neon PostgreSQL schemas & queries
│   │   ├── middleware/           # Auth & Bearer token verification
│   │   ├── routes/               # API routes (Events, Agenda, Speakers, AI)
│   │   ├── services/             # Schedule reflow engine & Quad-AI providers
│   │   └── server.ts             # Express server entry point (port 4000)
│   ├── tests/                    # Vitest test suite
│   └── package.json
│
├── mobile/                       # Flutter Mobile Application (Dart)
│   ├── android/                  # Native Android scaffold & drawables
│   ├── assets/                   # App icons & branding logos
│   ├── lib/
│   │   ├── main.dart             # Application entry point
│   │   ├── app.dart              # MaterialApp & Light Theme configuration
│   │   ├── core/                 # AppTheme, NeonDatabaseService, AuthService, Firebase, TTS
│   │   ├── models/               # Dart models (Event, AgendaItem, Speaker, Script, User)
│   │   ├── providers/            # EventProvider, AnchorProvider, ScriptsProvider
│   │   └── features/
│   │       ├── auth/             # Login, Role Selection, Forgot Password, 6-Step Wizards
│   │       ├── dashboard/        # StagePilot Dashboard & Rebranded Header
│   │       ├── control_room/     # Control Room Screen & Delay Controls
│   │       ├── anchor/           # Anchor Teleprompter & TTS Player
│   │       ├── stage_display/    # Stage Projector Billboard
│   │       └── agenda/           # Redesigned Event Agenda View
│   └── pubspec.yaml              # App configuration & package dependencies
│
└── README.md                     # Comprehensive project documentation
```

---

## 🚀 7. Getting Started

### 1. Backend Setup (`backend/`)
```bash
cd backend
npm install
npm run dev
```
- Server runs on `http://localhost:4000`

### 2. Mobile App Setup (`mobile/`)
```bash
cd mobile
flutter pub get
flutter run
```

---

*SmartEve — Keeping live stage events running on time, every time.*
