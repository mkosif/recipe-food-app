// Extracts a single timer hint from a recipe step.
// Matches localized and English duration units.
// Returns the largest detected duration in seconds along with a display label.
// We deliberately pick the largest match so interval reminders do not override a longer cooking time.

export interface StepTimerHint {
  durationSec: number;
  label: string;
}

interface TimeUnit {
  pattern: RegExp;
  factor: number;
}

const UNITS: TimeUnit[] = [
  // Hours
  { pattern: /(\d+(?:[\.,]\d+)?)\s*(saat|sa\b|hour(?:s)?|hr(?:s)?|h\b)/gi, factor: 3600 },
  // Minutes
  { pattern: /(\d+(?:[\.,]\d+)?)\s*(dakika|dk\b|minute(?:s)?|min\b|mins\b|m\b)/gi, factor: 60 },
  // Seconds
  { pattern: /(\d+(?:[\.,]\d+)?)\s*(saniye|sn\b|second(?:s)?|sec\b|secs\b|s\b)/gi, factor: 1 }
];

export function extractTimerHint(step: string): StepTimerHint | null {
  let bestSec = 0;
  let bestLabel = '';

  for (const unit of UNITS) {
    // Reset lastIndex defensively — the regex is shared across calls.
    unit.pattern.lastIndex = 0;
    let match: RegExpExecArray | null = unit.pattern.exec(step);
    while (match !== null) {
      const raw = match[1].replace(',', '.');
      const value = parseFloat(raw);
      if (!isNaN(value) && value > 0) {
        const sec = Math.round(value * unit.factor);
        if (sec > bestSec) {
          bestSec = sec;
          bestLabel = `${match[0]}`.trim();
        }
      }
      match = unit.pattern.exec(step);
    }
  }

  if (bestSec <= 0) {
    return null;
  }
  // Cap at 4 hours — anything longer is probably a misread (e.g. oven temp like "180 dk").
  if (bestSec > 4 * 3600) {
    return null;
  }
  return { durationSec: bestSec, label: bestLabel };
}
