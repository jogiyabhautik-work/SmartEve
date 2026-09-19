# SmartEve & Stage Flow
### *"Your Event's Co-Pilot"*

> **A mission-critical live stage management system with a deterministic schedule reflow engine, multi-device synchronization, and quad-tier fail-safe AI anchor assistance.**

---

## 🛠️ Technology Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend** | **Flutter (Dart)** | Cross-platform mobile app for Organizers, Stage Anchors & Display Projectors |
| **Backend** | **TypeScript / Node.js (Express)** | Deterministic schedule reflow engine, REST endpoints & real-time sync |
| **Database** | **[Neon.tech](https://neon.tech)** | Serverless PostgreSQL database with connection pooling and typed schemas |
| **Auth & Push Alerts** | **Firebase (Auth & FCM)** | Role-based 1-tap login & Firebase Cloud Messaging (FCM) live push alerts |
| **Image CDN** | **[Cloudinary](https://cloudinary.com)** | High-performance speaker headshot optimization and face-crop CDN delivery |
| **AI Inference** | **Quad-Tier Failover Engine** | **Gemini** → **Groq** → **Nvidia NIM** → **OpenRouter** → **Local Templates** |

---

## 🏗️ Repository Architecture

```
SmartEve/
│
├── backend/                      # Standalone TypeScript (.ts) Backend API
│   ├── src/
│   │   ├── config/
│   │   │   ├── db.ts             # Neon.tech PostgreSQL connection pool
│   │   │   ├── cloudinary.ts     # Cloudinary CDN SDK configuration
│   │   │   ├── firebaseAdmin.ts  # Firebase Admin SDK (Auth & Messaging)
│   │   │   └── constants.ts      # Roles, defaults & tokens
│   │   ├── db/
│   │   │   └── schema.sql        # Neon PostgreSQL schema (events, agenda, speakers, fcm)
│   │   ├── middleware/
│   │   │   └── auth.ts           # Firebase ID token verification middleware
│   │   ├── routes/
│   │   │   ├── events.ts         # Event lifecycle, start, delay (+15m), complete-current
│   │   │   ├── agenda.ts         # Agenda item management & buffer breaks
│   │   │   ├── speakers.ts       # Speaker profiles & arrival status
│   │   │   ├── ai.ts             # AI stage script generation endpoint
│   │   │   ├── upload.ts         # Cloudinary image upload route
│   │   │   └── public.ts         # Public stage display & server time sync
│   │   ├── services/
│   │   │   ├── reflow.ts         # Deterministic schedule reflow engine
│   │   │   ├── store.ts          # State store (Postgres + In-Memory fallback)
│   │   │   ├── validation.ts     # Zod schema validation
│   │   │   ├── notifications/
│   │   │   │   └── fcm.ts        # Firebase Cloud Messaging push dispatcher
│   │   │   └── ai/
│   │   │       ├── generate.ts   # Quad-AI cascade orchestrator
│   │   │       ├── prompts.ts    # Stage prose system instructions
│   │   │       ├── templates.ts  # Context-aware offline fallback templates
│   │   │       └── providers/
│   │   │           ├── gemini.ts     # Google Gemini API
│   │   │           ├── groq.ts       # Groq Llama 3.3 70B API
│   │   │           ├── nvidia.ts     # Nvidia NIM microservice API
│   │   │           └── openrouter.ts # OpenRouter universal API
│   │   ├── types/                # TypeScript shared data models
│   │   ├── utils/                # Date/time helpers and response formatters
│   │   └── server.ts             # Express entry point (port 4000)
│   ├── tests/                    # Vitest unit test suite
│   ├── package.json              # Express, Neon, Cloudinary, Firebase Admin
│   ├── tsconfig.json             # TypeScript configuration
│   └── .env.example              # Server environment configuration
│
├── mobile/                       # Flutter Mobile Application (Dart)
│   ├── android/                  # Android native scaffolding & manifest
│   ├── lib/
│   │   ├── main.dart             # Flutter app entry point (initializes Firebase)
│   │   ├── app.dart              # MaterialApp, dark theme & provider setup
│   │   ├── core/
│   │   │   ├── constants/        # API base URLs (emulator & physical device)
│   │   │   ├── network/          # ApiClient with Firebase Bearer auth headers
│   │   │   ├── services/
│   │   │   │   ├── firebase_service.dart   # Firebase Auth & FCM push alerts listener
│   │   │   │   ├── cloudinary_service.dart # Headshot picker & Cloudinary upload client
│   │   │   │   └── tts_service.dart        # Local speech synthesis for stage scripts
│   │   │   └── theme/            # AppTheme (#0B1020, cyan/amber neon accents)
│   │   ├── models/               # Dart models (Event, AgendaItem, Speaker, Script)
│   │   ├── providers/            # EventProvider (live state, countdown ticker, delay triggers)
│   │   └── features/
│   │       ├── auth/             # RoleSelectionScreen (Organizer, Anchor, Stage Display)
│   │       ├── control_room/     # ControlRoomScreen (Countdown, +15m delay, advance)
│   │       ├── anchor/           # AnchorTeleprompterScreen (AI scripts & TTS read-aloud)
│   │       ├── stage_display/    # StageDisplayScreen (Oversized countdown billboard)
│   │       └── agenda/           # AgendaScreen (Schedule timeline & buffer break tags)
│   ├── pubspec.yaml              # Flutter dependencies (Firebase, Cloudinary cache, TTS)
│   ├── .gitignore                # Flutter build ignore rules
│   └── README.md                 # Mobile guide
│
├── package.json                  # Root scripts (backend:dev, mobile:run)
├── .gitignore                    # Workspace gitignore
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

### 2. Start the TypeScript Backend (`backend/`)
```bash
cd backend
npm install
npm run dev
```
- Server runs on: `http://localhost:4000`
- Health check: `http://localhost:4000/api/health`

### 3. Run the Flutter Mobile App (`mobile/`)
```bash
cd mobile
flutter pub get
flutter run
```
- Connects automatically to the backend (`http://10.0.2.2:4000/api` on Android emulator, or `http://localhost:4000/api` on desktop/web).
