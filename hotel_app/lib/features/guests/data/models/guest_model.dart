/// Guest profile. `uuid` is the local/sync identity (set the moment the
/// record is created, before any network call); `serverId` is filled in
/// once SyncManager successfully pushes it.
class GuestModel {
  GuestModel({
    required this.uuid,
    this.serverId,
    required this.name,
    required this.mobile,
    this.email,
    this.idProofType,
    this.idProofNumber,
    this.address,
    required this.syncStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uuid;
  final int? serverId;
  final String name;
  final String mobile;
  final String? email;
  final String? idProofType;
  final String? idProofNumber;
  final String? address;
  final String syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => syncStatus == 'PENDING' || syncStatus == 'FAILED';

  factory GuestModel.fromMap(Map<String, dynamic> map) {
    return GuestModel(
      uuid: map['uuid'] as String,
      serverId: map['server_id'] as int?,
      name: map['name'] as String,
      mobile: map['mobile'] as String,
      email: map['email'] as String?,
      idProofType: map['id_proof_type'] as String?,
      idProofNumber: map['id_proof_number'] as String?,
      address: map['address'] as String?,
      syncStatus: map['sync_status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'server_id': serverId,
      'name': name,
      'mobile': mobile,
      'email': email,
      'id_proof_type': idProofType,
      'id_proof_number': idProofNumber,
      'address': address,
      'sync_status': syncStatus,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_deleted': 0,
    };
  }
}
