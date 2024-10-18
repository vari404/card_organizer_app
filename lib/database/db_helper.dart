// lib/database/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/folder.dart';
import '../../models/card_model.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._();
  static Database? _database;

  DBHelper._();

  factory DBHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDB('card_organizer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        imageUrl TEXT NOT NULL,
        folderId INTEGER,
        FOREIGN KEY (folderId) REFERENCES folders (id)
      )
    ''');

    await _prepopulateData(db);
  }

  Future<void> _prepopulateData(Database db) async {
    // Insert the four suits into folders
    List<String> suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    for (var suit in suits) {
      await db.insert('folders', {
        'name': suit,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    // Insert cards 1-13 for each suit
    for (var suit in suits) {
      for (int i = 1; i <= 13; i++) {
        String cardName = _getCardName(i, suit);
        String imageUrl = _getImageUrl(i, suit);
        await db.insert('cards', {
          'name': cardName,
          'suit': suit,
          'imageUrl': imageUrl,
          'folderId': null, // Not assigned yet
        });
      }
    }
  }

  String _getCardName(int number, String suit) {
    switch (number) {
      case 1:
        return 'Ace of $suit';
      case 11:
        return 'Jack of $suit';
      case 12:
        return 'Queen of $suit';
      case 13:
        return 'King of $suit';
      default:
        return '$number of $suit';
    }
  }

  String _getImageUrl(int number, String suit) {
    // Replace this with actual image URLs or asset paths
    return 'https://example.com/cards/$suit/$number.png';
  }

  // CRUD methods go here

  // Folder Methods
  Future<List<Folder>> getFolders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('folders');

    return List.generate(maps.length, (i) {
      return Folder.fromMap(maps[i]);
    });
  }

  Future<void> insertFolder(Folder folder) async {
    final db = await database;
    await db.insert('folders', folder.toMap());
  }

  Future<void> updateFolder(Folder folder) async {
    final db = await database;
    await db.update(
      'folders',
      folder.toMap(),
      where: 'id = ?',
      whereArgs: [folder.id],
    );
  }

  Future<void> deleteFolder(int id) async {
    final db = await database;
    await db.delete(
      'folders',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Delete associated cards
    await db.delete(
      'cards',
      where: 'folderId = ?',
      whereArgs: [id],
    );
  }

  // Card Methods
  Future<List<CardModel>> getCards({int? folderId}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;

    if (folderId != null) {
      maps = await db.query(
        'cards',
        where: 'folderId = ?',
        whereArgs: [folderId],
      );
    } else {
      maps = await db.query('cards');
    }

    return List.generate(maps.length, (i) {
      return CardModel.fromMap(maps[i]);
    });
  }

  Future<void> insertCard(CardModel card) async {
    final db = await database;
    await db.insert('cards', card.toMap());
  }

  Future<void> updateCard(CardModel card) async {
    final db = await database;
    await db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<void> deleteCard(int id) async {
    final db = await database;
    await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCardCountInFolder(int folderId) async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM cards WHERE folderId = ?',
      [folderId],
    ));
    return count ?? 0;
  }
}
