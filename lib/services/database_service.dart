import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/tag.dart';

class DatabaseService {
  static Database? _database;
  static const String _tableName = 'tasks';
  static const String _tagsTableName = 'tags';
  static const String _taskTagsTableName = 'task_tags';

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        dueDate INTEGER,
        priority INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE $_tagsTableName(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        color TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_taskTagsTableName(
        taskId TEXT NOT NULL,
        tagId TEXT NOT NULL,
        PRIMARY KEY (taskId, tagId),
        FOREIGN KEY (taskId) REFERENCES $_tableName (id) ON DELETE CASCADE,
        FOREIGN KEY (tagId) REFERENCES $_tagsTableName (id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $_tagsTableName(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL UNIQUE,
          color TEXT,
          createdAt INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE $_taskTagsTableName(
          taskId TEXT NOT NULL,
          tagId TEXT NOT NULL,
          PRIMARY KEY (taskId, tagId),
          FOREIGN KEY (taskId) REFERENCES $_tableName (id) ON DELETE CASCADE,
          FOREIGN KEY (tagId) REFERENCES $_tagsTableName (id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 3) {
      // Remove category column - first migrate data to tags if needed
      try {
        // Get all tasks with categories
        final result = await db.rawQuery('SELECT id, category FROM $_tableName WHERE category IS NOT NULL');

        for (final row in result) {
          final taskId = row['id'] as String;
          final categoryName = row['category'] as String;

          // Create/get tag for this category
          var tagResult = await db.query(_tagsTableName, where: 'name = ?', whereArgs: [categoryName]);
          String tagId;

          if (tagResult.isEmpty) {
            // Create new tag
            tagId = DateTime.now().millisecondsSinceEpoch.toString();
            await db.insert(_tagsTableName, {
              'id': tagId,
              'name': categoryName,
              'createdAt': DateTime.now().millisecondsSinceEpoch,
            });
          } else {
            tagId = tagResult.first['id'] as String;
          }

          // Link task to tag
          await db.insert(_taskTagsTableName, {
            'taskId': taskId,
            'tagId': tagId,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      } catch (e) {
        // If migration fails, just continue - we'll lose categories but app will work
        print('Category migration failed: $e');
      }

      // Drop the category column
      await db.execute('ALTER TABLE $_tableName DROP COLUMN category');
    }
  }

  // CRUD Operations for Tasks
  static Future<void> insertTask(Task task) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        _tableName,
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final tag in task.tags) {
        await txn.insert(
          _taskTagsTableName,
          {'taskId': task.id, 'tagId': tag.id},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'createdAt DESC',
    );

    List<Task> tasks = [];
    for (final map in maps) {
      final tags = await _getTaskTags(db, map['id']);
      tasks.add(Task.fromMap(map, tags: tags));
    }

    return tasks;
  }

  static Future<List<Tag>> _getTaskTags(Database db, String taskId) async {
    final List<Map<String, dynamic>> tagMaps = await db.rawQuery('''
      SELECT t.* FROM $_tagsTableName t
      INNER JOIN $_taskTagsTableName tt ON t.id = tt.tagId
      WHERE tt.taskId = ?
    ''', [taskId]);

    return tagMaps.map((map) => Tag.fromMap(map)).toList();
  }

  static Future<Task?> getTaskById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    final tags = await _getTaskTags(db, id);
    return Task.fromMap(maps.first, tags: tags);
  }

  static Future<void> updateTask(Task task) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        _tableName,
        task.toMap(),
        where: 'id = ?',
        whereArgs: [task.id],
      );

      // Remove old tag associations
      await txn.delete(
        _taskTagsTableName,
        where: 'taskId = ?',
        whereArgs: [task.id],
      );

      // Add new tag associations
      for (final tag in task.tags) {
        await txn.insert(
          _taskTagsTableName,
          {'taskId': task.id, 'tagId': tag.id},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  static Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  static Future<List<Task>> getTasksByPriority(TaskPriority priority) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'priority = ?',
      whereArgs: [priority.index],
      orderBy: 'createdAt DESC',
    );

    List<Task> tasks = [];
    for (final map in maps) {
      final tags = await _getTaskTags(db, map['id']);
      tasks.add(Task.fromMap(map, tags: tags));
    }
    return tasks;
  }

  // CRUD Operations for Tags
  static Future<void> insertTag(Tag tag) async {
    final db = await database;
    await db.insert(
      _tagsTableName,
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Tag>> getAllTags() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tagsTableName,
      orderBy: 'name ASC',
    );

    return maps.map((map) => Tag.fromMap(map)).toList();
  }

  static Future<Tag?> getTagByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tagsTableName,
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isEmpty) return null;
    return Tag.fromMap(maps.first);
  }

  static Future<void> updateTag(Tag tag) async {
    final db = await database;
    await db.update(
      _tagsTableName,
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  static Future<void> deleteTag(String id) async {
    final db = await database;
    await db.delete(
      _tagsTableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Task>> getTasksByTag(String tagId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT t.* FROM $_tableName t
      INNER JOIN $_taskTagsTableName tt ON t.id = tt.taskId
      WHERE tt.tagId = ?
      ORDER BY t.createdAt DESC
    ''', [tagId]);

    List<Task> tasks = [];
    for (final map in maps) {
      final tags = await _getTaskTags(db, map['id']);
      tasks.add(Task.fromMap(map, tags: tags));
    }
    return tasks;
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
