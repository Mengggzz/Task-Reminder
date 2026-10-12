import 'package:sqflite/sqflite.dart';
import '../core/services/database_service.dart';
import '../models/task_model.dart';

class TaskRepository {
  final DatabaseService _dbService;

  TaskRepository({DatabaseService? dbService})
      : _dbService = dbService ?? DatabaseService.instance;

  Future<int> insert(Task task) async {
    final db = await _dbService.database;
    return await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> update(Task task) async {
    final db = await _dbService.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await _dbService.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'waktu_pengingat ASC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<List<Task>> getPendingTasks() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'selesai = 0',
      orderBy: 'waktu_pengingat ASC',
    );
    return maps.map((m) => Task.fromMap(m)).toList();
  }
}
