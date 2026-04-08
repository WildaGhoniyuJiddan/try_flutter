import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('telur_asin.db');
    return _database!;
  }

  // membuat database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1, // Catatan: Jika kamu sudah pernah run app-nya di emulator sebelumnya, hapus/uninstall dulu app-nya dari emulator agar tabel baru ini ter-create ulang.
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // tabel bahan_baku
    await db.execute('''
      CREATE TABLE bahan_baku (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jumlah INTEGER,
        kualitas TEXT
      )
    ''');

    // tabel user (UPDATE: username -> email, tambah kolom nama & role)
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT,
        email TEXT,
        password TEXT,
        role TEXT
      )
    ''');

    // Memasukkan (seeding) data user awal untuk berbagai Role agar mudah dites
    await db.insert('user', {
      'nama': 'Budi Manajer',
      'email': 'manajer@admin.com',
      'password': 'inventory123',
      'role': 'Manajer Inventory'
    });
    await db.insert('user', {
      'nama': 'Siti Produsen',
      'email': 'produsen@admin.com',
      'password': 'produsen123',
      'role': 'Produsen'
    });
    await db.insert('user', {
      'nama': 'Bos Telur',
      'email': 'owner@admin.com',
      'password': 'owner123',
      'role': 'Owner'
    });
    await db.insert('user', {
      'nama': 'Kasir Depan',
      'email': 'kasir@admin.com',
      'password': 'kasir123',
      'role': 'Staf Offline'
    });

    // tabel produksi
    await db.execute('''
      CREATE TABLE produksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tgl_produksi TEXT,
        jumlah_hasil INTEGER,
        status TEXT
      )
    ''');

    // tabel alokasi stok
    await db.execute('''
      CREATE TABLE alokasi_stok (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tujuan TEXT,
        jumlah INTEGER,
        tgl_alokasi TEXT
      )
    ''');

    // tabel transaksi offline (Sprint 5)
    await db.execute('''
      CREATE TABLE transaksi_offline (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tgl_transaksi TEXT,
        jumlah_beli INTEGER,
        total_harga INTEGER
      )
    ''');

    // tabel transaksi online (Sprint 6)
    await db.execute('''
      CREATE TABLE transaksi_online (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_pembeli TEXT,
        jumlah_beli INTEGER,
        status TEXT,
        tgl_pesanan TEXT
      )
    ''');

    // tabel supplier modul baru
    await db.execute('''
      CREATE TABLE supplier (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_peternak TEXT,
        jumlah_telur INTEGER,
        harga_per_butir INTEGER,
        total_bayar INTEGER,
        tgl_beli TEXT
      )
    ''');
  }

  Future<int> insertBahanBaku(int jumlah, String kualitas) async {
    final db = await instance.database;

    int result = await db.insert('bahan_baku', {
      'jumlah': jumlah,
      'kualitas': kualitas,
    });

    print("Data Masuk: $jumlah - $kualitas");
    return result;
  }

  Future<List<Map<String, dynamic>>> getBahanBaku() async {
    final db = await instance.database;
    return await db.query('bahan_baku');
  }

  // UPDATE: Fungsi login sekarang menggunakan email dan mereturn 'role' (String)
  Future<String?> login(String email, String password) async {
    final db = await instance.database;

    final result = await db.query(
      'user',
      columns: ['role'], // Kita hanya butuh mengambil role-nya saja
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    // Jika data ditemukan, kembalikan nilai role (misal: 'Manajer Inventory')
    if (result.isNotEmpty) {
      return result.first['role'] as String;
    }
    
    // Jika email/password salah, kembalikan null
    return null;
  }

  // 1. Fungsi insert produksi 
  Future<int> insertProduksi(int jumlah, String tgl, String status) async {
    final db = await instance.database;
    return await db.insert('produksi', {
      'jumlah_hasil': jumlah,
      'tgl_produksi': tgl,
      'status': status // 'Berhasil' atau 'Gagal'
    });
  }

  // 2. Hitung berhasil
  Future<int> getTotalProduksiBerhasil() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COALESCE(SUM(jumlah_hasil), 0) as total FROM produksi WHERE status = 'Berhasil'");
    return result.first['total'] as int;
  }

  // 3. Hitung gagal
  Future<int> getTotalProduksiGagal() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COALESCE(SUM(jumlah_hasil), 0) as total FROM produksi WHERE status = 'Gagal'");
    return result.first['total'] as int;
  }

  // 4. Berapa yang siap pakai
  Future<int> getTotalBahanBakuLolosQC() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT SUM(jumlah) as total FROM bahan_baku WHERE kualitas = 'Lolos QC (Bagus)'");
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }
  
  //SPRINT 3
  // 1. CREATE: Tambah user baru
  Future<int> insertUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('user', row);
  }

  // 2. READ: Ambil semua data user
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await instance.database;
    return await db.query('user');
  }

  // 3. UPDATE: Edit data user
  Future<int> updateUser(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('user', row, where: 'id = ?', whereArgs: [id]);
  }

  // 4. DELETE: Hapus user
  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete('user', where: 'id = ?', whereArgs: [id]);
  }
    
    //SPRINT 4
    // 1. Tambah data alokasi
  Future<int> insertAlokasi(String tujuan, int jumlah, String tgl) async {
    final db = await instance.database;
    return await db.insert('alokasi_stok', {
      'tujuan': tujuan,
      'jumlah': jumlah,
      'tgl_alokasi': tgl
    });
  }

  // 2. Hitung total semua telur yang sudah dialokasikan
  Future<int> getTotalSemuaAlokasi() async {
    final db = await instance.database;
    // Menggunakan COALESCE agar NULL otomatis menjadi 0
    final result = await db.rawQuery("SELECT COALESCE(SUM(jumlah), 0) as total FROM alokasi_stok");
    return result.first['total'] as int;
  }

  // 3. Hitung total alokasi spesifik (Offline atau Online)
  Future<int> getTotalAlokasiByTujuan(String tujuan) async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COALESCE(SUM(jumlah), 0) as total FROM alokasi_stok WHERE tujuan = ?", [tujuan]);
    return result.first['total'] as int;
  }

  //SPRINT 5
  // 1. Simpan data penjualan toko offline
  Future<int> insertTransaksiOffline(int jumlah, int totalHarga, String tgl) async {
    final db = await instance.database;
    return await db.insert('transaksi_offline', {
      'jumlah_beli': jumlah,
      'total_harga': totalHarga,
      'tgl_transaksi': tgl
    });
  }

  // 2. Hitung total telur yang sudah terjual di toko offline
  Future<int> getTotalTerjualOffline() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COALESCE(SUM(jumlah_beli), 0) as total FROM transaksi_offline");
    return result.first['total'] as int;
  }

  //SPRINT 6
  // 1. Simulasikan Tarik Data Pesanan Baru dari Marketplace (PBI-032)
  Future<int> insertPesananOnline(String nama, int jumlah, String tgl) async {
    final db = await instance.database;
    return await db.insert('transaksi_online', {
      'nama_pembeli': nama,
      'jumlah_beli': jumlah,
      'status': 'PENDING', // Pesanan baru masuk berstatus PENDING
      'tgl_pesanan': tgl
    });
  }

  // 2. Ambil semua daftar pesanan online
  Future<List<Map<String, dynamic>>> getPesananOnline() async {
    final db = await instance.database;
    // Tampilkan dari yang terbaru (Descending)
    return await db.query('transaksi_online', orderBy: 'id DESC'); 
  }

  // 3. Update status menjadi SHIPPED (PBI-033)
  Future<int> updateStatusPesananOnline(int id) async {
    final db = await instance.database;
    return await db.update(
      'transaksi_online',
      {'status': 'SHIPPED'},
      where: 'id = ?',
      whereArgs: [id]
    );
  }

  // 4. Hitung stok online yang SUDAH DIKIRIM (SHIPPED) untuk mengurangi kuota (PBI-033)
  Future<int> getTotalTerjualOnline() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COALESCE(SUM(jumlah_beli), 0) as total FROM transaksi_online WHERE status = 'SHIPPED'");
    return result.first['total'] as int;
  }

  //SPRINT 7
  // Hitung total pendapatan uang dari toko offline
  Future<int> getTotalPendapatanOffline() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COALESCE(SUM(total_harga), 0) as total FROM transaksi_offline");
    return result.first['total'] as int;
  }

  // --- FUNGSI MANAJEMEN SUPPLIER ---

  // Simpan transaksi pembelian dari peternak
  Future<int> insertSupplier(String nama, int jumlah, int harga, int total, String tgl) async {
    final db = await instance.database;
    return await db.insert('supplier', {
      'nama_peternak': nama,
      'jumlah_telur': jumlah,
      'harga_per_butir': harga,
      'total_bayar': total,
      'tgl_beli': tgl
    });
  }

  // Ambil semua riwayat pembelian
  Future<List<Map<String, dynamic>>> getSuppliers() async {
    final db = await instance.database;
    return await db.query('supplier', orderBy: 'id DESC');
  }

  // Hitung total semua telur yang pernah dibeli dari supplier
  Future<int> getTotalPembelian() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COALESCE(SUM(jumlah_telur), 0) as total FROM supplier");
    return result.first['total'] as int;
  }

  // Hitung TOTAL PENGELUARAN (Modal) untuk Dashboard Owner
  Future<int> getTotalPengeluaran() async {
    final db = await instance.database;
    final result = await db.rawQuery("SELECT COALESCE(SUM(total_bayar), 0) as total FROM supplier");
    return result.first['total'] as int;
  }

  //Maintenance masing masing user
  // Fungsi untuk mengubah password berdasarkan email
  Future<int> updatePassword(String email, String passwordBaru) async {
    final db = await instance.database;
    return await db.update(
      'user',
      {'password': passwordBaru},
      where: 'email = ?',
      whereArgs: [email],
    );
  }
}