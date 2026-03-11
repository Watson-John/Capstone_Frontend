import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/todo_list/domain/models/todo_model.dart';
import '../../features/notifications_reminders/domain/models/in_app_notification.dart';
import '../../features/mood_logger/domain/models/mood_log.dart';
import '../../features/expense_tracker/domain/models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'lifelog.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task TEXT NOT NULL,
        startDate TEXT NOT NULL,
        dueDate TEXT NOT NULL,
        status TEXT NOT NULL,
        imagePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE moodLog(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        mood TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        emoji TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        vendor TEXT NOT NULL,
        category TEXT NOT NULL,
        veryfi_document_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE notifications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          isRead INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE moodLog(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          mood TEXT NOT NULL,
          dateTime TEXT NOT NULL,
          emoji TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE moodLog ADD COLUMN emoji TEXT DEFAULT '😎'
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          vendor TEXT NOT NULL,
          category TEXT NOT NULL,
          veryfi_document_id TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  // --- Todos Operations ---

  Future<int> insertTodo(Todo todo) async {
    final db = await database;
    return await db.insert(
      'todos',
      todo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Todo>> getTodos() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('todos');

    return List.generate(maps.length, (i) {
      return Todo.fromMap(maps[i]);
    });
  }

  Future<int> updateTodo(Todo todo) async {
    final db = await database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> deleteTodo(int id) async {
    final db = await database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Notifications Operations ---

  Future<int> insertNotification(InAppNotification notification) async {
    final db = await database;
    return await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<InAppNotification>> getNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notifications',
        orderBy: 'timestamp DESC' // Newest first
        );

    return List.generate(maps.length, (i) {
      return InAppNotification.fromMap(maps[i]);
    });
  }

  Future<void> markAllAsRead() async {
    final db = await database;
    await db.update(
      'notifications',
      {'isRead': 1},
      where: 'isRead = ?',
      whereArgs: [0],
    );
  }

  Future<int> getUnreadCount() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db
        .rawQuery('SELECT COUNT(*) FROM notifications WHERE isRead = 0'));
    return count ?? 0;
  }

  // --- Mood Logs Operations ---

  Future<int> insertMoodLog(MoodLog moodLog) async {
    final db = await database;
    return await db.insert(
      'moodLog',
      moodLog.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MoodLog>> getMoodLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'moodLog',
      orderBy: 'dateTime DESC', // Newest first
    );

    return List.generate(maps.length, (i) {
      return MoodLog.fromMap(maps[i]);
    });
  }

  Future<List<String>> getUniqueMoodTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db
        .rawQuery('SELECT DISTINCT mood FROM moodLog ORDER BY mood ASC');

    return maps.map((entry) => entry['mood'] as String).toList();
  }

  Future<int> updateMoodLog(MoodLog moodLog) async {
    final db = await database;
    return await db.update(
      'moodLog',
      moodLog.toMap(),
      where: 'id = ?',
      whereArgs: [moodLog.id],
    );
  }

  Future<int> deleteMoodLog(int id) async {
    final db = await database;
    return await db.delete(
      'moodLog',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Expense Operations ---

  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'created_at DESC');
    return maps.map(Expense.fromMap).toList();
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }
}
