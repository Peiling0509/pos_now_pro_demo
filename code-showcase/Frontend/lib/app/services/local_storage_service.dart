import 'dart:convert';

import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/models/main_menu_model.dart';
import '../data/models/table_model.dart';

class LocalStorageService extends GetxService {
  Database? _db;

  Future<LocalStorageService> init() async {
    _db = await _initDB();
    Get.log("Database Initialized");
    return this;
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pos_now.db');

    return await openDatabase(path, version: 1, onCreate: _createTables);
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY,
        name TEXT,
        sub_name TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE category_items(
        id INTEGER PRIMARY KEY,
        category_id INTEGER,
        name TEXT,
        sub_name TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE menu_items(
        id INTEGER PRIMARY KEY,
        category_item_id INTEGER,
        food_code TEXT,
        name TEXT,
        sub_name TEXT,
        price REAL,
        is_open_price INTEGER,
        image TEXT,
        is_available INTEGER,
        remarks TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE option_type(
        id INTEGER PRIMARY KEY,
        name TEXT,
        sub_name TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE options(
        id INTEGER PRIMARY KEY,
        option_type_id INTEGER,
        name TEXT,
        sub_name TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE menu_item_options(
        id INTEGER PRIMARY KEY,
        menu_item_id INTEGER,
        option_id INTEGER,
        extra_price REAL
      );
    ''');

    // await db.execute('''
    //   CREATE TABLE tables(
    //     id INTEGER PRIMARY KEY,
    //     name TEXT,
    //     status TEXT,
    //     created_at TEXT,
    //     updated_at TEXT
    //   );
    // ''');
  }

  // Future<void> saveTables(List<TableModel> list) async {
  //   // Use the getter to ensure DB is open
  //   final db = await database;
  //
  //   await db.transaction((txn) async {
  //     await txn.delete("tables");
  //     final batch = txn.batch();
  //     for (var t in list) {
  //       // Ensure TableModel.toJson matches your Table columns exactly
  //       batch.insert("tables", t.toJson());
  //     }
  //     await batch.commit(noResult: true);
  //   });
  // }

  // Future<List<TableModel>> getLocalTables() async {
  //   final db = await database;
  //
  //   // Query the table
  //   final List<Map<String, dynamic>> maps = await db.query('tables');
  //
  //   // Convert List<Map> to List<TableModel>
  //   return List.generate(maps.length, (i) {
  //     return TableModel.fromJson(maps[i]);
  //   });
  // }
  //
  // Future<void> updateTable(String id, String status) async {
  //   final db = await database;
  //   await db.update(
  //     'tables',
  //     {'status': status},
  //     where: 'id = ?',
  //     whereArgs: [int.parse(id)],
  //   );
  // }

  Future<void> saveFullMenu(List<MainMenuModel> categories) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Clear existing menu data (Full Refresh)
      await txn.delete('menu_item_options');
      await txn.delete('menu_items');
      await txn.delete('category_items');
      await txn.delete('categories');
      await txn.delete('options');

      // 2. Batch Insert variables
      final batch = txn.batch();

      for (var cat in categories) {
        // Insert Category
        batch.insert('categories', {
          'id': cat.id,
          'name': cat.name,
          'sub_name': cat.subName,
        });

        // Loop Category Items
        for (var item in cat.categoryItems) {
          batch.insert('category_items', {
            'id': item.id,
            'category_id': cat.id,
            'name': item.name,
            'sub_name': item.subName,
          });

          // Loop Menu Items
          for (var menu in item.menuItems) {
            batch.insert('menu_items', {
              'id': menu.id,
              'category_item_id': item.id,
              'food_code':menu.foodCode,
              'name': menu.name,
              'sub_name': menu.subName,
              'price': menu.price,
              'is_open_price': menu.isOpenPrice ? 1 : 0,
              'image': menu.image,
              'is_available': menu.isAvailable ? 1 : 0,
              'remarks': menu.remarks,
            });

            // Loop Options
            for (var opt in menu.options) {
              // --- A. Insert into OPTIONS Table ---
              // We use ConflictAlgorithm.replace because the same option (e.g., "Small", ID:1)
              // appears multiple times in the JSON (once for every menu item that has it).
              // We only need to store the definition once.
              batch.insert('options', {
                'id': opt.id,
                'option_type_id': opt.optionTypeId, // Storing the relationship
                'name': opt.name,
                'sub_name': opt.subName,
              }, conflictAlgorithm: ConflictAlgorithm.replace);

              // --- B. Insert into MENU_ITEM_OPTIONS (Pivot) Table ---
              // This links the specific Menu Item to the Option and stores the price
              batch.insert('menu_item_options', {
                // We let SQLite auto-generate the pivot ID, or you can calculate it
                'menu_item_id': menu.id,
                'option_id': opt.id,
                'extra_price': opt.extraPrice,
              });
            }
          }
        }
      }

      // 3. Commit all inserts at once
      await batch.commit(noResult: true);
    });
  }

  Future<List<MainMenuModel>> getFullMenu() async {
    final db = await database;

    // 1. Fetch all raw data needed
    final catMaps = await db.query('categories');
    final subCatMaps = await db.query('category_items');
    final menuItemMaps = await db.query('menu_items');
    final options = await db.query('options');
    final menuItemOptions = await db.query('menu_item_options');

    // // =========================================================
    // // 👇 DEBUG PRINTING CODE STARTS HERE
    // // =========================================================
    //
    // // Create a "Pretty Printer"
    // const encoder = JsonEncoder.withIndent('  ');
    //
    // print("🔴 RAW CATEGORIES TABLE (${catMaps.length} records):");
    // print(encoder.convert(catMaps));
    //
    // print("\n🔵 RAW SUB-CATEGORIES TABLE (${subCatMaps.length} records):");
    // print(encoder.convert(subCatMaps));
    //
    // print("\n🟢 RAW MENU ITEMS TABLE (${menuItemMaps.length} records):");
    // print(encoder.convert(menuItemMaps));
    //
    // print("\n🟢 RAW MENU OPTIONS TABLE (${menuItemOptions.length} records):");
    // print(encoder.convert(menuItemOptions));
    //
    // print("\n🟢 RAW OPTIONS TABLE (${options.length} records):");
    // print(encoder.convert(options));
    //
    // // =========================================================
    // // 👆 DEBUG PRINTING CODE ENDS HERE
    // // =========================================================

    // A. Create a Lookup Map for Option Definitions (ID -> Data)
    // This lets us find "Spicy" just by knowing ID 1 without looping
    final Map<int, Map<String, dynamic>> optionDefs = {
      for (var o in options) (o['id'] as int): o,
    };

    // B. Group Pivot Data by Menu Item ID
    // Key: MenuItemID, Value: List of links (Pivot rows)
    final Map<int, List<Map<String, dynamic>>> itemOptionsMap = {};

    for (var pivot in menuItemOptions) {
      int itemId = pivot['menu_item_id'] as int;
      if (!itemOptionsMap.containsKey(itemId)) {
        itemOptionsMap[itemId] = [];
      }
      itemOptionsMap[itemId]!.add(pivot);
    }
    List<MainMenuModel> mainMenu = [];

    for (var cMap in catMaps) {
      int catId = cMap['id'] as int;

      // Find all sub-categories belonging to this Main Category
      var mySubCats = subCatMaps.where((s) => s['category_id'] == catId);

      List<CategoryItemModel> subCategoryModels = [];

      for (var sMap in mySubCats) {
        int subCatId = sMap['id'] as int;

        // Find all menu items belonging to this Sub Category
        var myItems = menuItemMaps.where(
          (m) => m['category_item_id'] == subCatId,
        );

        List<MenuItemModel> itemModels = myItems.map((mMap) {
          int itemId = mMap['id'] as int;

          // --- BUILD OPTIONS LIST FOR THIS ITEM ---
          List<OptionModel> myOptions = [];

          // 1. Check if this item has any options in our grouped map
          if (itemOptionsMap.containsKey(itemId)) {
            final pivotRows = itemOptionsMap[itemId]!;

            for (var pivot in pivotRows) {
              int optionId = pivot['option_id'] as int;

              // 2. Get the option definition (Name, Type)
              final def = optionDefs[optionId];

              if (def != null) {
                // 3. Create the OptionModel combining Pivot Price + Definition Name
                myOptions.add(
                  OptionModel(
                    id: optionId,
                    // Handle potential null/type mismatch safely
                    optionTypeId: (def['option_type_id'] as num?)?.toInt() ?? 0,
                    name: def['name'] as String,
                    subName: def['sub_name'] as String,
                    // Price comes from the PIVOT table, not the definition
                    extraPrice:
                        (pivot['extra_price'] as num?)?.toDouble() ?? 0.0,
                  ),
                );
              }
            }
          }

          // --- CONSTRUCT ITEM WITH OPTIONS ---
          // We use the constructor directly because mMap doesn't contain the options list
          return MenuItemModel(
            id: itemId,
            categoryItemId: (mMap['category_item_id'] as num).toInt(),
            foodCode: mMap['food_code'] as String,
            name: mMap['name'] as String,
            subName: mMap['sub_name'] as String,
            price: (mMap['price'] as num).toDouble(),
            isOpenPrice: (mMap['is_open_price'] as num) == 1,
            image: mMap['image'] as String?,
            isAvailable: (mMap['is_available'] as num) == 1,
            remarks: mMap['remarks'] as String?,
            options: myOptions,
          );
        }).toList();

        subCategoryModels.add(
          CategoryItemModel(
            id: subCatId,
            categoryId: catId,
            name: sMap['name'] as String,
            subName: sMap['sub_name'] as String,
            menuItems: itemModels,
          ),
        );
      }

      mainMenu.add(
        MainMenuModel(
          id: catId,
          name: cMap['name'] as String,
          subName: cMap['sub_name'] as String,
          categoryItems: subCategoryModels,
        ),
      );
    }

    // ---------------------------------------------------------
    // DEBUG PRINTING: VISUALIZE THE TREE
    // ---------------------------------------------------------
    // Get.log("====== FULL MENU TREE START ======");
    // for (var mainCat in mainMenu) {
    //   Get.log("📂 MAIN: ${mainCat.name} (ID: ${mainCat.id})");
    //
    //   if (mainCat.categoryItems.isEmpty) {
    //     Get.log("   (No Sub-Categories)");
    //   }
    //
    //   for (var subCat in mainCat.categoryItems) {
    //     Get.log("   └── 📁 SUB: ${subCat.name} (ID: ${subCat.id})");
    //
    //     if (subCat.menuItems.isEmpty) {
    //       Get.log("       (No Items)");
    //     }
    //
    //     for (var item in subCat.menuItems) {
    //       Get.log("       └── 🍔 ITEM: ${item.name} | ${item.price} | Options: ${item.options.length}");
    //     }
    //   }
    //   Get.log(""); // Empty line between main categories
    // }
    // Get.log("====== FULL MENU TREE END ======");

    return mainMenu;
  }

  Future<MenuItemModel?> getMenuItemById(int id) async {
    final db = await database;

    // 1. Fetch the main menu item record
    final List<Map<String, dynamic>> maps = await db.query(
      'menu_items',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final mMap = maps.first;

    // 2. Fetch associated options via the pivot table
    // Join menu_item_options with options to get names and types
    final List<Map<String, dynamic>> optionMaps = await db.rawQuery(
      '''
      SELECT 
        o.id, 
        o.option_type_id, 
        o.name,
        o.sub_name,
        mio.extra_price 
      FROM menu_item_options mio
      INNER JOIN options o ON mio.option_id = o.id
      WHERE mio.menu_item_id = ?
    ''',
      [id],
    );

    // 3. Build the list of OptionModel
    List<OptionModel> options = optionMaps.map((oMap) {
      return OptionModel(
        id: oMap['id'] as int,
        optionTypeId: (oMap['option_type_id'] as num).toInt(),
        name: oMap['name'] as String,
        subName: oMap['sub_name'] as String,
        extraPrice: (oMap['extra_price'] as num).toDouble(),
      );
    }).toList();

    // 4. Return the fully constructed MenuItemModel
    return MenuItemModel(
      id: mMap['id'] as int,
      categoryItemId: (mMap['category_item_id'] as num).toInt(),
      foodCode: mMap['food_code'] as String,
      name: mMap['name'] as String,
      subName: mMap['sub_name'] as String,
      price: (mMap['price'] as num).toDouble(),
      isOpenPrice: (mMap['is_open_price'] as int) == 1,
      image: mMap['image'] as String?,
      isAvailable: (mMap['is_available'] as int) == 1,
      remarks: mMap['remarks'] as String?,
      options: options,
    );
  }

  /// Use this when you change table structure (schema) or want a fresh start.
  Future<void> hardResetDatabase() async {
    try {
      // 1. Close the existing connection if open
      if (_db != null && _db!.isOpen) {
        await _db!.close();
        _db = null; // Reset variable
      }

      // 2. Find the file path
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'pos_now.db');

      // 3. Delete the file using sqflite's built-in function
      await deleteDatabase(path);

      Get.log("🗑️ Database file deleted successfully.");

      // 4. Re-initialize to create fresh tables immediately
      await init();
    } catch (e) {
      Get.log("❌ Error resetting database: $e");
    }
  }
}
