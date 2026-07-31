import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/models.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'prep_tracker.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE phases (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE topics (
        id TEXT PRIMARY KEY,
        phase_id TEXT NOT NULL,
        name TEXT NOT NULL,
        weight INTEGER NOT NULL,
        is_critical INTEGER NOT NULL,
        confidence INTEGER NOT NULL DEFAULT 3,
        last_reviewed_at TEXT,
        last_activity_at TEXT,
        FOREIGN KEY (phase_id) REFERENCES phases(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id TEXT NOT NULL,
        title TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'not_started',
        practice_target INTEGER NOT NULL DEFAULT 1,
        practice_done INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        next_review_at TEXT,
        completed_at TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (topic_id) REFERENCES topics(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE streak_days (
        date TEXT PRIMARY KEY,
        minutes INTEGER NOT NULL DEFAULT 15
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<bool> isSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('db_seeded') ?? false;
  }

  Future<void> markSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('db_seeded', true);
  }

  Future<void> seedFromAssets() async {
    if (await isSeeded()) return;

    final jsonStr = await rootBundle.loadString('assets/seed/checklist.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final phases = data['phases'] as List<dynamic>;
    final db = await database;

    await db.transaction((txn) async {
      for (final phaseData in phases) {
        final phaseMap = phaseData as Map<String, dynamic>;
        await txn.insert('phases', {
          'id': phaseMap['id'],
          'name': phaseMap['name'],
          'icon': phaseMap['icon'] ?? 'school',
          'sort_order': phaseMap['sortOrder'] ?? 0,
        });

        final topics = phaseMap['topics'] as List<dynamic>? ?? [];
        for (final topicData in topics) {
          final topicMap = topicData as Map<String, dynamic>;
          await txn.insert('topics', {
            'id': topicMap['id'],
            'phase_id': phaseMap['id'],
            'name': topicMap['name'],
            'weight': topicMap['weight'] ?? 5,
            'is_critical': (topicMap['isCritical'] as bool? ?? false) ? 1 : 0,
            'confidence': 3,
          });

          final items = topicMap['items'] as List<dynamic>? ?? [];
          for (var i = 0; i < items.length; i++) {
            final itemMap = items[i] as Map<String, dynamic>;
            await txn.insert('items', {
              'topic_id': topicMap['id'],
              'title': itemMap['title'],
              'status': 'not_started',
              'practice_target': itemMap['practiceTarget'] ?? 1,
              'practice_done': 0,
              'sort_order': i,
            });
          }
        }
      }
    });

    await markSeeded();
  }

  Future<List<Phase>> getPhases() async {
    final db = await database;
    final rows = await db.query('phases', orderBy: 'sort_order ASC');
    return rows.map((r) => Phase.fromMap(r)).toList();
  }

  Future<List<Topic>> getTopicsForPhase(String phaseId) async {
    final db = await database;
    final rows = await db.query(
      'topics',
      where: 'phase_id = ?',
      whereArgs: [phaseId],
      orderBy: 'is_critical DESC, weight DESC, name ASC',
    );
    return rows.map((r) => Topic.fromMap(r)).toList();
  }

  Future<Topic?> getTopic(String topicId) async {
    final db = await database;
    final rows = await db.query('topics', where: 'id = ?', whereArgs: [topicId]);
    if (rows.isEmpty) return null;
    return Topic.fromMap(rows.first);
  }

  Future<List<ChecklistItem>> getItemsForTopic(String topicId) async {
    final db = await database;
    final rows = await db.query(
      'items',
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'sort_order ASC',
    );
    return rows.map((r) => ChecklistItem.fromMap(r)).toList();
  }

  Future<List<ChecklistItem>> getAllItems() async {
    final db = await database;
    final rows = await db.query('items', orderBy: 'sort_order ASC');
    return rows.map((r) => ChecklistItem.fromMap(r)).toList();
  }

  Future<ChecklistItem?> getItem(int id) async {
    final db = await database;
    final rows = await db.query('items', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ChecklistItem.fromMap(rows.first);
  }

  Future<void> updateItem(ChecklistItem item) async {
    final db = await database;
    await db.update('items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
    await db.update(
      'topics',
      {'last_activity_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [item.topicId],
    );
  }

  Future<void> updateTopic(Topic topic) async {
    final db = await database;
    await db.update('topics', topic.toMap(), where: 'id = ?', whereArgs: [topic.id]);
  }

  Future<List<Topic>> getAllTopics() async {
    final db = await database;
    final rows = await db.query('topics');
    return rows.map((r) => Topic.fromMap(r)).toList();
  }

  Future<void> recordStreakDay() async {
    final db = await database;
    final today = _dateKey(DateTime.now());
    await db.insert(
      'streak_days',
      {'date': today, 'minutes': 15},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<StreakInfo> getStreakInfo() async {
    final db = await database;
    final rows = await db.query('streak_days', orderBy: 'date DESC');
    final dates = rows.map((r) => r['date'] as String).toSet();
    final today = _dateKey(DateTime.now());

    var current = 0;
    var cursor = DateTime.now();
    while (dates.contains(_dateKey(cursor))) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var longest = 0;
    var run = 0;
    final sorted = dates.toList()..sort();
    for (var i = 0; i < sorted.length; i++) {
      if (i == 0) {
        run = 1;
      } else {
        final prev = DateTime.parse(sorted[i - 1]);
        final curr = DateTime.parse(sorted[i]);
        if (curr.difference(prev).inDays == 1) {
          run++;
        } else {
          run = 1;
        }
      }
      if (run > longest) longest = run;
    }

    return StreakInfo(
      currentStreak: current,
      longestStreak: longest,
      activeDates: dates,
      practicedToday: dates.contains(today),
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
