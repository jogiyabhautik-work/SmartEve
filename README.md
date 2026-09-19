# 🚀 SmartEve & Stage Flow
### *"Your Mission-Critical Live Event Co-Pilot"*

> **A mission-critical live stage management platform featuring a deterministic schedule reflow engine, real-time multi-device synchronization, quad-tier fail-safe AI anchor assistance, and modern light-themed UI.**

---

## 📌 1. Project Description

**SmartEve** is an enterprise-grade live event coordination and stage management platform built to handle the unpredictable dynamics of live conferences, auditoriums, festivals, and summits.

During live events, schedule shifts are inevitable: keynote presentations run overtime, VIP speakers arrive late, or impromptu stage announcements are required. Traditional static paper agendas and manual messaging channels fail under high-pressure scenarios, causing cascading delays and confused audiences.

**SmartEve solves this by providing:**
1. **Deterministic Schedule Reflow Engine**: When a session runs overtime or an organizer triggers a time adjustment (e.g., `+15m`), the system instantly recalculates downstream start times across the entire agenda while preserving hard stops (e.g., lunch breaks, venue closures) and safety buffers.
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

## 📱 3. App Icons & Branding

SmartEve includes custom high-resolution visual branding assets for native application icons and notification system drawables:

- **App Launcher Icon (`assets/smartEVE-icon.png`)**: Configured via `flutter_launcher_icons` to generate native Android app launcher icons across all screen density directories (`mipmap-hdpi`, `mdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`).
- **Notification Icon (`assets/trans_icon.png`)**: Transparent vector graphic placed in Android native resources (`drawable/trans_icon.png` & `drawable/ic_notification.png`) and linked to `AndroidManifest.xml` as the default status bar notification icon.
- **In-App Branding**: Integrated `trans_icon.png` on the animated Splash screen and the Login screen header.

---

## 📈 4. Progress Till Now (Work Completed)

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
- Configured `smartEVE-icon.png` as launcher icon and generated native density drawables.
- Positioned `trans_icon.png` into Android resource drawables and updated `AndroidManifest.xml` and `FirebaseService`.

### ⚙️ D. Backend API & Reflow Engine Implementation
- Programmed schedule reflow engine algorithm (`backend/src/services/reflow.ts`) that shifts session timings dynamically upon delay triggers (`+15m`, `-5m`).
- Neon PostgreSQL relational schemas (`backend/src/db/schema.sql`) for events, agenda items, speakers, fcm tokens, and user profiles.
- Express REST API endpoints (`backend/src/routes/`) for event lifecycle, agenda management, speaker profiles, Cloudinary image upload, and AI script generation.

### 🤖 E. Quad-AI Teleprompter & TTS Integration
- **Anchor Teleprompter Screen (`anchor_teleprompter_screen.dart`)**: Real-time live countdown timer, speaker profile overview, AI script generator, auto-scroll speed controls, and quick navigation.
- **Text-To-Speech (`tts_service.dart`)**: Integrated `flutter_tts` allowing anchors to listen to AI-generated scripts in real time for stage practice.

### 🧹 F. Code Quality & Zero-Error Verification
- Executed `dart fix --apply` applying 41 automatic fixes across 13 files.
- Verified zero static analysis errors (`dart analyze`).

---

## 🏗️ 5. Repository Architecture

```
SmartEve/
│
├── backend/                      # Standalone TypeScript (.ts) Backend API
│   ├── src/
│   │   ├── config/               # Neon DB, Cloudinary & Firebase Admin configs
│   │   ├── db/                   # Neon PostgreSQL schema definitions
│   │   ├── middleware/           # Firebase Bearer token authorization
│   │   ├── routes/               # Events, Agenda, Speakers, AI & Upload API routes
│   │   ├── services/             # Schedule reflow engine & Quad-AI cascade providers
│   │   ├── types/                # TypeScript shared model definitions
│   │   └── server.ts             # Express server entry point (port 4000)
│   ├── tests/                    # Vitest unit test suite
│   └── package.json
│
├── mobile/                       # Flutter Mobile Application (Dart)
│   ├── android/                  # Android native scaffolding & drawables
│   ├── assets/                   # App icons (smartEVE-icon.png, trans_icon.png)
│   ├── lib/
│   │   ├── main.dart             # Flutter app entry point
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
│   └── pubspec.yaml              # Dependencies & launcher icon configuration
│
└── README.md                     # Root project documentation
```

---

## 🚀 6. Getting Started

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
