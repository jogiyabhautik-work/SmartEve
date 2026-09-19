import { Router, Request, Response } from "express";
import { query } from "../config/db.js";
import { sendSuccess, sendError } from "../utils/apiResponse.js";
import { requireFirebaseAuth, AuthenticatedRequest } from "../middleware/auth.js";

export const authRouter = Router();

// Register or synchronize a user in Neon DB
authRouter.post("/register", async (req: Request, res: Response) => {
  try {
    let {
      firebaseUid,
      email,
      fullName,
      role = "anchor",
      phoneNumber = null,
      bio = null,
      profileImageUrl = null,
      profileData = {},
    } = req.body;

    if (!email || !fullName) {
      return sendError(res, "email and fullName are required", "VALIDATION_ERROR", 400);
    }

    const cleanEmail = email.trim().toLowerCase();
    const cleanName = fullName.trim();
    const effectiveUid = firebaseUid && firebaseUid.trim().isNotEmpty
      ? firebaseUid.trim()
      : `local_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;

    const validRoles = ["admin", "organizer", "anchor"];
    const normalizedRole = validRoles.includes(role.toLowerCase()) ? role.toLowerCase() : "anchor";

    // 1. Check if user with this email already exists in Neon DB
    const existing = await query("SELECT * FROM users WHERE LOWER(email) = $1 LIMIT 1", [cleanEmail]);

    let userRecord;
    if (existing.length > 0) {
      // Update existing record
      const updateSql = `
        UPDATE users SET
          firebase_uid = COALESCE($1, firebase_uid),
          full_name = $2,
          role = $3,
          phone_number = COALESCE($4, phone_number),
          bio = COALESCE($5, bio),
          profile_image_url = COALESCE($6, profile_image_url),
          profile_data = $7,
          updated_at = CURRENT_TIMESTAMP
        WHERE LOWER(email) = $8
        RETURNING *;
      `;
      const updated = await query(updateSql, [
        effectiveUid,
        cleanName,
        normalizedRole,
        phoneNumber,
        bio,
        profileImageUrl,
        JSON.stringify(profileData),
        cleanEmail,
      ]);
      userRecord = updated[0];
    } else {
      // Insert new user
      const insertSql = `
        INSERT INTO users (
          firebase_uid,
          email,
          full_name,
          role,
          phone_number,
          bio,
          profile_image_url,
          profile_data
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *;
      `;
      const inserted = await query(insertSql, [
        effectiveUid,
        cleanEmail,
        cleanName,
        normalizedRole,
        phoneNumber,
        bio,
        profileImageUrl,
        JSON.stringify(profileData),
      ]);
      userRecord = inserted[0];
    }

    return sendSuccess(res, userRecord, 201);
  } catch (err: any) {
    console.error("Auth register error:", err);
    return sendError(res, err.message || "Failed to register user in Neon database", "SERVER_ERROR", 500);
  }
});

// Resilient direct login / lookup endpoint
authRouter.post("/login", async (req: Request, res: Response) => {
  try {
    const { email } = req.body;
    if (!email) {
      return sendError(res, "Email is required", "VALIDATION_ERROR", 400);
    }

    const cleanEmail = email.trim().toLowerCase();

    // 1. Search Neon DB
    const rows = await query("SELECT * FROM users WHERE LOWER(email) = $1 LIMIT 1", [cleanEmail]);
    if (rows.length > 0) {
      return sendSuccess(res, {
        user: rows[0],
        role: rows[0].role,
        neonId: rows[0].id,
        firebaseUid: rows[0].firebase_uid,
      });
    }

    // 2. Fallback to demo profiles if not yet saved in DB
    if (cleanEmail === "alex@technova.io") {
      return sendSuccess(res, {
        user: {
          id: "demo-organizer-alex",
          firebase_uid: "user-organizer-1",
          email: "alex@technova.io",
          full_name: "Alex Rivera",
          role: "organizer",
        },
        role: "organizer",
        neonId: "demo-organizer-alex",
        firebaseUid: "user-organizer-1",
      });
    }

    if (cleanEmail === "jordan@stageflow.io" || cleanEmail.includes("anchor")) {
      return sendSuccess(res, {
        user: {
          id: "demo-anchor-jordan",
          firebase_uid: "user-anchor-1",
          email: cleanEmail,
          full_name: "Jordan Hayes",
          role: "anchor",
        },
        role: "anchor",
        neonId: "demo-anchor-jordan",
        firebaseUid: "user-anchor-1",
      });
    }

    return sendError(res, "User not found in system. Please register first.", "USER_NOT_FOUND", 404);
  } catch (err: any) {
    console.error("Auth login error:", err);
    return sendError(res, err.message || "Failed to authenticate with database", "SERVER_ERROR", 500);
  }
});

// Quick role check endpoint by email or uid
authRouter.get("/role", async (req: Request, res: Response) => {
  try {
    const email = (req.query.email as string)?.trim().toLowerCase();
    const uid = req.query.uid as string;

    if (!email && !uid) {
      return sendError(res, "email or uid parameter required", "VALIDATION_ERROR", 400);
    }

    let rows;
    if (email) {
      rows = await query("SELECT id, role, full_name, firebase_uid FROM users WHERE LOWER(email) = $1 LIMIT 1", [email]);
    } else {
      rows = await query("SELECT id, role, full_name, firebase_uid FROM users WHERE firebase_uid = $1 LIMIT 1", [uid]);
    }

    if (rows && rows.length > 0) {
      return sendSuccess(res, {
        role: rows[0].role,
        neonId: rows[0].id,
        fullName: rows[0].full_name,
        firebaseUid: rows[0].firebase_uid,
      });
    }

    // Check demo accounts fallback
    if (email === "alex@technova.io") {
      return sendSuccess(res, { role: "organizer", neonId: "demo-organizer-alex" });
    }
    if (email && (email === "jordan@stageflow.io" || email.includes("anchor"))) {
      return sendSuccess(res, { role: "anchor", neonId: "demo-anchor-jordan" });
    }

    return sendError(res, "Role not found", "NOT_FOUND", 404);
  } catch (err: any) {
    console.error("Auth role query error:", err);
    return sendError(res, err.message || "Failed to query role", "SERVER_ERROR", 500);
  }
});

// Get currently authenticated user profile
authRouter.get("/me", requireFirebaseAuth, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const firebaseUid = req.user?.uid;
    if (!firebaseUid) {
      return sendError(res, "Unauthorized", "UNAUTHORIZED", 401);
    }

    const rows = await query("SELECT * FROM users WHERE firebase_uid = $1", [firebaseUid]);
    if (rows.length === 0) {
      return sendError(res, "User profile not found in Neon", "NOT_FOUND", 404);
    }

    return sendSuccess(res, rows[0]);
  } catch (err: any) {
    console.error("Auth me error:", err);
    return sendError(res, err.message || "Failed to fetch user profile", "SERVER_ERROR", 500);
  }
});
