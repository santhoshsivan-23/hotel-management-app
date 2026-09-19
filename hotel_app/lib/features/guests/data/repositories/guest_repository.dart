import '../../../../core/db/app_database.dart';
import '../../../../core/db/daos/guest_dao.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../models/guest_model.dart';

/// Guests are fully offline-capable: every read/write here goes straight
/// to the local SQLite cache. Nothing in this class touches the network -
/// that only happens later, in bulk, when SyncManager.syncAll() runs.
class GuestRepository {
  GuestRepository(AppDatabase database) : _dao = GuestDao(database);
  final GuestDao _dao;

  Future<List<GuestModel>> findAll({String? search}) async {
    final rows = await _dao.findAll(search: search);
    return rows.map(GuestModel.fromMap).toList();
  }

  Future<GuestModel?> findByUuid(String uuid) async {
    final row = await _dao.findByUuid(uuid);
    return row == null ? null : GuestModel.fromMap(row);
  }

  Future<GuestModel> create({
    required String name,
    required String mobile,
    String? email,
    String? idProofType,
    String? idProofNumber,
    String? address,
    String? deviceId,
  }) async {
    final now = DateTime.now().toUtc();
    final guest = GuestModel(
      uuid: UuidGenerator.generate(),
      name: name,
      mobile: mobile,
      email: email,
      idProofType: idProofType,
      idProofNumber: idProofNumber,
      address: address,
      syncStatus: 'PENDING',
      createdAt: now,
      updatedAt: now,
    );

    final row = guest.toMap();
    if (deviceId != null) row['device_id'] = deviceId;
    await _dao.insert(row);
    return guest;
  }

  Future<void> update(
    String uuid, {
    String? name,
    String? mobile,
    String? email,
    String? idProofType,
    String? idProofNumber,
    String? address,
  }) async {
    final changes = <String, dynamic>{};
    if (name != null) changes['name'] = name;
    if (mobile != null) changes['mobile'] = mobile;
    if (email != null) changes['email'] = email;
    if (idProofType != null) changes['id_proof_type'] = idProofType;
    if (idProofNumber != null) changes['id_proof_number'] = idProofNumber;
    if (address != null) changes['address'] = address;
    await _dao.update(uuid, changes);
  }

  Future<void> delete(String uuid) => _dao.softDelete(uuid);
}
