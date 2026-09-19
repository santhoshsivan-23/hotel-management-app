import 'package:flutter/foundation.dart';
import '../../../core/db/app_database.dart';
import '../data/models/food_order_model.dart';
import '../data/repositories/food_order_repository.dart';

class FoodOrderProvider extends ChangeNotifier {
  FoodOrderProvider(AppDatabase database, {this.deviceId}) : _repository = FoodOrderRepository(database);

  final FoodOrderRepository _repository;
  final String? deviceId;

  List<FoodOrderModel> _orders = [];
  bool _loading = false;
  String? _statusFilter;

  List<FoodOrderModel> get orders => _orders;
  bool get loading => _loading;
  String? get statusFilter => _statusFilter;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _orders = await _repository.findAll(status: _statusFilter);
    _loading = false;
    notifyListeners();
  }

  Future<void> setStatusFilter(String? status) async {
    _statusFilter = status;
    await load();
  }

  Future<void> updateStatus(String uuid, String status) async {
    await _repository.updateStatus(uuid, status);
    await load();
  }
}
