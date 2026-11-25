# Ry-Money

Buku kas pribadi dalam satu halaman. Tanpa akun, tanpa server — data tinggal di HP kamu.

**Buka:** `https://riseky8876.github.io/Ry-Money/`

## Isi

- **Ringkas** — sisa uang bulan ini dalam satu angka besar, plus rincian gaji, penyisihan, tabungan, dan belanja.
- **Gaji** — catat gaji masuk; rutinitas aktif (kos, bensin, listrik) otomatis dipotong. Bisa dimatikan per pencatatan.
- **Tabungan** — daftar wishlist dengan harga target dan ritme nabung bebas (per hari / minggu / bulan). Perkiraan waktu dan sisa target dihitung otomatis.
- **Catatan** — pengeluaran dan pemasukan lain, dikelompokkan per hari, dengan rekap per kategori.

## Cara pakai

1. Buka tab **Gaji**, isi nominal gaji. Kalau rutinitas sudah ada, penyisihannya langsung terpotong.
2. Tambah rutinitas: nama, nominal sekali bayar, siklus. Hitungan per bulan: harian ×30, mingguan ×4,3, bulanan ×1.
3. Buat target di **Tabungan**, lalu tekan **Setor** tiap kali menabung.
4. Catat pengeluaran harian di **Catatan**.

Di HP: buka di Chrome → menu → **Tambahkan ke layar utama**. Aplikasi bisa dibuka offline setelah sekali dibuka.

## Data & privasi

Semua data disimpan di `localStorage` browser, tidak dikirim ke mana pun. Karena itu:

- Ganti HP atau bersihkan data browser = data hilang, kecuali kamu mengunduh cadangan.
- Unduh cadangan lewat tombol ⚙ di kanan atas → **Unduh cadangan (JSON)**.
- Pulihkan dengan **Pulihkan dari cadangan**.

## Teknis

Statis murni: HTML + CSS + ES module, tanpa build step dan tanpa dependensi. Deploy otomatis ke GitHub Pages lewat `.github/workflows/pages.yml` setiap push ke `main`.

Struktur:

```
index.html
assets/css/style.css
assets/js/store.js    # state, localStorage, hitungan
assets/js/format.js   # rupiah, tanggal
assets/js/app.js      # tampilan & interaksi
sw.js                 # cache offline
```

Menjalankan lokal:

```bash
python3 -m http.server 8080
# buka http://127.0.0.1:8080
```
