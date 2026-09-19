"use client";

import React, { useState, useEffect } from "react";
import { AgendaItem } from "@/types/agenda";
import { Speaker } from "@/types/speaker";
import { ScriptType, ScriptSource } from "@/types/script";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { SCRIPT_TYPE_LABELS } from "@/lib/constants";
import { Sparkles, Copy, Check, Volume2, VolumeX, RotateCcw, Edit3, Save } from "lucide-react";
import { notify } from "@/components/ui/toast";
import { broadcastStateChange } from "@/lib/syncClient";

export interface AnchorAssistPanelProps {
  eventId: string;
  currentItem: AgendaItem | null;
  nextItem: AgendaItem | null;
  speakers: Speaker[];
  totalDelayMin?: number;
}

export function AnchorAssistPanel({
  eventId,
  currentItem,
  nextItem,
  speakers,
  totalDelayMin = 0,
}: AnchorAssistPanelProps) {
  const [activeType, setActiveType] = useState<ScriptType>("speaker_intro");
  const [scriptText, setScriptText] = useState("");
  const [scriptSource, setScriptSource] = useState<ScriptSource>("ai");
  const [scriptProvider, setScriptProvider] = useState<string>("gemini");
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [isSpeaking, setIsSpeaking] = useState(false);

  // Auto-generate script on mount or when active session changes
  const handleGenerate = async (typeToGenerate = activeType) => {
    setLoading(true);
    setIsEditing(false);
    try {
      const res = await fetch("/api/ai/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          eventId,
          type: typeToGenerate,
          itemId: currentItem?.id,
          delayMinutes: totalDelayMin,
        }),
      });

      const data = await res.json();
      if (data.success && data.data) {
        setScriptText(data.data.script);
        setScriptSource(data.data.source);
        setScriptProvider(data.data.provider || "template");
        broadcastStateChange("script_generated", { type: typeToGenerate });
      } else {
        notify({ type: "error", message: "Failed to generate script" });
      }
    } catch (e) {
      notify({ type: "error", message: "Network error generating script" });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // Generate initial intro or welcome
    if (currentItem && !scriptText) {
      const initialType: ScriptType = currentItem.type === "opening" ? "opening" : "speaker_intro";
      setActiveType(initialType);
      handleGenerate(initialType);
    }
  }, [currentItem?.id]);

  const handleCopy = () => {
    if (!scriptText) return;
    navigator.clipboard.writeText(scriptText);
    setCopied(true);
    notify({ type: "success", message: "Script copied to clipboard!" });
    setTimeout(() => setCopied(false), 2000);
  };

  const handleSpeak = () => {
    if (typeof window === "undefined" || !("speechSynthesis" in window)) {
      notify({ type: "warning", message: "Speech synthesis not supported in this browser." });
      return;
    }

    if (isSpeaking) {
      window.speechSynthesis.cancel();
      setIsSpeaking(false);
      return;
    }

    const utterance = new SpeechSynthesisUtterance(scriptText);
    utterance.rate = 1.0;
    utterance.pitch = 1.0;
    utterance.onend = () => setIsSpeaking(false);
    utterance.onerror = () => setIsSpeaking(false);

    window.speechSynthesis.speak(utterance);
    setIsSpeaking(true);
  };

  const categories: ScriptType[] = [
    "opening",
    "speaker_intro",
    "transition",
    "delay",
    "unexpected",
    "closing",
  ];

  return (
    <div className="bg-surface border border-surface-border rounded-2xl p-6 shadow-xl flex flex-col justify-between h-full relative">
      {/* Header */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <div className="p-2 rounded-xl bg-primary/20 text-indigo-400 border border-primary/30">
              <Sparkles className="w-5 h-5 animate-pulse" />
            </div>
            <div>
              <h3 className="text-base font-bold text-white leading-none">Anchor Co-Pilot</h3>
              <span className="text-xs text-slate-400">Contextual Stage Assistant</span>
            </div>
          </div>

          {/* Source badge */}
          {scriptText && (
            <Badge
              variant={scriptSource === "ai" ? "ai" : scriptSource === "template" ? "template" : "manual"}
            >
              {scriptSource === "ai"
                ? `AI (${scriptProvider.toUpperCase()})`
                : scriptSource === "template"
                ? "TEMPLATE FALLBACK"
                : "MANUAL EDIT"}
            </Badge>
          )}
        </div>

        {/* Category Pills */}
        <div className="flex flex-wrap gap-1.5 mb-5">
          {categories.map((cat) => (
            <button
              key={cat}
              onClick={() => {
                setActiveType(cat);
                handleGenerate(cat);
              }}
              className={`px-2.5 py-1.5 rounded-lg text-xs font-semibold transition-all select-none ${
                activeType === cat
                  ? "bg-primary text-white shadow-md shadow-primary/25"
                  : "bg-surface-light text-slate-400 hover:text-white hover:bg-surface-border"
              }`}
            >
              {SCRIPT_TYPE_LABELS[cat] || cat}
            </button>
          ))}
        </div>

        {/* Script Display / Editor Box */}
        <div className="bg-background/90 border border-surface-border rounded-xl p-4 mb-4 min-h-[160px] relative flex flex-col justify-between">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-10 space-y-3">
              <div className="w-6 h-6 border-2 border-primary border-t-transparent rounded-full animate-spin" />
              <div className="text-xs text-slate-400 animate-pulse font-medium">
                Generating speakable {SCRIPT_TYPE_LABELS[activeType]}...
              </div>
            </div>
          ) : isEditing ? (
            <textarea
              value={scriptText}
              onChange={(e) => {
                setScriptText(e.target.value);
                setScriptSource("manual");
              }}
              className="w-full h-36 bg-transparent text-white text-sm font-medium resize-none focus:outline-none leading-relaxed"
              autoFocus
            />
          ) : (
            <div className="text-sm md:text-base text-slate-100 font-medium leading-relaxed select-text">
              {scriptText ? (
                `"${scriptText}"`
              ) : (
                <span className="text-slate-500 italic">No script generated yet. Select a category above.</span>
              )}
            </div>
          )}

          {/* Word count & deliverable estimate */}
          {scriptText && !loading && (
            <div className="flex items-center justify-between pt-3 mt-3 border-t border-surface-border/60 text-[11px] text-slate-400 font-mono">
              <span>{scriptText.split(/\s+/).filter(Boolean).length} words</span>
              <span>~{Math.round((scriptText.split(/\s+/).filter(Boolean).length / 130) * 60)}s spoken</span>
            </div>
          )}
        </div>
      </div>

      {/* Script Actions */}
      <div className="grid grid-cols-4 gap-2 pt-3 border-t border-surface-border">
        {/* Copy */}
        <Button variant="secondary" size="sm" onClick={handleCopy} title="Copy to clipboard">
          {copied ? <Check className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4" />}
          <span className="hidden sm:inline">{copied ? "Copied" : "Copy"}</span>
        </Button>

        {/* Edit / Save */}
        <Button
          variant={isEditing ? "primary" : "secondary"}
          size="sm"
          onClick={() => setIsEditing(!isEditing)}
          title="Edit script"
        >
          {isEditing ? <Save className="w-4 h-4 text-white" /> : <Edit3 className="w-4 h-4" />}
          <span className="hidden sm:inline">{isEditing ? "Save" : "Edit"}</span>
        </Button>

        {/* Read Aloud */}
        <Button
          variant={isSpeaking ? "danger" : "secondary"}
          size="sm"
          onClick={handleSpeak}
          title="Read aloud"
        >
          {isSpeaking ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
          <span className="hidden sm:inline">{isSpeaking ? "Stop" : "Speak"}</span>
        </Button>

        {/* Regenerate */}
        <Button
          variant="secondary"
          size="sm"
          onClick={() => handleGenerate()}
          isLoading={loading}
          title="Regenerate script"
        >
          <RotateCcw className="w-4 h-4" />
          <span className="hidden sm:inline">Regen</span>
        </Button>
      </div>
    </div>
  );
}
