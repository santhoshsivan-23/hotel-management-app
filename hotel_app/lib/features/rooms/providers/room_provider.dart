import 'package:flutter/foundation.dart';
import '../../../core/db/app_database.dart';
import '../../../core/network/api_client.dart';
import '../data/models/room_model.dart';
import '../data/repositories/room_repository.dart';

class RoomProvider extends ChangeNotifier {
  RoomProvider({required AppDatabase database, required ApiClient apiClient})
      : _repository = RoomRepository(database: database, apiClient: apiClient);

  final RoomRepository _repository;

  List<RoomModel> _rooms = [];
  bool _loading = false;
  String? _statusFilter;

  List<RoomModel> get rooms => _rooms;
  bool get loading => _loading;
  String? get statusFilter => _statusFilter;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _rooms = await _repository.findAll(status: _statusFilter);
    _loading = false;
    notifyListeners();
  }

  Future<void> setStatusFilter(String? status) async {
    _statusFilter = status;
    await load();
  }

  Future<String?> createRoom({
    required String roomNumber,
    required int roomTypeId,
    String? floor,
    required int capacity,
    required double price,
  }) async {
    try {
      await _repository.create(
        roomNumber: roomNumber,
        roomTypeId: roomTypeId,
        floor: floor,
        capacity: capacity,
        price: price,
      );
      await load();
      return null;
    } catch (e) {
      return 'Could not create room - connect to the internet and try again ($e)';
    }
  }

  Future<String?> updateStatus(int roomId, String status) async {
    try {
      await _repository.updateStatus(roomId, status);
      await load();
      return null;
    } catch (e) {
      return 'Could not update room status - connect to the internet and try again';
    }
  }
}
