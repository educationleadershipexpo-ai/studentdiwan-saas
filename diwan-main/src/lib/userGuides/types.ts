export interface UserGuide {
  id: string;
  role: string;
  title: string;
  tagline: string;
  audience: string;
  icon: string;
  gradient: string;
  accentHex: string;
  badgeBg: string;
  badgeText: string;
  estimatedMinutes: number;
  version: string;
  lastUpdated: string;
  chapters: Chapter[];
}

export interface Chapter {
  id: string;
  number: number;
  title: string;
  icon: string;
  summary: string;
  blocks: Block[];
}

export type Block =
  | TextBlock
  | StepsBlock
  | ScreenshotBlock
  | CalloutBlock
  | TableBlock
  | FaqBlock;

export interface TextBlock {
  type: 'text';
  markdown: string;
}

export interface StepsBlock {
  type: 'steps';
  title?: string;
  steps: Step[];
}

export interface Step {
  title: string;
  description: string;
  tip?: string;
}

export interface ScreenshotBlock {
  type: 'screenshot';
  src: string;
  caption: string;
  alt: string;
  annotations: ScreenshotAnnotation[];
}

export interface ScreenshotAnnotation {
  id: number;
  x: number;
  y: number;
  label: string;
  description: string;
}

export interface CalloutBlock {
  type: 'callout';
  variant: 'tip' | 'warning' | 'info' | 'success' | 'danger';
  title: string;
  body: string;
}

export interface TableBlock {
  type: 'table';
  caption?: string;
  headers: string[];
  rows: string[][];
}

export interface FaqBlock {
  type: 'faq';
  questions: { q: string; a: string }[];
}
