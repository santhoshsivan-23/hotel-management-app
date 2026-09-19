import 'package:flutter/foundation.dart';
import '../../../core/db/app_database.dart';
import '../data/models/service_request_model.dart';
import '../data/repositories/service_request_repository.dart';

class ServiceProvider extends ChangeNotifier {
  ServiceProvider(AppDatabase database) : _repository = ServiceRequestRepository(database);

  final ServiceRequestRepository _repository;

  List<ServiceRequestModel> _requests = [];
  bool _loading = false;
  String? _statusFilter;

  List<ServiceRequestModel> get requests => _requests;
  bool get loading => _loading;
  String? get statusFilter => _statusFilter;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _requests = await _repository.findAll(status: _statusFilter);
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
