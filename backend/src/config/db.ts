import { Pool } from "@neondatabase/serverless";
import dotenv from "dotenv";

dotenv.config();

const connectionString = process.env.DATABASE_URL;

export const hasDbConfig = Boolean(connectionString && connectionString.trim().length > 0);

let pool: Pool | null = null;

if (hasDbConfig) {
  try {
    pool = new Pool({ connectionString });
    console.log("🐘 Neon.tech PostgreSQL connection pool initialized");
  } catch (err) {
    console.warn("Failed to initialize Neon connection pool:", (err as Error).message);
  }
} else {
  console.log("ℹ️ DATABASE_URL not set — using in-memory store fallback");
}

export const dbPool = pool;

export async function query<T = any>(text: string, params?: any[]): Promise<T[]> {
  if (!dbPool) {
    throw new Error("Neon Database is not configured. Set DATABASE_URL in .env");
  }
  const result = await dbPool.query(text, params);
  return result.rows as T[];
}
