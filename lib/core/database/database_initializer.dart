import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

class DatabaseInitializer {
  static Future<void> initDatabase() async {
    // Ensure the database is initialized only once
    try {
      // Get database path and initialize
      await DatabaseHelper.instance.database;
      debugPrint('SQLite Database initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SQLite database: $e');
      rethrow;
    }
  }

  static Future<void> deleteDatabaseFile() async {
    try {
      final String path = join(await getDatabasesPath(), DatabaseHelper.dbName);
      await deleteDatabase(path);
      debugPrint('Database file deleted successfully');
    } catch (e) {
      debugPrint('Error deleting database file: $e');
      rethrow;
    }
  }

  static Future<void> resetDatabase() async {
    await deleteDatabaseFile();
    await initDatabase();
  }
}
