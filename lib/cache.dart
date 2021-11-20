import 'dart:io' show Platform;
import 'package:path/path.dart' show join;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cv/cv.dart';
import 'package:http/http.dart' as http;

const String columnId = '_id';

Database? db;

void initDB() {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    sqfliteFfiInit();
  }
}

abstract class DbRecord extends CvModelBase {
  final id = CvField<int>(columnId);
}

Future<Database?> openDB() async {
  if (db != null) {
    return db;
  }

  // if linux
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    var databaseFactory = databaseFactoryFfi;
    String dbPath =
        join(await databaseFactory.getDatabasesPath(), 'cache.sqlite');
    // String dbPath = inMemoryDatabasePath;
    db = await databaseFactory.openDatabase(dbPath);
  }

  // if android
  if (Platform.isAndroid) {
    String dbPath =
        join(await getDatabasesPath(), 'cache.sqlite');
    // String dbPath = inMemoryDatabasePath;
    db = await openDatabase(dbPath);
  }

  await db?.execute('''
  CREATE TABLE IF NOT EXISTS cache (
      id INTEGER PRIMARY KEY,
      key INTEGER UNIQUE,
      path TEXT,
      content TEXT
  )
  ''');

  await db?.execute('''
  DROP TABLE IF EXISTS session_cache;
  ''');

  await db?.execute('''
  CREATE TABLE IF NOT EXISTS session_cache (
      id INTEGER PRIMARY KEY,
      key INTEGER UNIQUE,
      path TEXT,
      content TEXT
  )
  ''');

  print('db open');
  return db;
}

Future<String?> cachedHttpFetch(String path, String key,
    {bool sessionOnly = false}) async {
  try {
    String cache = sessionOnly ? 'session_cache' : 'cache';

    if (db != null) {
      var result =
          await db?.query(cache, where: 'key=?', whereArgs: [key.hashCode]);

      int l = result?.length ?? 0;
      if (l > 0) {
        Map? obj = result?[0] as Map;
        print('fetched from cache');
        return obj['content'];
      }
    }

    var response = await http.get(Uri.parse(path));
    if (response.statusCode != 200) {
      print('unable to fetch');
      return null;
    }

    print(response.statusCode);

    if (db != null) {
      print('save to ${cache}');
      await db?.insert(cache,
          <String, Object?>{'key': key.hashCode, 'content': response.body});
      return response.body;
    }

    // return response.body;
  } catch (err, msg) {
    print(err); // snackbar network error!
    return null;
  }

  return null;
}
