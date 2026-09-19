import { adminDb } from "../lib/firebaseAdmin";
import {
  INITIAL_DEMO_EVENT,
  INITIAL_DEMO_AGENDA,
  INITIAL_DEMO_SPEAKERS,
  INITIAL_DEMO_USERS,
} from "../lib/store";

async function seedDatabase() {
  console.log("Starting database seed for Smart Anchor & Stage Flow...");

  if (!adminDb) {
    console.log("No Firebase Admin connection configured. In-memory and mock store will be used out-of-the-box.");
    return;
  }

  const batch = adminDb.batch();

  // 1. Seed Users
  for (const [uid, user] of Object.entries(INITIAL_DEMO_USERS)) {
    const userRef = adminDb.collection("users").doc(uid);
    batch.set(userRef, user, { merge: true });
  }

  // 2. Seed Event
  const eventRef = adminDb.collection("events").doc(INITIAL_DEMO_EVENT.id);
  batch.set(eventRef, INITIAL_DEMO_EVENT, { merge: true });

  // 3. Seed Speakers
  for (const [spkId, speaker] of Object.entries(INITIAL_DEMO_SPEAKERS)) {
    const spkRef = eventRef.collection("speakers").doc(spkId);
    batch.set(spkRef, speaker, { merge: true });
  }

  // 4. Seed Agenda Items
  for (const [itemId, item] of Object.entries(INITIAL_DEMO_AGENDA)) {
    const itemRef = eventRef.collection("agenda").doc(itemId);
    batch.set(itemRef, item, { merge: true });
  }

  await batch.commit();
  console.log("Successfully seeded TechNova 2026 into Firestore!");
}

seedDatabase().catch((err) => {
  console.error("Error seeding database:", err);
});
