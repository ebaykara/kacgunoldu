import type { DateKey } from './date';

/**
 * A tracked thing. `recs` holds the days it was done, newest first.
 * Nothing derived is ever stored — see `domain/logic.ts`.
 */
export type Card = {
  id: string;
  name: string;
  recs: DateKey[];
};

export type Tier = 'fresh' | 'calm' | 'soon' | 'late';

export type Tab = 'cards' | 'time';
