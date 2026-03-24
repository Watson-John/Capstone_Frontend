import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../features/expense_tracker/domain/models/expense.dart';
import '../../features/expense_tracker/domain/models/budget.dart';
import '../../features/expense_tracker/domain/models/receipt_line_item.dart';
import '../../features/expense_tracker/domain/models/user_alias.dart';
import '../../features/todo_list/domain/models/todo_model.dart';
import '../../features/notifications_reminders/domain/models/in_app_notification.dart';
import '../../features/mood_logger/domain/models/mood_log.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lifelog.db');
    return openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        limit_amount REAL NOT NULL,
        period TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
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
      CREATE TABLE receipt_line_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_id INTEGER NOT NULL,
        receipt_acronym TEXT NOT NULL,
        decoded_name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        scan_order INTEGER NOT NULL,
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE user_aliases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_acronym TEXT NOT NULL UNIQUE,
        decoded_name TEXT NOT NULL,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await _seedUserAliases(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications(
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
        CREATE TABLE IF NOT EXISTS moodLog(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          mood TEXT NOT NULL,
          dateTime TEXT NOT NULL,
          emoji TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      try {
        await db.execute('''
          ALTER TABLE moodLog ADD COLUMN emoji TEXT DEFAULT '😎'
        ''');
      } catch (_) {
        // Column already exists — safe to ignore
      }
    }

    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
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

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          limit_amount REAL NOT NULL,
          period TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS receipt_line_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          expense_id INTEGER NOT NULL,
          receipt_acronym TEXT NOT NULL,
          decoded_name TEXT NOT NULL,
          category TEXT NOT NULL,
          price REAL NOT NULL,
          scan_order INTEGER NOT NULL,
          FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_aliases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          receipt_acronym TEXT NOT NULL UNIQUE,
          decoded_name TEXT NOT NULL,
          category TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await _seedUserAliases(db);
    }

    if (oldVersion < 8) {
      // Force-update seed aliases with corrected proper-case display names.
      await _reseedUserAliases(db);
    }
  }

  // --- Seed aliases --------------------------------------------------------

  static const _kSeedAliases = <(String, String, String)>[
    // (receipt_acronym, decoded_name, category)
    ('BETTER THAN BOUIL',  'Better Than Bouillon',        'GROCERY'),
    ('BY PREM APLWD BAC',  'Premium Applewood Bacon',     'GROCERY'),
    ('CARROTS 2LB',        'Carrots 2lb',                 'GROCERY'),
    ('CENTO TOMATO PAST',  'Cento Tomato Paste',          'GROCERY'),
    ('CHOICE BNLS CHUCK',  'Ground Chuck',                'GROCERY'),
    ('DORITOS DINAMITA',   'Doritos Dinamita',            'GROCERY'),
    ('FCL BAY LEAVES',     'Bay Leaves',                  'GROCERY'),
    ('FCL HZLNT CHOC SP',  'Hazelnut Chocolate Spread',   'GROCERY'),
    ('FCL POPCORN MICRO',  'Microwave Popcorn',           'GROCERY'),
    ('FRANKS RED HOT SA',  'Frank\'s Red Hot Sauce',      'GROCERY'),
    ('GOYA RED CKING WI',  'Goya Red Cooking Wine',       'GROCERY'),
    ('RED POTATO',         'Red Potato',                  'GROCERY'),
    ('VIDALIA ONIONS',     'Vidalia Onions',              'GROCERY'),
  ];

  Future<void> _seedUserAliases(Database db) async {
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final (acronym, name, category) in _kSeedAliases) {
      batch.insert(
        'user_aliases',
        {
          'receipt_acronym': acronym,
          'decoded_name': name,
          'category': category,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Re-apply seed aliases using REPLACE so stale entries are overwritten.
  Future<void> _reseedUserAliases(Database db) async {
    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final (acronym, name, category) in _kSeedAliases) {
      batch.insert(
        'user_aliases',
        {
          'receipt_acronym': acronym,
          'decoded_name': name,
          'category': category,
          'created_at': now,
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
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

  // --- Budget Operations ---

  Future<Budget?> getBudget() async {
    final db = await database;
    final maps = await db.query('budgets', limit: 1, orderBy: 'id DESC');
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  Future<int> saveBudget(Budget budget) async {
    final db = await database;
    // Only one active budget — replace any existing row.
    await db.delete('budgets');
    return db.insert('budgets', budget.toMap());
  }

  // --- Receipt Line Items Operations ---

  Future<int> insertLineItem(ReceiptLineItem item) async {
    final db = await database;
    return db.insert('receipt_line_items', item.toMap());
  }

  Future<void> insertLineItems(List<ReceiptLineItem> items) async {
    final db = await database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert('receipt_line_items', item.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<ReceiptLineItem>> getLineItemsForExpense(int expenseId) async {
    final db = await database;
    final maps = await db.query(
      'receipt_line_items',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
      orderBy: 'scan_order ASC',
    );
    return maps.map(ReceiptLineItem.fromMap).toList();
  }

  Future<int> updateLineItem(ReceiptLineItem item) async {
    final db = await database;
    return db.update(
      'receipt_line_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Update all line items in an expense that share the same receipt_acronym.
  Future<int> updateLineItemsByAcronym({
    required int expenseId,
    required String receiptAcronym,
    required String newDecodedName,
    required String newCategory,
  }) async {
    final db = await database;
    return db.update(
      'receipt_line_items',
      {
        'decoded_name': newDecodedName,
        'category': newCategory,
      },
      where: 'expense_id = ? AND receipt_acronym = ?',
      whereArgs: [expenseId, receiptAcronym],
    );
  }

  Future<List<ReceiptLineItem>> getLineItemsForExpenses(
      List<int> expenseIds) async {
    if (expenseIds.isEmpty) return [];
    final db = await database;
    final placeholders = List.filled(expenseIds.length, '?').join(',');
    final maps = await db.query(
      'receipt_line_items',
      where: 'expense_id IN ($placeholders)',
      whereArgs: expenseIds,
    );
    return maps.map(ReceiptLineItem.fromMap).toList();
  }

  Future<int> deleteLineItemsForExpense(int expenseId) async {
    final db = await database;
    return db.delete(
      'receipt_line_items',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
  }

  // --- User Alias Operations ---

  /// Insert or replace an alias (newest wins via UNIQUE on receipt_acronym).
  Future<int> upsertUserAlias(UserAlias alias) async {
    final db = await database;
    return db.insert(
      'user_aliases',
      alias.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserAlias?> getUserAlias(String normalizedAcronym) async {
    final db = await database;
    final maps = await db.query(
      'user_aliases',
      where: 'receipt_acronym = ?',
      whereArgs: [normalizedAcronym],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserAlias.fromMap(maps.first);
  }

  Future<List<UserAlias>> getAllUserAliases() async {
    final db = await database;
    final maps = await db.query('user_aliases', orderBy: 'updated_at DESC');
    return maps.map(UserAlias.fromMap).toList();
  }

  Future<int> deleteUserAlias(int id) async {
    final db = await database;
    return db.delete('user_aliases', where: 'id = ?', whereArgs: [id]);
  }
}
