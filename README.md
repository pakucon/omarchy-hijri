# Hijri Calendar (jp.hijri)

An Omarchy bar widget that shows today's Hijri date and opens a one-month
Hijri calendar when clicked. The popup mimics the built-in `omarchy.clock`
plugin: a large date hero, a 6×7 grid with today outlined, and month
navigation via chevrons / arrow keys / scroll wheel.

## Features
- In the bar: `15 Rab. Awal 1448 H` (today's date, refreshed automatically
  every minute / at midnight).
- Click the widget: a 6×7 grid calendar for the displayed Hijri month, with
  today outlined.
- Large date hero (click to return to the current month), ⟨ ⟩ chevrons,
  left/right arrows, `[` `]` for month, `{` `}` for year, `t` for today,
  scroll wheel, and `Esc` to close.
- Week starts on Monday.
- Settings (gear button below the month selector): choose the interface
  language (**Indonesia** / **English** / **Arabic**) and adjust the date by
  ±days (clamped to −3..+3) to match your local moon-sighting. Settings are
  persisted across restarts.

## Calendar note
The conversion uses the tabular Islamic calendar (the arithmetical algorithm
from Reingold & Dershowitz, "Calendrical Calculations") — deterministic and
with no external dependencies. It can differ by **at most 1 day** from
hilal-observation based calendars such as Umm al-Qura.

## Install
```sh
omarchy plugin add https://github.com/pakucon/omarchy-hijri.git --enable
```

## Move / disable
```sh
omarchy bar move jp.hijri --section right        # or left / center
omarchy plugin disable jp.hijri
omarchy plugin remove jp.hijri
```

## Files
- `manifest.json` — plugin contract
- `BarWidget.qml` — bar label + popup host
- `Panel.qml` — calendar grid + settings
- `Hijri.js` — Gregorian ↔ Hijri conversion
