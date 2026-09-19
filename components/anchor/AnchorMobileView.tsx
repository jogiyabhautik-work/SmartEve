"use client";

import React, { useState, useEffect } from "react";
import { EventData } from "@/types/event";
import { AgendaItem } from "@/types/agenda";
import { Speaker } from "@/types/speaker";
import { EventNotification } from "@/types/notification";
import { ScriptType, ScriptSource } from "@/types/script";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { TimerDisplay } from "@/components/live/TimerDisplay";
import { formatTimeDisplay } from "@/lib/time";
import { SCRIPT_TYPE_LABELS } from "@/lib/constants";
import {
  CheckCircle2,
  Sparkles,
  Volume2,
  VolumeX,
  Copy,
  Check,
  RotateCcw,
  PlusCircle,
  AlertTriangle,
  ArrowRight,
  User,
  Radio,
} from "lucide-react";
import { notify } from "@/components/ui/toast";
import { broadcastStateChange } from "@/lib/syncClient";

export interface AnchorMobileViewProps {
  event: EventData;
  currentItem: AgendaItem | null;
  nextItem: AgendaItem | null;
  speakers: Speaker[];
  notifications: EventNotification[];
  timerDisplay: {
    formatted: string;
    isOvertime: boolean;
    minutes: number;
    remainingSeconds: number;
  };
  progressPercent: number;
}

export function AnchorMobileView({
  event,
  currentItem,
  nextItem,
  speakers,
  notifications,
  timerDisplay,
  progressPercent,
}: AnchorMobileViewProps) {
  const [activeType, setActiveType] = useState<ScriptType>("speaker_intro");
  const [scriptText, setScriptText] = useState("");
  const [scriptSource, setScriptSource] = useState<ScriptSource>("ai");
  const [scriptProvider, setScriptProvider] = useState<string>("gemini");
  const [generating, setGenerating] = useState(false);
  const [completing, setCompleting] = useState(false);
  const [copied, setCopied] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);

  // Associated speaker
  const currentSpeaker = currentItem
    ? speakers.find((s) => currentItem.speakerIds.includes(s.id))
    : null;

  // Generate script
  const handleGenerateScript = async (typeToGenerate: ScriptType = activeType) => {
    setActiveType(typeToGenerate);
    setGenerating(true);
    try {
      const res = await fetch("/api/ai/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          eventId: event.id,
          type: typeToGenerate,
          itemId: currentItem?.id,
          delayMinutes: event.liveState.totalDelayMin,
        }),
      });

      const data = await res.json();
      if (data.success && data.data) {
        setScriptText(data.data.script);
        setScriptSource(data.data.source);
        setScriptProvider(data.data.provider || "template");
        broadcastStateChange("script_generated", { type: typeToGenerate });
      }
    } catch (e) {
      notify({ type: "error", message: "Error generating script" });
    } finally {
      setGenerating(false);
    }
  };

  // Initial load
  useEffect(() => {
    if (currentItem && !scriptText) {
      const initialType = currentItem.type === "opening" ? "opening" : "speaker_intro";
      handleGenerateScript(initialType);
    }
  }, [currentItem?.id]);

  // Complete current session
  const handleComplete = async () => {
    setCompleting(true);
    try {
      const res = await fetch(`/api/events/${event.id}/complete-current`, {
        method: "POST",
      });
      const data = await res.json();
      if (data.success) {
        broadcastStateChange("complete_current");
        notify({ type: "success", message: "Session marked complete!" });
        setScriptText(""); // Reset for next session
      }
    } catch (e) {
      notify({ type: "error", message: "Failed to mark complete" });
    } finally {
      setCompleting(false);
    }
  };

  const handleCopy = () => {
    if (!scriptText) return;
    navigator.clipboard.writeText(scriptText);
    setCopied(true);
    notify({ type: "success", message: "Script copied!" });
    setTimeout(() => setCopied(false), 2000);
  };

  const handleSpeak = () => {
    if (typeof window === "undefined" || !("speechSynthesis" in window)) return;
    if (isSpeaking) {
      window.speechSynthesis.cancel();
      setIsSpeaking(false);
      return;
    }
    const utterance = new SpeechSynthesisUtterance(scriptText);
    utterance.rate = 1.0;
    utterance.onend = () => setIsSpeaking(false);
    utterance.onerror = () => setIsSpeaking(false);
    window.speechSynthesis.speak(utterance);
    setIsSpeaking(true);
  };

  const latestDelayNotification = notifications.find(
    (n) => n.type === "delay" && Date.now() - n.createdAt < 5 * 60 * 1000
  );

  return (
    <div className="min-h-screen bg-background text-slate-100 p-4 pb-20 max-w-lg mx-auto flex flex-col space-y-4 select-none">
      {/* Top Header Bar */}
      <div className="flex items-center justify-between pb-2 border-b border-surface-border">
        <div className="flex items-center gap-2">
          <Badge variant="live" pulse={true}>
            STAGE CO-PILOT
          </Badge>
          <span className="text-xs font-bold text-white tracking-tight truncate max-w-[180px]">
            {event.name}
          </span>
        </div>

        {event.liveState.totalDelayMin !== 0 && (
          <Badge variant="warning">
            {event.liveState.totalDelayMin > 0 ? `+${event.liveState.totalDelayMin}m` : `${event.liveState.totalDelayMin}m`}
          </Badge>
        )}
      </div>

      {/* Delay Alert Banner if organizer shifted schedule */}
      {latestDelayNotification && (
        <div className="p-3.5 rounded-2xl bg-amber-500/15 border border-amber-500/40 text-amber-200 flex items-start gap-2.5 animate-bounce">
          <AlertTriangle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
          <div className="text-xs flex-1">
            <div className="font-bold text-amber-100 uppercase tracking-wider text-[11px]">
              Live Schedule Adjustment
            </div>
            <div className="mt-0.5">{latestDelayNotification.message}</div>
          </div>
          <Button
            size="sm"
            variant="amber"
            onClick={() => handleGenerateScript("delay")}
            className="text-[11px] px-2 h-7 font-bold shrink-0"
          >
            Gen Delay Script
          </Button>
        </div>
      )}

      {/* Huge Stage Timer */}
      <TimerDisplay
        formatted={timerDisplay.formatted}
        isOvertime={timerDisplay.isOvertime}
        minutes={timerDisplay.minutes}
        remainingSeconds={timerDisplay.remainingSeconds}
        progressPercent={progressPercent}
        size="huge"
      />

      {/* Current Session Overview */}
      {currentItem && (
        <div className="p-4 rounded-2xl bg-surface border border-surface-border shadow-lg">
          <div className="text-[11px] font-mono text-slate-400 uppercase tracking-wider mb-1 flex items-center justify-between">
            <span>NOW ON STAGE</span>
            <span>{formatTimeDisplay(currentItem.startTime)} – {formatTimeDisplay(currentItem.endTime)}</span>
          </div>
          <h2 className="text-xl font-black text-white leading-tight mb-2">
            {currentItem.title}
          </h2>

          {currentSpeaker && (
            <div className="flex items-center gap-3 mt-2 p-2.5 rounded-xl bg-surface-light/60 border border-surface-border">
              {currentSpeaker.photoUrl ? (
                <img
                  src={currentSpeaker.photoUrl}
                  alt={currentSpeaker.name}
                  className="w-10 h-10 rounded-xl object-cover"
                />
              ) : (
                <User className="w-8 h-8 text-slate-400" />
              )}
              <div className="min-w-0">
                <div className="text-sm font-bold text-white truncate">{currentSpeaker.name}</div>
                <div className="text-xs text-slate-400 truncate">
                  {currentSpeaker.designation} · {currentSpeaker.organization}
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Next Activity Preview */}
      {nextItem && (
        <div className="p-3 rounded-xl bg-surface/50 border border-surface-border text-xs flex items-center justify-between">
          <div className="min-w-0">
            <span className="text-[10px] font-mono text-primary-light font-bold uppercase block">
              UP NEXT
            </span>
            <span className="font-semibold text-slate-200 truncate block">
              {nextItem.title}
            </span>
          </div>
          <span className="font-mono text-slate-400 text-[11px] shrink-0 ml-2">
            {formatTimeDisplay(nextItem.startTime)}
          </span>
        </div>
      )}

      {/* Quick 1-Tap Script Generation Buttons */}
      <div>
        <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
          1-Tap Stage Script
        </div>
        <div className="grid grid-cols-3 gap-2">
          <Button
            size="touch"
            variant={activeType === "speaker_intro" ? "primary" : "secondary"}
            onClick={() => handleGenerateScript("speaker_intro")}
            isLoading={generating && activeType === "speaker_intro"}
            className="text-xs font-bold h-14"
          >
            Speaker Intro
          </Button>

          <Button
            size="touch"
            variant={activeType === "transition" ? "primary" : "secondary"}
            onClick={() => handleGenerateScript("transition")}
            isLoading={generating && activeType === "transition"}
            className="text-xs font-bold h-14"
          >
            Transition
          </Button>

          <Button
            size="touch"
            variant={activeType === "delay" ? "amber" : "secondary"}
            onClick={() => handleGenerateScript("delay")}
            isLoading={generating && activeType === "delay"}
            className="text-xs font-bold h-14"
          >
            Delay Alert
          </Button>
        </div>
      </div>

      {/* Generated Script Teleprompter Card */}
      <div className="p-4 rounded-2xl bg-surface border border-surface-border shadow-xl space-y-3">
        <div className="flex items-center justify-between">
          <span className="text-xs font-bold text-white uppercase tracking-wider flex items-center gap-1.5">
            <Sparkles className="w-4 h-4 text-primary" />
            Teleprompter View
          </span>
          {scriptText && (
            <Badge variant={scriptSource === "ai" ? "ai" : "template"}>
              {scriptSource === "ai" ? `AI (${scriptProvider})` : "TEMPLATE"}
            </Badge>
          )}
        </div>

        <div className="p-4 rounded-xl bg-background border border-surface-border text-base md:text-lg text-white font-medium leading-relaxed select-text min-h-[120px]">
          {generating ? (
            <div className="flex items-center justify-center py-6 text-sm text-slate-400 animate-pulse">
              Crafting stage speech...
            </div>
          ) : scriptText ? (
            `"${scriptText}"`
          ) : (
            <span className="text-slate-500 italic text-sm">
              Tap a button above to generate spoken lines instantly.
            </span>
          )}
        </div>

        {/* Teleprompter actions */}
        <div className="grid grid-cols-3 gap-2">
          <Button size="md" variant="secondary" onClick={handleCopy} className="text-xs">
            {copied ? <Check className="w-4 h-4 mr-1 text-emerald-400" /> : <Copy className="w-4 h-4 mr-1" />}
            {copied ? "Copied" : "Copy"}
          </Button>

          <Button
            size="md"
            variant={isSpeaking ? "danger" : "secondary"}
            onClick={handleSpeak}
            className="text-xs"
          >
            {isSpeaking ? <VolumeX className="w-4 h-4 mr-1" /> : <Volume2 className="w-4 h-4 mr-1" />}
            {isSpeaking ? "Stop" : "Read Aloud"}
          </Button>

          <Button
            size="md"
            variant="secondary"
            onClick={() => handleGenerateScript()}
            isLoading={generating}
            className="text-xs"
          >
            <RotateCcw className="w-4 h-4 mr-1" />
            Regen
          </Button>
        </div>
      </div>

      {/* 1-Tap Giant Complete Button */}
      <div className="pt-2">
        <Button
          variant="live"
          size="touch"
          onClick={handleComplete}
          isLoading={completing}
          className="w-full text-lg font-black h-16 min-h-[64px] shadow-2xl shadow-emerald-500/25 active:scale-[0.97]"
        >
          <CheckCircle2 className="w-6 h-6 mr-2" />
          COMPLETE SESSION & PROGRESS
        </Button>
      </div>
    </div>
  );
}
