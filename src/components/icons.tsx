import React from 'react';
import Svg, { Circle, Path, Rect } from 'react-native-svg';

/**
 * The two tab glyphs and the FAB `+`, redrawn from the mock.
 * They stand in for `square.grid.2x2` / `list.bullet.indent` (SF Symbols) and
 * `grid_view` / `timeline` (Material Symbols) — swap in the system icon set if
 * the target platform ships one.
 */

type IconProps = { color: string; active?: boolean; size?: number };

export function GridIcon({ color, active = false, size = 22 }: IconProps) {
  const fill = active ? color : 'none';
  return (
    <Svg width={size} height={size} viewBox="0 0 22 22" fill="none">
      <Rect x={3} y={3} width={7} height={7} rx={2.2} stroke={color} strokeWidth={1.7} fill={fill} />
      <Rect x={12} y={3} width={7} height={7} rx={2.2} stroke={color} strokeWidth={1.7} fill="none" />
      <Rect x={3} y={12} width={7} height={7} rx={2.2} stroke={color} strokeWidth={1.7} fill="none" />
      <Rect x={12} y={12} width={7} height={7} rx={2.2} stroke={color} strokeWidth={1.7} fill={fill} />
    </Svg>
  );
}

export function TimelineIcon({ color, active = false, size = 22 }: IconProps) {
  const fill = active ? color : 'none';
  return (
    <Svg width={size} height={size} viewBox="0 0 22 22" fill="none">
      <Path d="M5.5 3.5v15" stroke={color} strokeWidth={1.7} strokeLinecap="round" />
      <Circle cx={5.5} cy={7.5} r={2.4} fill={fill} stroke={color} strokeWidth={1.7} />
      <Circle cx={5.5} cy={15} r={2.4} fill="none" stroke={color} strokeWidth={1.7} />
      <Path d="M11 7.5h7M11 15h5" stroke={color} strokeWidth={1.7} strokeLinecap="round" />
    </Svg>
  );
}

export function TrashIcon({ color, size = 17 }: { color: string; size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 17 17" fill="none">
      <Path d="M3 4.6h11M6.4 4.6V3.2a1 1 0 0 1 1-1h2.2a1 1 0 0 1 1 1v1.4" stroke={color} strokeWidth={1.4} strokeLinecap="round" strokeLinejoin="round" />
      <Path d="M4.2 4.6l.6 9.2a1.4 1.4 0 0 0 1.4 1.3h5.6a1.4 1.4 0 0 0 1.4-1.3l.6-9.2" stroke={color} strokeWidth={1.4} strokeLinecap="round" strokeLinejoin="round" />
      <Path d="M7 7.5v4.4M10 7.5v4.4" stroke={color} strokeWidth={1.4} strokeLinecap="round" />
    </Svg>
  );
}

export function PlusIcon({ color, size = 17 }: { color: string; size?: number }) {
  return (
    <Svg width={size} height={size} viewBox="0 0 17 17" fill="none">
      <Path d="M8.5 1.6v13.8M1.6 8.5h13.8" stroke={color} strokeWidth={2.1} strokeLinecap="round" />
    </Svg>
  );
}
