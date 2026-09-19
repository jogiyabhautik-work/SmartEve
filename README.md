# 🚀 SmartEve & Stage Flow
### *"Your Mission-Critical Event Co-Pilot"*

> **A mission-critical live stage management system featuring a deterministic schedule reflow engine, multi-device real-time synchronization, quad-tier fail-safe AI anchor assistance, modern light theme UI, and cloud-native backend infrastructure.**

---

## 📌 1. Project Description

**SmartEve** is an enterprise-grade live event coordination and stage management platform designed to solve the chaotic reality of live conference, auditorium, and festival management.

During live events, schedule shifts are inevitable: keynotes run overtime, speakers arrive late, or impromptu stage announcements are required. Traditional paper agendas and manual messaging channels crumble under these high-pressure scenarios, causing cascading delays and confused attendees.

**SmartEve solves this by providing:**
1. **Deterministic Schedule Reflow Engine**: When a session goes overtime or an organizer triggers a time adjustment (e.g., `+15m`), the system instantly recalculates downstream start times across the entire agenda while preserving hard stops (e.g., lunch breaks, venue closures) and safety buffers.
2. **Multi-Role Tailored Interfaces**:
   - **Control Room Dashboard**: Gives event managers instant oversight of live session timers, speaker arrival statuses, and delay controls.
   - **Anchor Teleprompter**: Equips stage hosts with AI-generated speaker intros, stage talking points, auto-scrolling teleprompter, and built-in Text-to-Speech (TTS) read-aloud capabilities.
   - **Public Stage Display**: High-contrast, oversized countdown billboard tailored for stage projectors and backstage monitors.
   - **Agenda View**: Interactive timeline of all event sessions, speaker profiles, and live status tags.
3. **Quad-Tier Fail-Safe AI Assistant**: Generates professional stage prose and emergency announcements with automatic cascading across multiple LLM inference providers (**Google Gemini → Groq Llama 3.3 → Nvidia NIM → OpenRouter → Context-Aware Offline Templates**) to guarantee 100% uptime on stage.
4. **Resilient Multi-Cloud Architecture**: Combines **Firebase Auth & Messaging**, **Cloudinary CDN** for speaker headshots, and **Neon.tech Serverless PostgreSQL** connected directly over TLS.

---

## 🛠️ 2. Technology Stack

### **Frontend (Mobile App)**
- **Framework**: Flutter SDK (Dart)
- **State Management**: Provider (`provider: ^6.1.2`) using `ChangeNotifier` for reactive UI updates and real-time countdown tickers
- **Design System & Theme**: Custom `AppTheme.lightTheme` with Slate Light Palette (`#F8FAFC` background, `#FFFFFF` card surfaces, `#2563EB` Royal Blue accents, `#0F172A` Slate 900 typography)
- **Networking**: `http` with custom `ApiClient` injecting Firebase Bearer tokens
- **Speech Synthesis**: `flutter_tts` for on-device script read-aloud and anchor practice
- **Image Handling & CDN**: `cached_network_image` and `image_picker` integrated with Cloudinary CDN
- **Push Alerts**: `firebase_messaging` & `flutter_local_notifications`
- **Native Assets & Icons**: `flutter_launcher_icons` (`smartEVE-icon.png` launcher & `trans_icon.png` notification icon)

### **Backend (API Server)**
- **Runtime & Language**: Node.js & TypeScript (`.ts`)
- **HTTP Framework**: Express.js
- **Validation**: Zod schema validation
- **Testing**: Vitest unit test suite

### **Database & Cloud Services**
- **Primary Database**: **[Neon.tech](https://neon.tech)** Serverless PostgreSQL with TLS connection pooling
- **Authentication**: **Firebase Authentication** with resilient direct Neon DB fallback
- **Push Notifications**: **Firebase Cloud Messaging (FCM)** for instant alerts across all devices
- **Media Optimization**: **Cloudinary CDN** with face-detection auto-cropping for speaker avatars

### **AI Inference Pipeline**
- **Tier 1**: Google Gemini 1.5 / 2.0 API
- **Tier 2**: Groq Cloud (Llama 3.3 70B Versatile)
- **Tier 3**: Nvidia NIM Microservices API
- **Tier 4**: OpenRouter Universal Gateway
- **Tier 5 (Offline Guarantee)**: Context-aware pre-compiled local templates

---

## 📈 3. Progress Till Now (Detailed Work Completed)

### 🎨 A. Complete Light Theme UI Regeneration
- **App Theme Infrastructure (`lib/core/theme/app_theme.dart`)**:
  - Engineered `AppTheme.lightTheme` with modern slate light tokens (`#F8FAFC` background, `#FFFFFF` crisp cards, `#E2E8F0` borders, `#2563EB` primary blue, `#10B981` live green, `#F59E0B` warning amber, and `#EF4444` danger rose).
  - Applied `AppTheme.lightTheme` globally in `lib/app.dart`.
- **Splash Screen (`splash_screen.dart`)**:
  - Animated entry screen featuring `assets/trans_icon.png` brand logo, scale/fade animation transitions, and light theme progress indicators.
- **Login Screen (`login_screen.dart`)**:
  - Regenerated UI with `assets/trans_icon.png` logo header, white input field surfaces with blue focus rings, one-tap demo login shortcuts (Organizer & Anchor), event code quick join button, and integrated Forgot Password.
- **Role Selection Screen (`role_selection_screen.dart`)**:
  - Light theme cards for selecting **StagePilot Suite**, **Anchor Teleprompter**, and **Stage Display Billboard**. Added backend connection indicator and test push alert action.
- **Multi-Step Registration Flows**:
  - **Organizer Registration (`organizer_registration_screen.dart`)**: 6-step guided wizard (Basic Info, Organization Details, Event Profile, Credentials, Preferences, Terms & Review) with step indicators, custom light dropdowns, image picker, password confirmation, and direct database sync.
  - **Anchor Registration (`anchor_registration_screen.dart`)**: 6-step wizard (Contact Info, Anchoring Experience, Portfolio & Socials, Technical Preferences, Emergency Contact, Confirmation) with experience sliders and specialty chips.

### 🔑 B. Forgot Password Functionality
- Extended `AuthService` with `sendPasswordResetEmail(String email)` connecting to `FirebaseAuth.instance.sendPasswordResetEmail` with resilient fallback error translation.
- Created an interactive **Forgot Password** modal bottom sheet in `LoginScreen` complete with email validation, sending state spinner, and floating success/error snackbars.

### 📱 C. Native App Icon & Notification Icon Setup
- **App Launcher Icon**: Configured `assets/smartEVE-icon.png` in `pubspec.yaml` and generated native launcher icons across Android density directories (`mipmap-hdpi`, `mdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
- **Transparent Notification Icon**: Positioned `assets/trans_icon.png` into Android drawable folders (`trans_icon.png` & `ic_notification.png`), updated `AndroidManifest.xml` default notification icon metadata, and updated local notification settings in `FirebaseService`.
- Integrated `trans_icon.png` as the official brand graphic on Splash and Login screens.

### ⚙️ D. Backend API & Reflow Engine Implementation
- **Deterministic Reflow Engine (`backend/src/services/reflow.ts`)**: Programmed schedule shifting algorithms that recalculate session timings dynamically upon delay triggers (`+15m`, `-5m`).
- **Neon PostgreSQL Database Schema (`backend/src/db/schema.sql`)**: Created relational tables for `events`, `agenda_items`, `speakers`, `fcm_tokens`, and `users`.
- **Express REST API Routes (`backend/src/routes/`)**: Implemented endpoints for event state, agenda items, speaker profiles, Cloudinary image uploads, AI script generation, and public display syncing.

### 🤖 E. Quad-AI Teleprompter & TTS Integration
- **Anchor Teleprompter Screen (`anchor_teleprompter_screen.dart`)**: Real-time live countdown timer, speaker profile overview, AI script generator, auto-scroll speed controls, and quick navigation.
- **Text-To-Speech (`tts_service.dart`)**: Integrated `flutter_tts` allowing anchors to listen to AI-generated scripts in real time for stage practice.

### 🧹 F. Automated Code Cleanup & Quality Verification
- Ran `dart fix --apply` resolving 41 automatic lint items across 13 files.
- Executed `dart analyze` confirming **0 static analysis errors**.
- Cleared build cache with `flutter clean` and `flutter pub get`.

---

## 🏗️ Repository Architecture

```
SmartEve/
│
├── backend/                      # Standalone TypeScript (.ts) Backend API
│   ├── src/
│   │   ├── config/               # DB pool, Cloudinary & Firebase Admin configs
│   │   ├── db/                   # Neon PostgreSQL schema (events, agenda, speakers, users)
│   │   ├── middleware/           # Firebase Bearer token authorization
│   │   ├── routes/               # Events, Agenda, Speakers, AI & Upload API routes
│   │   ├── services/             # Schedule reflow engine & Quad-AI cascade providers
│   │   ├── types/                # TypeScript shared model definitions
│   │   └── server.ts             # Express server entry point (port 4000)
│   ├── tests/                    # Vitest unit test suite
│   └── package.json
│
├── mobile/                       # Flutter Mobile Application (Dart)
│   ├── android/                  # Android scaffolding, launcher icons & drawables
│   ├── assets/                   # smartEVE-icon.png & trans_icon.png
│   ├── lib/
│   │   ├── main.dart             # Flutter app entry point (Firebase initialization)
│   │   ├── app.dart              # MaterialApp & AppTheme.lightTheme setup
│   │   ├── core/                 # Theme, ApiClient, AuthService, FirebaseService, TTS
│   │   ├── models/               # Dart models (Event, AgendaItem, Speaker, Script)
│   │   ├── providers/            # EventProvider live state store & ticker
│   │   └── features/
│   │       ├── auth/             # Login, Role Selection, Forgot Password, 6-Step Registration
│   │       ├── control_room/     # Control Room Dashboard & +15m delay controls
│   │       ├── anchor/           # Anchor Teleprompter & TTS script player
│   │       ├── stage_display/    # Stage Projector countdown billboard
│   │       └── agenda/           # Event agenda schedule timeline
│   └── pubspec.yaml              # Dependencies & flutter_launcher_icons configuration
│
└── README.md                     # Root project documentation
```

---

## 🚀 Getting Started

### 1. Configure Backend Environment (`backend/.env`)
Copy `backend/.env.example` to `backend/.env` and supply your credentials:
```bash
DATABASE_URL=postgresql://user:pass@ep-cool-db.neon.tech/smarteve?sslmode=require
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
GEMINI_API_KEY=your_gemini_key
GROQ_API_KEY=your_groq_key
```

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
