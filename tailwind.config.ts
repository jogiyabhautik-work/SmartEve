import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        background: "#0B1020",
        surface: "#141B34",
        "surface-light": "#1E2749",
        "surface-border": "#27345D",
        primary: {
          DEFAULT: "#6366F1",
          hover: "#4F46E5",
          light: "#818CF8",
        },
        live: {
          DEFAULT: "#22C55E",
          glow: "rgba(34, 197, 94, 0.25)",
        },
        warning: {
          DEFAULT: "#F59E0B",
          glow: "rgba(245, 158, 11, 0.25)",
        },
        danger: {
          DEFAULT: "#EF4444",
          glow: "rgba(239, 68, 68, 0.25)",
        },
      },
      fontFamily: {
        sans: ["var(--font-inter)", "Inter", "system-ui", "sans-serif"],
        mono: ["var(--font-mono)", "JetBrains Mono", "monospace"],
      },
      animation: {
        "pulse-slow": "pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite",
        "live-ping": "ping 1.5s cubic-bezier(0, 0, 0.2, 1) infinite",
      },
    },
  },
  plugins: [],
};

export default config;
