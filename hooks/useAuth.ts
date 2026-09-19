"use client";

import { useEffect, useState } from "react";
import { User, UserRole } from "@/types/user";
import { getCurrentUser, switchUserRole } from "@/lib/auth";

export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setUser(getCurrentUser());
    setLoading(false);

    const handleStorage = () => {
      setUser(getCurrentUser());
    };

    window.addEventListener("storage", handleStorage);
    return () => window.removeEventListener("storage", handleStorage);
  }, []);

  const switchRole = (newRole: UserRole) => {
    const updated = switchUserRole(newRole);
    setUser(updated);
  };

  return { user, loading, switchRole };
}
