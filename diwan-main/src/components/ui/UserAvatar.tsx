/**
 * UserAvatar — a professional, consistent avatar for every person in the app.
 *
 * Priority:
 *  1. Real photo  (`src` prop — e.g. photoURL from Firebase)
 *  2. DiceBear `notionists-neutral` generated SVG (keyed on `name`/`seed`)
 *  3. Gradient initial badge fallback (offline / blocked network)
 *
 * Usage:
 *   <UserAvatar name="Aisha Khan" size="md" />
 *   <UserAvatar name="Mr. Ali" src={user.photoURL} size="lg" />
 */

import { useState } from "react";
import { cn } from "@/lib/utils";

// --- Size map ----------------------------------------------------------------
const SIZES = {
  "2xs": { root: "h-5 w-5",   text: "text-[7px]",  ring: "ring-1" },
  xs:    { root: "h-6 w-6",   text: "text-[8px]",  ring: "ring-1" },
  sm:    { root: "h-7 w-7",   text: "text-[9px]",  ring: "ring-1" },
  md:    { root: "h-8 w-8",   text: "text-[10px]", ring: "ring-[1.5px]" },
  lg:    { root: "h-10 w-10", text: "text-xs",     ring: "ring-2" },
  xl:    { root: "h-12 w-12", text: "text-sm",     ring: "ring-2" },
  "2xl": { root: "h-16 w-16", text: "text-base",   ring: "ring-2" },
  "3xl": { root: "h-20 w-20", text: "text-lg",     ring: "ring-2" },
};
type AvatarSize = keyof typeof SIZES;

// --- Palette for gradient fallback -------------------------------------------
const GRADIENTS: [string, string][] = [
  ["#6366F1", "#8B5CF6"],
  ["#8B5CF6", "#D946EF"],
  ["#EC4899", "#F97316"],
  ["#0EA5E9", "#6366F1"],
  ["#10B981", "#0EA5E9"],
  ["#F59E0B", "#EF4444"],
  ["#6366F1", "#EC4899"],
  ["#14B8A6", "#6366F1"],
];

function hashName(name: string): number {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  return h;
}

function getInitials(name: string): string {
  return name.trim().split(/\s+/).slice(0, 2).map((w) => w[0] || "").join("").toUpperCase() || "?";
}

import { getCustomAvatar } from "@/lib/avatarHelper";

function dicebearUrl(seed: string, name?: string): string {
  return getCustomAvatar(name || seed);
}

// --- Component ---------------------------------------------------------------
interface UserAvatarProps {
  name?: string;
  seed?: string;
  src?: string | null;
  size?: AvatarSize;
  className?: string;
  shape?: "circle" | "rounded";
  ring?: boolean;
  ringColor?: string;
}

export function UserAvatar({
  name = "",
  seed,
  src,
  size = "md",
  className,
  shape = "circle",
  ring = false,
  ringColor = "ring-white/80",
}: UserAvatarProps) {
  const sz = SIZES[size];
  const avatarSeed = seed || name || "user";
  const gradient = GRADIENTS[hashName(avatarSeed) % GRADIENTS.length];
  const initials = getInitials(name || avatarSeed);
  const shapeClass = shape === "circle" ? "rounded-full" : "rounded-xl";

  const isRealSrc = src && !src.includes("dicebear.com");
  const [stage, setStage] = useState<"real" | "dicebear" | "fallback">(
    isRealSrc ? "real" : "dicebear"
  );

  const rootClass = cn(
    "relative shrink-0 overflow-hidden inline-flex items-center justify-center select-none",
    sz.root, shapeClass,
    ring && `ring-offset-1 ${sz.ring} ${ringColor}`,
    className
  );

  const isCustomReal = src && src.includes("/avatars/");
  if (stage === "real" && src && isRealSrc) {
    return (
      <div className={rootClass}>
        <img src={src} alt={name || "Avatar"} 
          className={cn("h-full w-full object-cover", isCustomReal && "scale-[0.88]")}
          onError={() => setStage("dicebear")} draggable={false} />
      </div>
    );
  }

  if (stage === "dicebear") {
    const avatarUrl = getCustomAvatar(name || avatarSeed);
    const isCustom = avatarUrl.includes("/avatars/");
    return (
      <div className={rootClass}>
        <img src={avatarUrl} alt={name || "Avatar"} 
          className={cn("h-full w-full object-cover", isCustom && "scale-[0.88]")}
          onError={() => setStage("fallback")} draggable={false} />
      </div>
    );
  }

  return (
    <div className={rootClass}
      style={{ background: `linear-gradient(135deg, ${gradient[0]}, ${gradient[1]})` }}
      aria-label={name || "Avatar"}>
      <span className={cn("font-bold text-white leading-none tracking-tight", sz.text)} aria-hidden="true">
        {initials}
      </span>
    </div>
  );
}

export default UserAvatar;
