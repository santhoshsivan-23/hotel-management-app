import '../../../../core/db/app_database.dart';
import '../../../../core/db/daos/food_order_dao.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../models/food_order_model.dart';

class FoodOrderRepository {
  FoodOrderRepository(AppDatabase database) : _dao = FoodOrderDao(database);
  final FoodOrderDao _dao;

  Future<List<FoodOrderModel>> findAll({String? status, String? bookingUuid}) async {
    final rows = await _dao.findAll(status: status, bookingUuid: bookingUuid);
    return rows.map((r) => FoodOrderModel.fromMap(r)).toList();
  }

  Future<FoodOrderModel?> findByUuid(String uuid) async {
    final row = await _dao.findByUuid(uuid);
    if (row == null) return null;
    final itemRows = await _dao.itemsFor(uuid);
    return FoodOrderModel.fromMap(row, items: itemRows.map(FoodOrderItemModel.fromMap).toList());
  }

  Future<FoodOrderModel> create({
    required String bookingUuid,
    required int roomId,
    required String guestUuid,
    required List<FoodOrderItemModel> items,
    String? deviceId,
  }) async {
    final now = DateTime.now().toUtc();
    final totalAmount = items.fold<double>(0, (sum, i) => sum + i.lineTotal);
    final orderUuid = UuidGenerator.generate();

    // Item uuids are assigned here, not trusted from the caller - this is
    // the one place responsible for guaranteeing every food_order_items
    // row gets a unique primary key.
    final finalItems = items
        .map((i) => FoodOrderItemModel(
              uuid: UuidGenerator.generate(),
              productName: i.productName,
              quantity: i.quantity,
              price: i.price,
              modifiers: i.modifiers,
              notes: i.notes,
            ))
        .toList();

    final order = FoodOrderModel(
      uuid: orderUuid,
      bookingUuid: bookingUuid,
      roomId: roomId,
      guestUuid: guestUuid,
      status: 'NEW',
      totalAmount: totalAmount,
      syncStatus: 'PENDING',
      createdAt: now,
      updatedAt: now,
      items: finalItems,
    );

    final orderRow = order.toMap();
    if (deviceId != null) orderRow['device_id'] = deviceId;

    await _dao.insertWithItems(orderRow, finalItems.map((i) => i.toMap(orderUuid)).toList());
    return order;
  }

  Future<void> updateStatus(String uuid, String status) => _dao.updateStatus(uuid, status);

  Future<double> totalForBooking(String bookingUuid) => _dao.totalForBooking(bookingUuid);
}
