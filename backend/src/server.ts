import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { eventsRouter } from "./routes/events.js";
import { agendaRouter } from "./routes/agenda.js";
import { speakersRouter } from "./routes/speakers.js";
import { aiRouter } from "./routes/ai.js";
import { publicRouter } from "./routes/public.js";
import { uploadRouter } from "./routes/upload.js";
import { APP_NAME, APP_TAGLINE } from "./config/constants.js";
import "./config/db.js";
import "./config/cloudinary.js";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 4000;

// Enable CORS for Flutter mobile app, emulator, and web clients
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

app.use(express.json({ limit: "10mb" }));

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on("finish", () => {
    const duration = Date.now() - start;
    console.log(`[${req.method}] ${req.originalUrl} -> ${res.statusCode} (${duration}ms)`);
  });
  next();
});

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    app: APP_NAME,
    tagline: APP_TAGLINE,
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// Mount modular API routes
app.use("/api/events", eventsRouter);
app.use("/api/events", agendaRouter);
app.use("/api/events", speakersRouter);
app.use("/api/ai", aiRouter);
app.use("/api/public", publicRouter);
app.use("/api/upload", uploadRouter);

// Global Error Handler
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error("Unhandled server error:", err);
  res.status(500).json({
    success: false,
    error: {
      code: "INTERNAL_SERVER_ERROR",
      message: err.message || "An unexpected error occurred",
    },
  });
});

// Start listening if run directly
if (process.env.NODE_ENV !== "test") {
  app.listen(PORT, () => {
    console.log(`=========================================`);
    console.log(`⚡ ${APP_NAME} Backend Engine Running`);
    console.log(`📡 URL: http://localhost:${PORT}`);
    console.log(`🎯 Health check: http://localhost:${PORT}/api/health`);
    console.log(`📱 Flutter Mobile API base: http://10.0.2.2:${PORT}/api (Android Emulator)`);
    console.log(`=========================================`);
  });
}

export default app;
