import 'package:flutter/foundation.dart';
import '../../../core/db/app_database.dart';
import '../data/models/guest_model.dart';
import '../data/repositories/guest_repository.dart';

class GuestProvider extends ChangeNotifier {
  GuestProvider(AppDatabase database, {this.deviceId}) : _repository = GuestRepository(database);

  final GuestRepository _repository;
  final String? deviceId;

  List<GuestModel> _guests = [];
  bool _loading = false;
  String _search = '';

  List<GuestModel> get guests => _guests;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _guests = await _repository.findAll(search: _search.isEmpty ? null : _search);
    _loading = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    _search = query;
    await load();
  }

  Future<GuestModel> createGuest({
    required String name,
    required String mobile,
    String? email,
    String? idProofType,
    String? idProofNumber,
    String? address,
  }) async {
    final guest = await _repository.create(
      name: name,
      mobile: mobile,
      email: email,
      idProofType: idProofType,
      idProofNumber: idProofNumber,
      address: address,
      deviceId: deviceId,
    );
    await load();
    return guest;
  }

  Future<void> updateGuest(
    String uuid, {
    String? name,
    String? mobile,
    String? email,
    String? idProofType,
    String? idProofNumber,
    String? address,
  }) async {
    await _repository.update(
      uuid,
      name: name,
      mobile: mobile,
      email: email,
      idProofType: idProofType,
      idProofNumber: idProofNumber,
      address: address,
    );
    await load();
  }

  Future<void> deleteGuest(String uuid) async {
    await _repository.delete(uuid);
    await load();
  }
}
