import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'meals.db');

//TO DELETE LOCAL DB FOR DEVELOPMENT
//     if (await databaseExists(path)) {
//   await deleteDatabase(path);
//   print('Old database deleted');
// }
    return openDatabase(
      path,
      onCreate: (db, version) async {
        // Meal analysis with images
        await db.execute('''
          CREATE TABLE meal_analysis (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imagePath TEXT,
            result TEXT,
            createdAt TEXT
          )
        ''');

        // Nutritional plans (no images)
        await db.execute('''
          CREATE TABLE nutrition_plan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            result TEXT,
            createdAt TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  // Insert meal analysis (with image)
  Future<void> insertMealAnalysis(String imagePath, Map<String, dynamic> result) async {
    final db = await database;
    await db.insert(
      'meal_analysis',
      {
        'imagePath': imagePath,
        'result': jsonEncode(result),
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert nutritional plan (no image)
  Future<void> insertNutritionPlan(Map<String, dynamic> result) async {
    final db = await database;
    await db.insert(
      'nutrition_plan',
      {
        'result': jsonEncode(result),
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fetch meal analyses
Future<List<Map<String, dynamic>>> getMealAnalyses() async {
  final db = await database;
  final meals = await db.query(
    'meal_analysis',
    orderBy: 'createdAt DESC',
  );

  return meals.map((meal) {
    final decoded = jsonDecode(meal['result'] as String);

    final plan = decoded['plan'] ?? [];
    final totals = decoded['totals'] ?? {
      'calories': 0,
      'protein': 0,
      'carbs': 0,
      'fat': 0,
    };

    print("🔥 DB Row: ${meal['createdAt']} -> $totals");

    return {
      'id': meal['id'],
      'imagePath': meal['imagePath'],
      'plan': plan,
      'totals': totals,
      'result': decoded,
      'createdAt': meal['createdAt'],
    };
  }).toList();
}


  // Fetch nutritional plans
  Future<List<Map<String, dynamic>>> getNutritionPlans() async {
    final db = await database;
    final plans = await db.query(
      'nutrition_plan',
      orderBy: 'createdAt DESC',
    );

    return plans.map((plan) {
      final decoded = jsonDecode(plan['result'] as String);
      return {
        'id': plan['id'],
        'result': decoded,
        'createdAt': plan['createdAt'],
      };
    }).toList();
  }

  // Delete a meal by ID
Future<void> deleteMeal(int id) async {
  final db = await database;
  await db.delete(
    'meal_analysis',
    where: 'id = ?',
    whereArgs: [id],
  );
}

}
