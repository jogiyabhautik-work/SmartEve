import * as admin from "firebase-admin";

const hasAdminConfig = Boolean(
  process.env.FIREBASE_ADMIN_PROJECT_ID &&
  process.env.FIREBASE_ADMIN_CLIENT_EMAIL &&
  process.env.FIREBASE_ADMIN_PRIVATE_KEY
);

function getAdminApp(): admin.app.App | null {
  if (!hasAdminConfig) return null;

  if (admin.apps.length > 0) {
    return admin.apps[0]!;
  }

  const privateKey = (process.env.FIREBASE_ADMIN_PRIVATE_KEY || "").replace(/\\n/g, "\n");

  return admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
      clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
      privateKey: privateKey,
    }),
  });
}

export const adminApp = getAdminApp();
export const adminDb = adminApp ? admin.firestore(adminApp) : null;
export const adminAuth = adminApp ? admin.auth(adminApp) : null;
