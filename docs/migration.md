# Migrasi ke komputer baru

Jangan menerapkan profile lama secara buta. Nama service, driver, device, dan penyebab crash dapat berbeda.

## 1. Siapkan sistem

1. Selesaikan Windows Update dan restart.
2. Pasang driver chipset, GPU, jaringan, dan audio dari vendor resmi.
3. Pasang Git dan PowerShell 7 bila diperlukan.
4. Clone repository ini.

## 2. Audit sebelum optimasi

```powershell
.\scripts\Audit-Windows.ps1 -Days 30
```

Simpan hasil lokal, tetapi jangan commit laporan tanpa memeriksa data pribadi.

## 3. Sesuaikan profile

Salin `profiles/gaming-dev.psd1`, lalu ubah daftar service, startup, dan scheduled task sesuai aplikasi yang benar-benar terpasang. Script melewati item yang tidak ditemukan, tetapi profile tetap harus ditinjau.

## 4. Preview dan backup

```powershell
.\scripts\Apply-Profile.ps1 -Profile .\profiles\gaming-dev.psd1
.\scripts\Apply-Profile.ps1 -Profile .\profiles\gaming-dev.psd1 -Apply -CreateRestorePoint
```

State rollback disimpan pada `state/` dan sengaja tidak masuk Git karena spesifik untuk setiap PC.

## 5. Jangan migrasikan tweak hardware-specific secara otomatis

TDR delay, ULPS, MPO, PCIe Link State Power Management, AHCI LPM, BIOS, firmware, dan penonaktifan device hanya layak diterapkan setelah gejala serta hardware baru diperiksa.

## 6. Uji stabilitas bertahap

- Uji coding workload.
- Uji game tanpa overlay/emulator lebih dulu.
- Tambahkan kembali overlay, emulator, Sandboxie, VPN, dan utility peripheral satu per satu.
- Periksa Event Viewer setelah setiap tahap.
