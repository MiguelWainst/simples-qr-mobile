import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/catalog.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final instance = DatabaseHelper._();
  Future<Database>? _database;
  Future<Database> get database => _database ??= _open();
  Future<Database> _open() async => openDatabase(
    '${await getDatabasesPath()}/simples_qr.db',
    version: 2,
    onCreate: (db, version) async {
      await db.execute(
        'CREATE TABLE cache (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE favorites (id TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS favorites (id TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
      }
    },
  );
}

/// SQLite on Android; persistent preferences on the browser.
class CatalogCache {
  CatalogCache(this.preferences, {bool? useSqlite})
    : useSqlite =
          useSqlite ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
  final SharedPreferences preferences;
  final bool useSqlite;
  Future<String?> read(String key) async {
    if (!useSqlite) {
      return preferences.getString('catalog.$key');
    }
    final rows = await (await DatabaseHelper.instance.database).query(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> write(String key, String value) async {
    if (!useSqlite) {
      await preferences.setString('catalog.$key', value);
      return;
    }
    await (await DatabaseHelper.instance.database).insert('cache', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remove(String key) async {
    if (!useSqlite) {
      await preferences.remove('catalog.$key');
      return;
    }
    await (await DatabaseHelper.instance.database).delete(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<List<Product>> favorites() async {
    if (!useSqlite) {
      return (jsonDecode(preferences.getString('favorites') ?? '[]') as List)
          .map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    final rows = await (await DatabaseHelper.instance.database).query(
      'favorites',
    );
    return rows.map((e) => Product.fromJson(e['value'] as String)).toList();
  }

  Future<void> saveFavorite(Product product) async {
    if (!useSqlite) {
      final list = await favorites();
      list.removeWhere((e) => e.id == product.id);
      list.add(product);
      await preferences.setString(
        'favorites',
        jsonEncode(list.map((e) => e.toMap()).toList()),
      );
      return;
    }
    await (await DatabaseHelper.instance.database).insert('favorites', {
      'id': product.id,
      'value': product.toJson(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteFavorite(String id) async {
    if (!useSqlite) {
      final list = await favorites();
      list.removeWhere((e) => e.id == id);
      await preferences.setString(
        'favorites',
        jsonEncode(list.map((e) => e.toMap()).toList()),
      );
      return;
    }
    await (await DatabaseHelper.instance.database).delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
