import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/report.dart';

// bu sınıfın amacı db yi fiziksel olarak cihazda oluşturmak ve sql komutlarını çalıştırmak
class DatabaseHelper {
  // singleton pattern: uygulama boyunca sadece tek bir veritabanı bağlantısı olmasını sağlar
  DatabaseHelper._internal(); //private. kodun başka bir yerinde yazılıp nesne oluşturulamaz.
  // sadece 1 tane(statik ve değişmez) örnek yaratıldı. bütün uyg. bu tek örneği kullanır.
  static final DatabaseHelper instance = DatabaseHelper._internal();
  // açılan db bağlantısını hafızada tutacağım değişken. uygulamanın ilk saniyesinde null olabilir
  static Database? _database;

  // dışarıdan veritabanına erişmek isteyenlerin çağıracağı metot
  Future<Database> get database async {
    //uyg. çalışırken db zaten 1 kere açılmışsa, var olan bağlantıyı geri ver.
    // ! : bunun boş olmadığına eminim demek
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sikayet_uygulamasi.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // db.execute: db ye sql komutu gönderir. bu sadece db ilk oluşturulduğunda tek bir kez çalışır
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reports (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        status TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        imagePaths TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> insertReport(Report report) async {
    final db = await instance.database;
    await db.insert(
      'reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm
          .replace, // eklediğin şikayetin id si zaten db de varsa, hata vermiyor eskisini silip bu yenisini üzerine yazar
    );
  }

  Future<List<Map<String, dynamic>>> getAllReports() async {
    final db = await instance.database;
    return await db.query('reports', orderBy: 'createdAt DESC');
  }

  Future<void> updateStatus(String id, String newStatus) async {
    final db = await instance.database;
    await db.update(
      'reports',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteReport(String id) async {
    final db = await instance.database;
    await db.delete('reports', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getReportCount() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM reports');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
