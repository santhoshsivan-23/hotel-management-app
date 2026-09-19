/// Line items for a food order. Kept simple (no independent sync_status)
/// because items always travel embedded with their parent order - see
/// FoodOrderSyncApi, which sends the whole item list alongside the order
/// and the backend replaces the item set wholesale on each sync.
class FoodOrderItemsTable {
  FoodOrderItemsTable._();

  static const String tableName = 'food_order_items';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      uuid TEXT PRIMARY KEY,
      food_order_uuid TEXT NOT NULL,
      product_name TEXT NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 1,
      price REAL NOT NULL DEFAULT 0,
      modifiers TEXT,
      notes TEXT,
      FOREIGN KEY (food_order_uuid) REFERENCES food_orders (uuid) ON DELETE CASCADE
    );
  ''';

  static const String idxFoodOrder =
      'CREATE INDEX IF NOT EXISTS idx_food_order_items_order ON $tableName (food_order_uuid);';
}
