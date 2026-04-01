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
}