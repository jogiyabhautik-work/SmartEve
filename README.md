# SmartEve & Stage Flow
### *"Your Mission-Critical Event Co-Pilot"*

> **A mission-critical live stage management system with a deterministic schedule reflow engine, multi-device real-time synchronization, quad-tier fail-safe AI anchor assistance, and modern UI.**

---

## 📌 Project Description

**SmartEve** is an enterprise-grade live event coordination and stage management platform. When live events experience unexpected delays, speaker schedule shifts, or stage announcements, traditional paper schedules break down. 

SmartEve solves this by providing:
- **Deterministic Schedule Reflow**: Instantly recalculates downstream session start times when a speaker goes overtime or an organizer triggers a `+15m` delay, seamlessly preserving fixed hard stops and buffer breaks.
- **Multi-Role Co-Pilot Interfaces**: Dedicated screens tailored for **Event Organizers** (Control Room), **Stage Anchors** (AI Teleprompter & TTS Read-Aloud), and **Stage Display Projectors** (Oversized Billboard Countdown).
- **Quad-Tier Fail-Safe AI**: Generates context-aware speaker introductions and stage scripts with automated fallback cascading across multiple AI inference providers (**Gemini → Groq → Nvidia NIM → OpenRouter → Offline Templates**).
- **Resilient Multi-Cloud Database & Auth**: Seamless authentication combining Firebase Auth, Cloudinary Image CDN, and Neon.tech Serverless PostgreSQL over TLS.

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend Mobile** | **Flutter (Dart)** | Cross-platform app for Organizers, Anchors & Stage Display Projectors |
| **State Management** | **Provider (ChangeNotifier)** | Reactive state management & real-time live countdown ticker |
| **Backend API** | **TypeScript / Node.js (Express)** | Reflow engine, REST API endpoints & server-time synchronization |
| **Database** | **[Neon.tech](https://neon.tech)** | Serverless PostgreSQL database with connection pooling over TLS |
| **Auth & Push Alerts** | **Firebase (Auth & FCM)** | Role-based authentication, 1-tap demo access & FCM push alerts |
| **Image CDN** | **[Cloudinary](https://cloudinary.com)** | Speaker headshot optimization and face-crop CDN image delivery |
| **Voice Synthesis** | **Flutter TTS (`flutter_tts`)** | On-device speech synthesis for stage script rehearsal and read-aloud |
| **AI Inference** | **Quad-Tier Failover Cascade** | **Google Gemini** → **Groq (Llama 3.3)** → **Nvidia NIM** → **OpenRouter** → **Offline Templates** |

---

## 📈 Progress Till Now

### 🎨 1. Full Light Theme UI Regeneration
- **App-Wide Light Theme**: Designed and implemented `AppTheme.lightTheme` with clean slate background (`#F8FAFC`), crisp white card surfaces (`#FFFFFF`), vibrant Royal Blue primary accents (`#2563EB`), and high-contrast typography (`#0F172A`).
- **Authentication Screens Overhaul**:
  - **Splash Screen**: Animated entry with `trans_icon.png` branding and light theme progress indicator.
  - **Login Screen**: Modern light theme interface, quick demo login buttons (Organizer & Anchor), event join code entry card, and integrated Forgot Password.
  - **Role Selection Screen**: Visual role selection cards (StagePilot Suite, Anchor Teleprompter, Stage Projector).
  - **6-Step Registration Forms**: Multi-step registration flows for both **Organizers** and **Anchors** featuring step indicators, profile input fields, specialty tags, terms confirmation, and immediate database sync.

### 🔑 2. Forgot Password Functionality
- Added `sendPasswordResetEmail(String email)` in `AuthService` handling Firebase Auth password reset emails with graceful offline/demo fallbacks.
- Built an interactive **Forgot Password** modal bottom sheet on the Login screen with email validation and user feedback snackbars.

### 📱 3. Native App Icon & Notification Icon Setup
- **App Launcher Icon**: Configured `assets/smartEVE-icon.png` in `pubspec.yaml` and generated native Android icons across all density folders (`mipmap-hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
- **Transparent Notification Icon**: Positioned `assets/trans_icon.png` into Android drawable folders (`trans_icon.png` & `ic_notification.png`), updated `AndroidManifest.xml` default notification icon metadata, and configured local notification settings in `FirebaseService`.

### ⚡ 4. Backend Reflow Engine & Database Integration
- Implemented deterministic schedule recalculation logic in TypeScript (`backend/src/services/reflow.ts`).
- Created Neon.tech PostgreSQL database schemas (`schema.sql`) for events, agenda items, speaker profiles, and FCM token registrations.
- Built RESTful Express endpoints (`/api/events`, `/api/agenda`, `/api/speakers`, `/api/ai/generate-script`).

### 🤖 5. Quad-Tier AI Cascade & Teleprompter
- Built multi-provider AI orchestrator cascading from Gemini to Groq, Nvidia NIM, OpenRouter, and context-aware offline templates.
- Teleprompter view with speed controls, script generation, and one-tap Text-To-Speech (`flutter_tts`) read-aloud.

---

## 🏗️ Repository Architecture

```
SmartEve/
│
├── backend/                      # Standalone TypeScript (.ts) Backend API
│   ├── src/
│   │   ├── config/               # Neon DB, Cloudinary & Firebase Admin configs
│   │   ├── db/                   # Neon PostgreSQL schema definitions
│   │   ├── middleware/           # Firebase Bearer token authentication
│   │   ├── routes/               # Events, Agenda, Speakers, AI & Upload routes
│   │   ├── services/             # Deterministic reflow engine & Quad-AI cascade
│   │   ├── types/                # Shared TypeScript interface models
│   │   └── server.ts             # Express application entry point
│   ├── tests/                    # Vitest unit tests
│   └── package.json
│
├── mobile/                       # Flutter Mobile Application (Dart)
│   ├── android/                  # Android scaffolding, launcher icons & drawables
│   ├── assets/                   # App icons (smartEVE-icon.png, trans_icon.png)
│   ├── lib/
│   │   ├── main.dart             # Flutter app entry point
│   │   ├── app.dart              # MaterialApp & light theme setup
│   │   ├── core/                 # Theme, ApiClient, AuthService, FirebaseService, TTS
│   │   ├── models/               # Dart data models
│   │   ├── providers/            # EventProvider live state & ticker
│   │   └── features/
│   │       ├── auth/             # Login, Role Selection, Forgot Password, 6-Step Registration
│   │       ├── control_room/     # Control Room Dashboard & +15m delay controls
│   │       ├── anchor/           # Anchor Teleprompter & TTS script player
│   │       ├── stage_display/    # Stage Projector countdown billboard
│   │       └── agenda/           # Event agenda timeline & break tags
│   └── pubspec.yaml              # Dependencies & launcher icon configuration
│
└── README.md                     # Root project documentation
```

---

## 🚀 Getting Started

### 1. Configure Backend Environment (`backend/.env`)
Copy `backend/.env.example` to `backend/.env` and supply your credentials:
- `DATABASE_URL`: Neon.tech PostgreSQL connection string
- `CLOUDINARY_*`: Cloudinary cloud name, API key & secret
- `FIREBASE_ADMIN_*`: Firebase Admin credentials
- `GEMINI_API_KEY`, `GROQ_API_KEY`, `NVIDIA_NIM_API_KEY`, `OPENROUTER_API_KEY`

### 2. Start the Backend API (`backend/`)
```bash
cd backend
npm install
npm run dev
```
- Server runs on `http://localhost:4000`

### 3. Run the Flutter Mobile App (`mobile/`)
```bash
cd mobile
flutter pub get
flutter run
```
