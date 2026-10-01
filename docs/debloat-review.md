# Review pendekatan debloat

Ditinjau pada 1 Oktober 2026.

## Chris Titus Tech WinUtil

- Repository: <https://github.com/ChrisTitusTech/winutil>
- Populer, aktif, memiliki preset dan mekanisme undo untuk banyak tweak.
- Cocok untuk inspeksi dan perubahan terpilih.
- Rekomendasi: gunakan stable branch dan pilih tweak satu per satu; jangan langsung memakai Advanced preset pada workstation coding/gaming.

## Raphire Win11Debloat

- Repository: <https://github.com/Raphire/Win11Debloat>
- Fokus pada app removal, privacy, suggested content, dan UI.
- Memiliki export/import konfigurasi dan undo untuk banyak perubahan.
- Rekomendasi: gunakan custom mode; pertahankan Store/Xbox/Game Bar bila dibutuhkan game atau Game Pass.

## Sophia Script

- Repository: <https://github.com/farag2/Sophia-Script-for-Windows>
- Sangat granular dan kuat, tetapi membutuhkan review konfigurasi yang lebih teliti.
- Rekomendasi: cocok untuk power user yang membaca setiap fungsi sebelum eksekusi.

## AtlasOS dan playbook agresif

- Perubahan lebih dalam dapat mengurangi kompatibilitas, recovery, update, keamanan, anti-cheat, atau tooling developer.
- Tidak direkomendasikan sebagai langkah pertama untuk mesin kerja utama.

## Keputusan repo ini

Toolkit ini memakai perubahan targeted berdasarkan inventory aktual. Tujuannya bukan mengejar jumlah proses terendah, tetapi mengurangi beban yang nyata sambil menjaga update, keamanan, Steam, anti-cheat, Docker, WSL, database, dan compiler tetap dapat dipakai.
