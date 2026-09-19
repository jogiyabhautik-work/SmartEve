import { v2 as cloudinary, UploadApiResponse } from "cloudinary";
import dotenv from "dotenv";

dotenv.config();

const isCloudinaryConfigured = Boolean(
  process.env.CLOUDINARY_CLOUD_NAME &&
  process.env.CLOUDINARY_API_KEY &&
  process.env.CLOUDINARY_API_SECRET
);

if (isCloudinaryConfigured) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true,
  });
  console.log("☁️ Cloudinary SDK configured successfully");
} else {
  console.log("ℹ️ Cloudinary credentials not set — image uploads will return fallback URLs");
}

export { cloudinary, isCloudinaryConfigured };

/**
 * Uploads a base64 or file buffer to Cloudinary
 */
export async function uploadToCloudinary(
  fileData: string,
  folder = "smarteve/speakers"
): Promise<string> {
  if (!isCloudinaryConfigured) {
    // Return placeholder avatar if Cloudinary credentials are not configured yet
    return "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop";
  }

  const result: UploadApiResponse = await cloudinary.uploader.upload(fileData, {
    folder,
    transformation: [
      { width: 500, height: 500, crop: "fill", gravity: "face" },
      { fetch_format: "auto", quality: "auto" },
    ],
  });

  return result.secure_url;
}
