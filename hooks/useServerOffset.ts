"use client";

import { useEffect, useState } from "react";

export function useServerOffset() {
  const [offsetMs, setOffsetMs] = useState(0);

  useEffect(() => {
    // Probe server timestamp to estimate delta
    const clientReqTime = Date.now();
    fetch("/api/public/time", { method: "HEAD" })
      .then((res) => {
        const serverDateHeader = res.headers.get("date");
        if (serverDateHeader) {
          const serverTime = new Date(serverDateHeader).getTime();
          const clientResTime = Date.now();
          const roundTrip = (clientResTime - clientReqTime) / 2;
          const estimatedServerNow = serverTime + roundTrip;
          setOffsetMs(estimatedServerNow - clientResTime);
        }
      })
      .catch(() => {
        setOffsetMs(0);
      });
  }, []);

  return offsetMs;
}
