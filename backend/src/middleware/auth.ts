import { Request, Response, NextFunction } from "express";
import { adminAuth } from "../config/firebaseAdmin.js";
import { sendError } from "../utils/apiResponse.js";

export interface AuthenticatedRequest extends Request {
  user?: {
    uid: string;
    email?: string;
    role?: string;
  };
}

export async function requireFirebaseAuth(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    // If Firebase Admin is not configured or in demo mode, inject fallback demo user
    if (!adminAuth) {
      req.user = {
        uid: "user-organizer-1",
        email: "alex@technova.io",
        role: "organizer",
      };
      return next();
    }
    return sendError(res, "Missing or invalid Authorization header", "UNAUTHORIZED", 401);
  }

  const idToken = authHeader.split("Bearer ")[1];

  if (!adminAuth) {
    req.user = {
      uid: "user-organizer-1",
      email: "alex@technova.io",
      role: "organizer",
    };
    return next();
  }

  try {
    const decodedToken = await adminAuth.verifyIdToken(idToken);
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      role: (decodedToken as any).role || "anchor",
    };
    next();
  } catch (err) {
    return sendError(res, "Invalid or expired Firebase auth token", "UNAUTHORIZED", 401);
  }
}
