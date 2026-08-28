# Hijri Calendar (jp.hijri)

Widget bar Omarchy yang menampilkan tanggal Hijriyah hari ini, dan membuka
kalender satu bulan Hijriyah saat diklik. Tampilan popup meniru plugin
bawaan `omarchy.clock`: hero tanggal besar, grid 6×7 dengan hari ini
di-outline, dan navigasi bulan via chevron / panah keyboard / scroll wheel.

## Fitur
- Di bar: `15 Rab. Awal 1448 H` (hari ini, diperbarui otomatis tiap menit /
  saat tengah malam).
- Klik widget: popup kalender grid 6×7 untuk bulan Hijriyah yang sedang
  ditampilkan, dengan hari ini diberi garis tepi.
- Hero tanggal besar (klik untuk kembali ke bulan ini), navigasi ⟨ ⟩, panah
  kiri/kanan, `[` `]` bulan, `{` `}` tahun, `t` hari ini, scroll wheel,
  `Esc` menutup.
- Minggu dimulai Senin.

## Catatan kalender
Konversi menggunakan kalender Islam tabular (algoritma aritmetis Reingold &
Dershowitz, "Calendrical Calculations") — deterministik dan tanpa dependensi
eksternal. Ini dapat berbeda **maksimal 1 hari** dari kalender berbasis
rukyat hilal / Umm al-Qura.

## Instal
```sh
omarchy plugin add https://github.com/pakucon/omarchy-hijri.git --enable
```

## Pindah / nonaktifkan
```sh
omarchy bar move jp.hijri --section right        # atau left / center
omarchy plugin disable jp.hijri
omarchy plugin remove jp.hijri
```

## Files
- `manifest.json` — kontrak plugin
- `BarWidget.qml` — label bar + host popup
- `Panel.qml` — grid kalender
- `Hijri.js` — konversi Gregorian ↔ Hijriyah
