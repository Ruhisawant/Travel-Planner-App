import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

import 'main.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('plans.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE plans(
      _id INTEGER PRIMARY KEY,
      name TEXT,
      description TEXT,
      priority TEXT,
      date TEXT,
      isCompleted INTEGER
    )
    ''');
  }

  Future<int> insertPlan(Plan plan) async {
    final db = await instance.database;
    return await db.insert('plans', plan.toMap());
  }

  Future<List<Plan>> getPlans() async {
    final db = await instance.database;
    final maps = await db.query('plans');
    return List.generate(maps.length, (i) {
      return Plan.fromMap(maps[i]);
    });
  }

  Future<int> updatePlan(Plan plan) async {
    final db = await instance.database;
    return await db.update(
      'plans',
      plan.toMap(),
      where: '_id = ?',
      whereArgs: [plan.id],
    );
  }

  Future<int> deletePlan(int id) async {
    final db = await instance.database;
    return await db.delete(
      'plans',
      where: '_id = ?',
      whereArgs: [id],
    );
  }
}