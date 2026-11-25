# Ry-Money

Buku kas pribadi. Dua bentuk, data yang sama-sama lokal:

- **APK Android** (disarankan) — ikon sendiri di layar utama, tanpa browser, tanpa izin internet.
- **Web** — <https://riseky8876.github.io/Ry-Money/>

## Pasang APK

Unduh: **<https://github.com/riseky8876/Ry-Money/releases/latest/download/Ry-Money.apk>**

1. Buka tautan di HP, unduh `Ry-Money.apk`.
2. Ketuk berkasnya → izinkan **instal dari sumber tidak dikenal** untuk aplikasi yang membuka berkas (Chrome/Files).
3. Selesai. Ikon Ry-Money muncul di laci aplikasi.

Memperbarui: unduh APK terbaru dan pasang di atas yang lama — data tidak hilang, karena APK ditandatangani dengan kunci yang sama.

APK dibangun otomatis oleh GitHub Actions (`.github/workflows/android.yml`) setiap ada perubahan pada `android/`, `assets/`, atau `index.html`.

## Isi

- **Ringkas** — sisa uang bulan ini dalam satu angka besar, plus rincian gaji, penyisihan, tabungan, dan belanja.
- **Gaji** — catat gaji masuk; rutinitas aktif (kos, bensin, listrik) otomatis dipotong. Bisa dimatikan per pencatatan.
- **Tabungan** — wishlist dengan harga target dan ritme nabung bebas (per hari / minggu / bulan). Sisa target dan perkiraan waktu dihitung otomatis.
- **Catatan** — pengeluaran dan pemasukan lain, dikelompokkan per hari, dengan rekap per kategori.

## Cara pakai

1. Tab **Gaji** → isi nominal gaji. Rutinitas yang aktif langsung terpotong.
2. Tambah rutinitas: nama, nominal sekali bayar, siklus. Hitungan per bulan: harian ×30, mingguan ×4,3, bulanan ×1.
3. Buat target di **Tabungan**, tekan **Setor** tiap kali menabung.
4. Catat pengeluaran harian di **Catatan**.

## Data & privasi

Semua data disimpan di penyimpanan lokal aplikasi. APK tidak meminta izin internet sama sekali — tidak ada data yang bisa keluar dari HP.

Cadangan: tombol ⚙ → **Unduh cadangan (JSON)**. Di APK, berkasnya masuk ke `Download/Ry-Money/`. Pulihkan lewat **Pulihkan dari cadangan**.

Ganti HP atau hapus data aplikasi = data hilang, kecuali sudah dicadangkan.

## Teknis

Web: HTML + CSS + ES module, tanpa build step dan tanpa dependensi. Font ikut dibundel (tidak memanggil Google Fonts).

Android: WebView lokal dengan `WebViewAssetLoader`, Java murni, satu dependensi (`androidx.webkit`). Aset web disalin otomatis ke `assets/www` saat build, jadi kode web hanya ada satu sumber.

```
index.html
assets/css/style.css
assets/js/store.js    # state, localStorage, hitungan
assets/js/format.js   # rupiah, tanggal
assets/js/app.js      # tampilan & interaksi
assets/fonts/*.woff2  # Fraunces, Karla, JetBrains Mono
sw.js                 # cache offline untuk versi web
android/              # pembungkus APK
```

Menjalankan web secara lokal:

```bash
python3 -m http.server 8080
# buka http://127.0.0.1:8080
```

Membangun APK secara lokal butuh JDK 17 + Android SDK:

```bash
gradle -p android assembleRelease
```

### Penandatanganan

APK ditandatangani dengan kunci rilis yang tersimpan sebagai secret repo (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`). Salinan lokal ada di `android/keystore.p12` dan `android/KEYSTORE.txt` — keduanya di-`.gitignore`.

Kalau kunci ini hilang, APK berikutnya tidak bisa dipasang menimpa versi lama (harus uninstal dulu). Simpan `android/KEYSTORE.txt` di tempat aman.

Verifikasi APK yang sudah dibangun:

```bash
apksigner verify --print-certs Ry-Money.apk
```
