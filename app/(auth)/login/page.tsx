"use client";

import React, { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { switchUserRole } from "@/lib/auth";
import { Radio, Shield, Smartphone, ArrowRight } from "lucide-react";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("alex@technova.io");
  const [password, setPassword] = useState("password123");

  const handleFastLogin = (role: "organizer" | "anchor") => {
    switchUserRole(role);
    if (role === "anchor") {
      router.push("/events/technova-2026/anchor");
    } else {
      router.push("/dashboard");
    }
  };

  return (
    <div className="min-h-screen bg-background text-slate-100 flex items-center justify-center p-4">
      <div className="w-full max-w-md p-8 rounded-3xl bg-surface border border-surface-border shadow-2xl space-y-6">
        {/* Brand */}
        <div className="text-center space-y-2">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-primary to-indigo-400 flex items-center justify-center text-white mx-auto shadow-lg shadow-primary/25">
            <Radio className="w-6 h-6 animate-pulse" />
          </div>
          <h2 className="text-2xl font-extrabold text-white tracking-tight">
            Smart Anchor Login
          </h2>
          <p className="text-xs text-slate-400">
            Select your event role to access your live co-pilot workspace
          </p>
        </div>

        {/* 1-Click Fast Login for Hackathon Judges */}
        <div className="space-y-3">
          <label className="text-[11px] font-bold uppercase tracking-wider text-slate-400 block text-center">
            Instant Demo Access
          </label>

          <Button
            variant="primary"
            size="lg"
            className="w-full font-bold justify-between"
            onClick={() => handleFastLogin("organizer")}
          >
            <span className="flex items-center gap-2">
              <Shield className="w-4 h-4" />
              Sign in as Organizer (Alex Rivera)
            </span>
            <ArrowRight className="w-4 h-4" />
          </Button>

          <Button
            variant="secondary"
            size="lg"
            className="w-full font-bold justify-between"
            onClick={() => handleFastLogin("anchor")}
          >
            <span className="flex items-center gap-2">
              <Smartphone className="w-4 h-4" />
              Sign in as Anchor (Jordan Hayes)
            </span>
            <ArrowRight className="w-4 h-4" />
          </Button>
        </div>

        <div className="relative flex py-2 items-center">
          <div className="flex-grow border-t border-surface-border"></div>
          <span className="flex-shrink mx-4 text-xs font-mono text-slate-500">OR</span>
          <div className="flex-grow border-t border-surface-border"></div>
        </div>

        {/* Standard Form */}
        <form
          onSubmit={(e) => {
            e.preventDefault();
            handleFastLogin("organizer");
          }}
          className="space-y-4"
        >
          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1">Email Address</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-background border border-surface-border rounded-xl px-3.5 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <div>
            <label className="text-xs font-semibold text-slate-300 block mb-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full bg-background border border-surface-border rounded-xl px-3.5 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-primary"
            />
          </div>

          <Button type="submit" variant="secondary" className="w-full">
            Log In with Credentials
          </Button>
        </form>
      </div>
    </div>
  );
}
