"use client";

import { useState, useEffect } from "react";

// 静的エクスポートは slug=[] を HTML に埋め込むため、マウント後に
// window.location から実際のパスを読み直す必要がある。
/* eslint-disable react-hooks/set-state-in-effect */
export function useRouteSlug(prefix: string) {
  const [slug, setSlug] = useState<string[] | undefined>(undefined);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    const path = window.location.pathname.replace(/\/+$/, "");
    const segments = path.split("/").filter(Boolean);
    const prefixIndex = segments.indexOf(prefix);
    const sub = prefixIndex >= 0 ? segments.slice(prefixIndex + 1) : [];
    setSlug(sub.length > 0 ? sub : undefined);
    setMounted(true);
  }, [prefix]);

  return { slug, mounted };
}
