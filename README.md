# 🥚 SaltIT - Sistem Informasi Manajemen Stok Telur Asin

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

**SaltIT** adalah aplikasi *mobile* berbasis Android yang dirancang untuk mendigitalisasi dan mengotomatisasi seluruh alur operasional bisnis telur asin. Mulai dari penerimaan bahan baku, proses produksi, alokasi stok, hingga pencatatan kasir dan pelaporan *executive*.

## 📖 Project Overview
Dalam bisnis produksi telur asin skala menengah, pencatatan stok yang dilakukan secara manual (menggunakan kertas/buku) sering kali memicu berbagai masalah operasional:
* Terjadinya selisih data antara bahan baku mentah yang masuk dengan produk jadi.
* Kesulitan melacak sisa stok secara *real-time* untuk toko *offline* dan *online*.
* Tidak adanya batas akses data, sehingga rawan terjadi manipulasi catatan.

**SaltIT** hadir sebagai solusi sistem terintegrasi (End-to-End). Dengan mengimplementasikan **Role-Based Access Control (RBAC)**, aplikasi ini memastikan setiap pegawai (Manajer, Produsen, Kasir, Admin) hanya dapat mengakses modul dan memanipulasi data sesuai dengan wewenang/tugas masing-masing.

## ✨ Key Features
* 🔐 **Role-Based Access Control (RBAC):** Login multi-pengguna dengan 5 peran berbeda (Manajer Inventory, Produsen, Staf Offline, Admin Online, Owner).
* 📦 **Manajemen Bahan Baku & QC:** Pencatatan telur mentah yang lolos atau gagal *Quality Control*.
* 🏭 **Tracking Produksi:** Mengonversi data bahan baku menjadi produk jadi secara dinamis (tanpa *redundancy* data).
* 🔀 **Alokasi Stok Cerdas:** Pembagian kuota produk jadi untuk kebutuhan toko *offline* dan pesanan e-commerce (*online*).
* 🛒 **Point of Sales (POS) Offline:** Sistem kasir sederhana dengan validasi ketersediaan stok etalase.
* 🌐 **Manajemen Pesanan Online:** Tarik data pesanan (*mockup*) dan *update* status pengiriman barang.
* 📊 **Executive Dashboard:** Ringkasan performa produksi, omzet penjualan, dan simulasi *export* laporan PDF untuk *Owner*.

## 🛠️ Tech Stack

| Kategori | Teknologi | Deskripsi |
| :--- | :--- | :--- |
| **Frontend Framework** | Flutter | Cross-platform UI toolkit |
| **Programming Language**| Dart | Core language for logic and state |
| **Database** | SQLite (sqflite) | Embedded local database for offline persistence |
| **Architecture** | MVC Pattern | Pemisahan antara UI, logika bisnis, dan query DB |

## 🚀 How to Run

1. **Clone Repository**
   ```bash
   git clone [https://github.com/username-kamu/SaltIT.git](https://github.com/username-kamu/SaltIT.git)
   cd SaltIT
