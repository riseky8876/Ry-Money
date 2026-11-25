# Ry-Money

Buku kas pribadi dalam bentuk aplikasi Android asli (Flutter). Ikon sendiri di layar utama, tanpa browser, tanpa akun, tanpa server, dan tanpa izin internet.

**Unduh APK:** <https://github.com/riseky8876/Ry-Money/releases/latest/download/Ry-Money.apk>

## Pasang

1. Buka tautan di atas dari HP, unduh `Ry-Money.apk`.
2. Ketuk berkasnya → izinkan **instal dari sumber tidak dikenal** untuk aplikasi yang membukanya (Chrome/Files).
3. Selesai. Ikon Ry-Money muncul di laci aplikasi.

Memperbarui: unduh APK terbaru dan pasang di atas yang lama. Data tidak hilang selama APK ditandatangani dengan kunci yang sama.

## Isi

- **Ringkas** — sisa uang bulan ini dalam satu angka besar, lengkap dengan garis pemisah penyisihan, tabungan, belanja, dan sisa.
- **Gaji** — catat gaji masuk. Penyisihan rutin dan tabungan bisa dipotong otomatis, masing-masing dengan sakelar sendiri.
- **Tabungan** — wishlist dengan harga target dan ritme nabung bebas. Setiap target bisa ikut dipotong dari gaji atau tidak.
- **Catatan** — pengeluaran dan pemasukan lain, dikelompokkan per hari, dengan rekap per kategori.

## Yang baru

### Potongan gaji fleksibel

Saat mencatat gaji ada dua sakelar terpisah:

- **Potong penyisihan** — memotong semua rutinitas yang aktif (kos, bensin, listrik, …).
- **Sisihkan tabungan** — menyisihkan rencana bulanan dari target yang punya sakelar **Potong dari gaji** aktif.

Di bawah sakelar ada pratinjau langsung: gaji, tiap potongan, dan sisanya. Semua bisa dimatikan tanpa menghapus datanya. Setiap rutinitas juga punya sakelar aktif sendiri, dan setiap target punya sakelar potong-otomatis sendiri.

### Siklus & ritme custom

Rutinitas dan target tabungan sama-sama punya empat pilihan: **Harian**, **Mingguan**, **Bulanan**, dan **Custom**. Custom menerima angka bebas — tiap 2 hari, 10 hari, 15 hari, berapa pun.

Hitungan per bulan memakai satu bulan = 30,4 hari:

```
bulanan  → nominal × 1
mingguan → nominal × 4,3
harian   → nominal × 30,4
custom   → nominal × 30,4 ÷ N hari
```

## Cara pakai

1. Tab **Gaji** → isi nominal gaji. Pratinjau menunjukkan potongan yang akan diambil.
2. Tambah rutinitas: nama, nominal sekali bayar, siklus. Sakelar di kanan mengaktifkan/mematikan potongannya.
3. Buat target di **Tabungan**, atur ritme dan sakelar **Potong dari gaji**. Tekan **Setor** untuk setoran manual.
4. Catat pengeluaran harian di **Catatan**.
5. Pindah bulan lewat tanda `<` `>` di atas; ketuk nama bulan untuk kembali ke bulan ini.

## Data & privasi

Semua data disimpan di penyimpanan lokal aplikasi (`shared_preferences`). APK tidak meminta izin internet sama sekali.

Cadangan: tombol pengaturan di kanan atas → **Salin cadangan (JSON)** atau **Lihat cadangan**. Untuk memulihkan: **Pulihkan dari cadangan** → tempel teks JSON → **Pulihkan**.

Ganti HP atau hapus data aplikasi = data hilang, kecuali sudah dicadangkan.

### Pindah dari versi web lama

Data versi web tersimpan di localStorage browser dan tidak bisa dibaca aplikasi. Kalau masih ada isinya:

1. Buka versi web lama → ⚙ → **Unduh cadangan**.
2. Di aplikasi → pengaturan → **Pulihkan dari cadangan** → tempel isi berkas JSON.
3. Cadangan versi lama (`hari`/`minggu`/`bulan`) otomatis dibaca sebagai `harian`/`mingguan`/`bulanan`, dan potongan tabungan otomatis dimulai dalam keadaan mati.

## Teknis

Flutter (Dart), satu dependensi runtime: `shared_preferences`. Format angka dan tanggal ditulis sendiri, tanpa `intl`. Font dibundel sebagai TTF statis (Fraunces, Karla, JetBrains Mono) supaya tampilan sama tanpa internet.

```
lib/
  main.dart            # aplikasi, bilah atas, navigasi bawah
  theme.dart           # warna & tipografi
  format.dart          # rupiah, tanggal, formatter input
  models.dart          # model data + semua hitungan
  store.dart           # simpan/muat lokal & cadangan
  widgets.dart         # komponen bersama
  sheets.dart          # lembar isian
  screens/             # ringkas, gaji, tabungan, catatan
test/                  # tes hitungan & widget
tool/patch_android.py  # membuat & menambal proyek Android di CI
assets/fonts/          # TTF statis
```

Proyek `android/` tidak di-commit; dibuat ulang oleh `tool/patch_android.py` setiap build supaya selalu mengikuti template Flutter terbaru.

### Build

Butuh Flutter stable + JDK 17 + Android SDK.

```bash
flutter pub get
flutter analyze
flutter test

export RY_KEYSTORE="$PWD/keys/keystore.p12"
export RY_STOREPASS="$(grep '^password' keys/KEYSTORE.txt | cut -d' ' -f2)"
export RY_KEYALIAS=rymoney
export RY_KEYPASS="$RY_STOREPASS"

python3 tool/patch_android.py
flutter build apk --release
```

Di GitHub Actions (`.github/workflows/android.yml`) semua langkah itu berjalan otomatis setiap push ke `main`; APK diunggah ke rilis `apk-latest`.

### Penandatanganan

APK ditandatangani kunci rilis yang tersimpan sebagai secret repo: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`. Salinan lokal ada di `keys/keystore.p12` dan `keys/KEYSTORE.txt` (keduanya di-`.gitignore`).

Kalau kunci ini hilang, APK berikutnya tidak bisa dipasang menimpa versi lama. Simpan `keys/KEYSTORE.txt` di tempat aman.
