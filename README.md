# SMART ANCHOR & STAGE FLOW
### *"Your Event's Co-Pilot"*

> **A mission-critical, real-time stage management system with a deterministic schedule reflow engine, multi-device synchronization, and fail-safe AI anchor assistance.**

---

## 🌟 The Problem
Live conferences, tech summits, and stage broadcasts face one inevitable reality: **Sessions run overtime**. 
When a keynote runs 15 minutes late:
- The anchor has no idea what to say or how much to cut.
- Stage displays show outdated timings.
- Breaks become chaotic bottlenecks.
- Attendees are left confused.
- Organizers frantically run back and forth with walkie-talkies.

---

## 💡 The Solution: "One Live Source of Truth"
**Smart Anchor & Stage Flow** transforms chaotic stage production into a deterministic, synchronized experience:
1. **Organizer triggers "+15m delay"** from the Control Room.
2. **Deterministic Reflow Engine** recalculates the entire schedule in milliseconds, intelligently shrinking absorbable breaks to protect major keynote sessions.
3. **Multi-Device Real-Time Sync** updates the Organizer Dashboard, Anchor Mobile Screen, and Stage Projector Display simultaneously.
4. **Fail-Safe AI Co-Pilot** instantly crafts speakable, contextual announcements for the anchor.

---

## 🚀 Key Innovations & Differentiators

### 1. Deterministic Smart Delay & Reflow Engine (`lib/reflow.ts`)
Unlike generic calendar apps that drift or overlap:
- **Immutability of History**: Completed sessions and original `plannedStart` are strictly preserved.
- **Break Buffer Absorption**: Absorbable breaks (e.g. a 30m tea break) automatically absorb delays down to their `minDuration` (e.g. 15m) before downstream sessions are forced to move.
- **Hard-Start Detection**: Fixed broadcast commitments flag instant conflicts if pushed.
- **Schedule Compression**: Early finishes or cancellations pull the schedule forward.

### 2. Multi-Tier Fail-Safe AI Co-Pilot (`lib/ai/`)
Never strands the stage host during an internet dip or API rate limit:
```
Google Gemini API (Primary AI)
       ↓ (failure or timeout)
Groq Llama 3.3 70B (Ultra-fast secondary AI)
       ↓ (failure or timeout)
Contextual Deterministic Templates (Instant fail-safe fallback)
       ↓
Manual Entry & Live Speech Synthesis
```
- Only receives true event context (real speaker names, designations, topics, and delays).
- Generates 30–75 word speakable stage prose.
- Features one-click Web Speech API read-aloud for accessibility.

### 3. Dual-Mode Real-Time Architecture (Zero-Setup Guarantee)
- Connects directly to **Firebase Firestore** via `onSnapshot` when `.env.local` credentials exist.
- Seamlessly falls back to an in-memory cross-tab **BroadcastChannel real-time bus** so judges and evaluators can experience multi-window sync out-of-the-box with zero configuration!

---

## 🛠️ Technology Stack
- **Framework**: Next.js 15 (App Router, Server Components & Route Handlers)
- **Language**: TypeScript (Strict mode)
- **Styling**: Tailwind CSS (Custom Dark Control-Room Aesthetic `#0B1020`)
- **Real-Time Data**: Firebase Firestore (`onSnapshot`) + Fallback Real-time Store
- **Security & Admin**: Firebase Admin SDK + Zod validation on every API endpoint
- **AI Inference**: Google Gemini API & Groq API
- **Testing**: Vitest test suite

---

## 📁 Project Structure
```
smart-anchor/
├── app/
│   ├── (auth)/login/page.tsx           # Role-based 1-click login
│   ├── dashboard/page.tsx              # Organizer dashboard & event cards
│   ├── events/
│   │   ├── new/page.tsx                # Create event & join code
│   │   └── [id]/
│   │       ├── page.tsx                # Preparation: Agenda & Speakers
│   │       ├── live/page.tsx           # 3-Column Organizer Control Room
│   │       ├── anchor/page.tsx         # Mobile-first Anchor Teleprompter
│   │       └── summary/page.tsx        # Post-event analytics & audit log
│   ├── stage/[joinCode]/page.tsx       # Volunteer Public Stage Display
│   └── api/
│       ├── ai/generate/route.ts        # AI script generator with fallback
│       ├── events/                     # Event CRUD & lifecycle endpoints
│       │   └── [id]/
│       │       ├── start/route.ts
│       │       ├── complete-current/route.ts
│       │       ├── delay/route.ts
│       │       ├── cancel-item/route.ts
│       │       └── announce/route.ts
│       └── public/[joinCode]/route.ts  # Public stage read-only endpoint
├── components/
│   ├── ui/                             # Button, Badge, Modal, Toast, Skeleton
│   ├── layout/Navbar.tsx               # Top command bar & fast role switch
│   ├── live/                           # Control Room cards, timer & feeds
│   ├── anchor/AnchorMobileView.tsx     # Mobile-optimized stage view
│   ├── stage/ProjectorDisplay.tsx      # High-contrast stage projector
│   ├── speakers/                       # Speaker list & VIP management
│   └── agenda/AgendaEditor.tsx         # Agenda builder & break settings
├── lib/
│   ├── reflow.ts                       # Mathematical reflow engine
│   ├── validation.ts                   # Centralized Zod schemas
│   ├── time.ts                         # Derived countdown & progress math
│   ├── syncClient.ts                   # Universal real-time subscriber
│   ├── store.ts                        # Seed data & in-memory state
│   └── ai/                             # Gemini, Groq & template orchestrator
├── tests/
│   ├── reflow.test.ts                  # +5m, +15m, +20m, absorption & cancel tests
│   ├── validation.test.ts              # Zod schema tests
│   └── ai-fallback.test.ts             # Triple fallback verification
├── firestore.rules                     # Production Firestore security rules
└── firestore.indexes.json              # Query indexing
```

---

## ⚙️ Installation & Running Locally

### 1. Prerequisites
- Node.js 18+ (tested on Node v24)
- npm

### 2. Setup
```bash
# Navigate to project
cd smart-anchor

# Install dependencies (if not already installed)
npm install

# Run unit tests
npm test

# Launch development server
npm run dev
```
Open [http://localhost:3000](http://localhost:3000) in your browser.

---

## 🔑 Environment Variables (`.env.example`)
Create `.env.local` to connect to production services (optional, local mode works out-of-the-box):
```env
NEXT_PUBLIC_FIREBASE_API_KEY=your_firebase_api_key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your-project-id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789
NEXT_PUBLIC_FIREBASE_APP_ID=1:123456789:web:abcdef

FIREBASE_ADMIN_PROJECT_ID=your-project-id
FIREBASE_ADMIN_CLIENT_EMAIL=firebase-adminsdk@your-project-id.iam.gserviceaccount.com
FIREBASE_ADMIN_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n..."

GEMINI_API_KEY=your_gemini_api_key
GROQ_API_KEY=your_groq_api_key
```

---

## ⚡ The 6-Minute Judge Demo Flow

1. **Login**: Click *Sign in as Organizer (Alex Rivera)* at `/login`.
2. **Dashboard**: Open **TechNova 2026 — AI Innovation Summit**.
3. **Preparation**: Review the 4 speakers and 7 agenda items with an absorbable buffer on the *Networking Tea Break*.
4. **Start Event**: Click **Enter Live Control Room** (`/events/technova-2026/live`).
5. **Anchor Multi-Device View**: Open a second window/phone at `/events/technova-2026/anchor`.
6. **Public Stage Display**: Open a third window at `/stage/TN26`.
7. **Generate Opening Script**: In Anchor view, click **Opening** &rarr; see speakable lines instantly generated.
8. **Complete Session**: Click **Mark Session Complete** &rarr; Keynote with Dr. Aris Vance becomes active on all 3 screens.
9. **The WOW Moment (+15 MIN DELAY)**:
   - In Organizer Control Room, click **+15 MIN DELAY**.
   - Watch the schedule reflow instantly.
   - The absorbable *Networking Tea Break* compresses by 15 min to cushion downstream sessions.
   - Anchor phone displays an amber **Live Schedule Adjustment** alert.
   - Stage Display reflects the adjusted timeline.
10. **Broadcast Announcement**: Click **Announce** &rarr; "Lunch will be served at Canteen 2" &rarr; Stage display shows alert banner in real-time.
11. **Summary & Audit**: Visit `/events/technova-2026/summary` to inspect planned vs. reflowed timeline and total savings.
