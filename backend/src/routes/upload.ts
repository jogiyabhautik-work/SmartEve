import { Router, Request, Response } from "express";
import { uploadToCloudinary, isCloudinaryConfigured } from "../config/cloudinary.js";
import { sendError, sendSuccess } from "../utils/apiResponse.js";

export const uploadRouter = Router();

uploadRouter.post("/image", async (req: Request, res: Response) => {
  try {
    const { image, folder } = req.body;

    if (!image) {
      return sendError(res, "Missing 'image' field (base64 string or image URL required)", "VALIDATION_ERROR", 400);
    }

    const secureUrl = await uploadToCloudinary(image, folder || "smarteve/speakers");

    return sendSuccess(res, {
      url: secureUrl,
      provider: isCloudinaryConfigured ? "cloudinary" : "placeholder",
    });
  } catch (err) {
    console.error("Cloudinary upload error:", err);
    return sendError(res, "Failed to upload image to Cloudinary", "UPLOAD_ERROR", 500);
  }
});
