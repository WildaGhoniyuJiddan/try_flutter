import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  // Inisialisasi pemanggilan Firestore
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // LOGIN & PENGECEKAN ROLE
  // Cari jabatan (role) berdasarkan email saat login
  static Future<String?> getUserRoleByEmail(String email) async {
    final snapshot = await _db.collection('users')
                              .where('email', isEqualTo: email)
                              .limit(1)
                              .get();
    
    // Kalau emailnya ketemu di buku daftar karyawan, kembalikan jabatannya
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data()['role'] as String?;
    }
    
    // Kalau tidak ada di daftar
    return null; 
  }

  // BAHAN BAKU & QC
  // 1. Simpan hasil QC (Bagus/Jelek)
  static Future<void> insertBahanBaku(int jumlah, String status) async {
    await _db.collection('bahan_baku').add({
      'jumlah': jumlah,
      'status': status, // 'Lolos QC' atau 'Gagal QC'
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 2. Hitung total telur yang Lolos QC (Bagus)
  static Future<int> getTotalBahanBakuLolosQC() async {
    final snapshot = await _db.collection('bahan_baku')
                              .where('status', isEqualTo: 'Lolos QC')
                              .get();
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['jumlah'] as int? ?? 0);
    }
    return total;
  }

  // 3. Hitung total telur yang Gagal QC (Jelek)
  static Future<int> getTotalBahanBakuGagalQC() async {
    final snapshot = await _db.collection('bahan_baku')
                              .where('status', isEqualTo: 'Gagal QC')
                              .get();
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['jumlah'] as int? ?? 0);
    }
    return total;
  }

  // 4. Hitung TOTAL SELURUH telur mentah yang dibeli dari Supplier (Modul 7)
  static Future<int> getTotalBeliDariSupplier() async {
    final snapshot = await _db.collection('supplier').get();
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['jumlah_telur'] as int? ?? 0);
    }
    return total;
  }

  // PRODUKSI TELUR ASIN
  // 1. Simpan data produksi baru
  static Future<void> insertProduksi(int jumlah, String statusDB) async {
    await _db.collection('produksi').add({
      'jumlah': jumlah,
      'status': statusDB, // isinya: 'Berhasil' atau 'Gagal'
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("Data Produksi berhasil masuk ke Firestore!");
  }

  // 2. Hitung Total Produksi Berdasarkan Status
  static Future<int> getTotalProduksiByStatus(String status) async {
    final snapshot = await _db.collection('produksi')
                              .where('status', isEqualTo: status)
                              .get();
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['jumlah'] as int? ?? 0);
    }
    return total;
  }

  // ALOKASI STOK TOKO
  // 1. Simpan data pembagian stok (Alokasi)
  static Future<void> insertAlokasi(String tujuan, int jumlah) async {
    await _db.collection('alokasi').add({
      'tujuan': tujuan, // isinya: 'Toko Offline' atau 'Toko Online'
      'jumlah': jumlah,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("Data Alokasi berhasil masuk ke Firestore!");
  }

  // 2. Hitung total semua telur yang SUDAH dibagikan (ke semua toko)
  static Future<int> getTotalSemuaAlokasi() async {
    final snapshot = await _db.collection('alokasi').get();
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['jumlah'] as int? ?? 0);
    }
    return total;
  }

  // 3. Hitung total telur di masing-masing toko spesifik
  static Future<int> getTotalAlokasiByTujuan(String tujuan) async {
    final snapshot = await _db.collection('alokasi')
                              .where('tujuan', isEqualTo: tujuan)
                              .get();
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['jumlah'] as int? ?? 0);
    }
    return total;
  }

  // TRANSAKSI TOKO OFFLINE
  // 1. Simpan data transaksi penjualan kasir
  static Future<void> insertTransaksiOffline(int jumlah, int totalHarga) async {
    await _db.collection('transaksi_offline').add({
      'jumlah': jumlah,
      'total_harga': totalHarga,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("Transaksi Offline berhasil masuk ke Firestore!");
  }

  // 2. Hitung total telur yang sudah laku terjual di Toko Offline
  static Future<int> getTotalTerjualOffline() async {
    final snapshot = await _db.collection('transaksi_offline').get();
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['jumlah'] as int? ?? 0);
    }
    return total;
  }

  // TRANSAKSI TOKO ONLINE
  // 1. Simpan pesanan baru (Simulasi tarik data dari Marketplace)
  static Future<void> insertPesananOnline(String namaPembeli, int jumlahBeli) async {
    await _db.collection('pesanan_online').add({
      'nama_pembeli': namaPembeli,
      'jumlah_beli': jumlahBeli,
      'status': 'PENDING',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("Pesanan Marketplace masuk ke Firestore!");
  }

  // 2. Hitung total telur yang SUDAH DIKIRIM (Status: SHIPPED)
  static Future<int> getTotalTerjualOnline() async {
    final snapshot = await _db.collection('pesanan_online')
                              .where('status', isEqualTo: 'SHIPPED')
                              .get();
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['jumlah_beli'] as int? ?? 0);
    }
    return total;
  }

  // 3. Update status pesanan menjadi SHIPPED (Barang dikirim)
  static Future<void> updateStatusPesananOnline(String docId) async {
    await _db.collection('pesanan_online').doc(docId).update({
      'status': 'SHIPPED',
    });
  }

  // 4. Ambil daftar pesanan secara REAL-TIME untuk layar HP
  static Stream<QuerySnapshot> streamPesananOnline() {
    return _db.collection('pesanan_online')
              .orderBy('timestamp', descending: true)
              .snapshots();
  }

  // KELOLA DATA KARYAWAN (OWNER)
  // 1. Ambil daftar karyawan secara Real-time
  static Stream<QuerySnapshot> streamUsers() {
    return _db.collection('users').snapshots();
  }

  // 2. Tambah data karyawan baru
  static Future<void> insertUser(Map<String, dynamic> data) async {
    await _db.collection('users').add(data);
  }

  // 3. Update data karyawan
  static Future<void> updateUser(String docId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(docId).update(data);
  }

  // 4. Hapus data karyawan
  static Future<void> deleteUser(String docId) async {
    await _db.collection('users').doc(docId).delete();
  }

  // PENGADAAN BAHAN BAKU (SUPPLIER)
  // 1. Simpan data pembelian dari supplier
  static Future<void> insertSupplier(String namaPeternak, int jumlah, int harga, int totalBayar) async {
    await _db.collection('supplier').add({
      'nama_peternak': namaPeternak,
      'jumlah_telur': jumlah,
      'harga_per_butir': harga,
      'total_bayar': totalBayar,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("Data Supplier berhasil masuk ke Firestore!");
  }

  // 2. Ambil riwayat pengadaan secara Real-time
  static Stream<QuerySnapshot> streamSuppliers() {
    return _db.collection('supplier')
              .orderBy('timestamp', descending: true)
              .snapshots();
  }

  // LAPORAN KEUANGAN (OWNER)

  // 1. Hitung total uang masuk dari Kasir Offline
  static Future<int> getTotalPendapatanOffline() async {
    final snapshot = await _db.collection('transaksi_offline').get();
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['total_harga'] as int? ?? 0);
    }
    return total;
  }

  // 2. Hitung total uang keluar dari Pembelian Supplier
  static Future<int> getTotalPengeluaran() async {
    final snapshot = await _db.collection('supplier').get();
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['total_bayar'] as int? ?? 0);
    }
    return total;
  }
}