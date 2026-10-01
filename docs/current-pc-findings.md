# Temuan PC asal — 1 Oktober 2026

Dokumen ini sengaja tidak memuat email, serial number, token, dump database, atau crash dump mentah.

## Hardware dan sistem

- Windows 11 Pro 25H2, build 26200.9168.
- Intel Core i5-13400F, RAM 32 GB.
- Gigabyte H610M K V2, BIOS F4 bertanggal 27 September 2024.
- Drive sistem: Samsung SSD 870 EVO 1TB, firmware SVT03B6Q.
- GPU: AMD Radeon RX 580 2048SP, driver 31.0.12027.9001 bertanggal 30 Maret 2023.
- MuMuPlayer Virtual Display Adapter terpasang.

## Fakta yang terkonfirmasi dari log

- Banyak Event ID 41 dan shutdown tidak bersih.
- Bugcheck yang tercatat antara lain:
  - `0x154` — UNEXPECTED_STORE_EXCEPTION.
  - `0x7A` — KERNEL_DATA_INPAGE_ERROR.
  - `0xEF` — CRITICAL_PROCESS_DIED.
  - `0x1E` dengan parameter status I/O `0xC0000006`.
- NTFS mencatat torn write pada `$MFT` dan `$LogFile` volume C:.
- NTFS Event 55/98 meminta full offline CHKDSK.
- Volmgr Event 161 menunjukkan crash dump berulang kali gagal dibuat.
- Windows Error Reporting mencatat LiveKernelEvent 141.
- WHEA-Logger Event 17 mencatat corrected PCIe Root Port errors pada `PCI\VEN_8086&DEV_460D`.
- SFC kemudian melaporkan file korup dan berhasil memperbaikinya.
- Crash aplikasi terpisah terlihat pada Cloudflare WARP, Gigabyte RunUpd, Logitech G Hub, dan LDPlayer.

## Indikasi kuat, tetapi belum menjadi bukti tunggal

- Rangkaian `0x154`, `0x7A`, `0xC0000006`, torn write, dan dump failure sangat konsisten dengan masalah jalur storage/I/O. Kemungkinan mencakup filesystem rusak, SSD/firmware, kabel SATA, konektor daya, controller/driver, atau efek shutdown paksa.
- LiveKernelEvent 141 dan WHEA PCIe menunjukkan jalur GPU/PCIe juga perlu diperiksa: driver, pemasangan kartu, suhu, power supply, atau hardware GPU.
- Driver GPU yang sangat lama meningkatkan risiko incompatibility dengan Windows/game terbaru.

## Hipotesis dari troubleshooting Anti Gravity sebelumnya

Troubleshooting sebelumnya mengaitkan crash Steam/Ragnarok dengan MuMuPlayer Virtual Display Adapter, service MuMu, Sandboxie, dan anti-cheat. Ada event `WUDFRd` untuk virtual display di sekitar salah satu crash, tetapi korelasi waktu saja belum membuktikan deadlock atau akar tunggal.

Cara mengujinya secara lebih kuat:

1. Catat baseline Event Viewer dan waktu crash.
2. Nonaktifkan hanya virtual display/service MuMu dan Sandboxie secara sementara.
3. Uji game yang sama dengan beban dan durasi serupa.
4. Aktifkan kembali komponen satu per satu.
5. Bandingkan bugcheck, WHEA, LiveKernelEvent, dan dump baru.

Gunakan `Set-GameCompatibility.ps1` untuk uji A/B yang menyimpan state rollback.

## Perubahan yang pernah diterapkan

- DISM RestoreHealth dan SFC Scannow.
- CHKDSK offline dijadwalkan dan dilaporkan selesai tanpa bad sector.
- Service cFosSpeed/Gigabyte tertentu dinonaktifkan.
- Service database diubah menjadi Manual.
- Startup Docker, MuMuPlayer, Chrome AutoLaunch, dan Comet Updater dinonaktifkan/dihapus.
- Crash dump dikonfigurasi.
- TDR delay, AHCI/PCIe power setting, ULPS, MPO, Fast Startup, virtual display, dan Sandboxie pernah diubah oleh script lama. Karena sebagian bersifat mitigasi dan hardware-specific, repo baru tidak menerapkannya otomatis.

## Langkah lanjutan yang masih penting

- Verifikasi firmware SSD melalui Samsung Magician resmi dan cek kabel SATA serta konektor daya.
- Pasang driver AMD WHQL yang cocok dari situs resmi AMD dengan opsi Minimal atau Driver Only.
- Setelah sistem stabil, kembalikan tweak eksperimental satu per satu untuk mengetahui apakah masih diperlukan.
- Pastikan crash dump baru benar-benar berhasil dibuat sebelum analisis lanjutan.
