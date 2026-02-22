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

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
  // 1. tabel bahan_baku
  await db.execute('''
    CREATE TABLE bahan_baku (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      jumlah INTEGER,
      kualitas TEXT
    )
  ''');

  // 2. tabel user
  await db.execute('''
    CREATE TABLE user (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT,
      password TEXT
    )
  ''');

  await db.insert('user', {
    'username': 'admin',
    'password': 'admin123',
  });

  await db.execute('''
    CREATE TABLE produksi (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tgl_produksi TEXT,
    jumlah_hasil INTEGER,
    status TEXT
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
  Future<bool> login(String username, String password) async {
    final db = await instance.database;

    final result = await db.query(
      'user',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    return result.isNotEmpty;
  }
}
