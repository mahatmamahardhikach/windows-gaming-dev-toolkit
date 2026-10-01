# Windows Gaming + Development Toolkit

Toolkit PowerShell yang dapat diaudit dan di-rollback untuk PC Windows yang dipakai terutama untuk coding dan gaming.

Repo ini dibuat dari investigasi crash nyata pada Windows 11: bugcheck storage/I/O, korupsi NTFS, timeout GPU, error PCIe, serta beban service dan startup pihak ketiga. Script tidak menganggap semua PC memiliki penyebab yang sama. Jalankan audit lebih dulu, baca hasilnya, lalu terapkan hanya perubahan yang relevan.

## Prinsip keselamatan

- Tidak menonaktifkan Microsoft Defender, Windows Update, firewall, atau fitur keamanan inti.
- Tidak menghapus aplikasi Windows secara massal.
- Tidak menjalankan script internet dengan pola `irm | iex`.
- Semua optimasi profile membuat backup state lokal sebelum mengubah service, startup, atau scheduled task.
- Tweak GPU dan virtual display bersifat opsional dan terpisah dari perbaikan utama.
- Repair disk, update BIOS/firmware, dan driver GPU tetap membutuhkan penilaian hardware masing-masing PC.

## Mulai cepat

1. Clone repo.
2. Buka PowerShell atau Windows Terminal sebagai Administrator.
3. Jalankan:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\Start-Toolkit.ps1
```

Atau jalankan audit langsung tanpa mengubah sistem:

```powershell
.\scripts\Audit-Windows.ps1
```

Hasil audit masuk ke folder `reports/` dan tidak dilacak Git karena dapat memuat nama perangkat atau path lokal.

## Workflow yang direkomendasikan

```text
Audit read-only
    -> backup data penting
    -> perbaiki filesystem/image Windows jika terbukti rusak
    -> update driver/firmware dari vendor resmi
    -> uji stabilitas
    -> apply profile gaming+dev
    -> uji lagi
```

Untuk komputer baru, baca [panduan migrasi](docs/migration.md). Temuan mesin asal ada di [current-pc-findings.md](docs/current-pc-findings.md), dengan pemisahan antara fakta log dan hipotesis.

## Perintah penting

```powershell
# Audit 30 hari terakhir
.\scripts\Audit-Windows.ps1 -Days 30

# Repair image Windows dan file sistem
.\scripts\Repair-Windows.ps1 -RestoreHealth -SystemFileCheck

# Scan volume tanpa repair offline
.\scripts\Repair-Windows.ps1 -DiskAction Scan -DriveLetter C

# Jadwalkan CHKDSK /F saat boot berikutnya (meminta konfirmasi)
.\scripts\Repair-Windows.ps1 -DiskAction ScheduleFix -DriveLetter C

# Preview profile tanpa perubahan
.\scripts\Apply-Profile.ps1 -Profile .\profiles\gaming-dev.psd1

# Terapkan profile dan simpan rollback state
.\scripts\Apply-Profile.ps1 -Profile .\profiles\gaming-dev.psd1 -Apply -CreateRestorePoint

# Mode gaming/coding untuk database dev
.\scripts\Set-WorkMode.ps1 -Mode Gaming
.\scripts\Set-WorkMode.ps1 -Mode Coding

# Rollback profile terakhir
.\scripts\Restore-Profile.ps1 -Latest -Apply
```

## Tentang debloat tool populer

Lihat [debloat-review.md](docs/debloat-review.md). Repo ini memilih pendekatan targeted dan reversible. Preset agresif tidak digunakan sebagai default karena pengurangan jumlah proses belum tentu menaikkan FPS, sementara penghapusan komponen dapat merusak Store, Game Pass, anti-cheat, WSL, Docker, compiler, atau update driver.

## Lisensi

MIT. Gunakan dengan risiko sendiri dan selalu siapkan backup.
