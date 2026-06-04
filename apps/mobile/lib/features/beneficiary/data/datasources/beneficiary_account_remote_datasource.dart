import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:saveameal/core/models/beneficiary_model.dart';
import 'package:saveameal/core/models/user_model.dart';
import 'package:saveameal/features/beneficiary/data/models/beneficiary_profile_model.dart';
import 'package:saveameal/features/beneficiary/domain/entities/beneficiary_org_profile_update.dart';
import 'package:saveameal/features/donor/domain/entities/user_profile_update.dart';
import 'package:saveameal/services/firestore_service.dart';

abstract class BeneficiaryAccountRemoteDatasource {
  Stream<BeneficiaryProfileModel?> watchProfile(String uid);
  Future<void> updatePersonalInfo(String uid, UserProfileUpdate update);
  Future<void> updateOrgProfile(String uid, BeneficiaryOrgProfileUpdate update);
  Stream<List<Map<String, dynamic>>> watchOrderHistory(
    String uid, {
    String? cursor,
    int limit = 10,
  });
}

class BeneficiaryAccountRemoteDatasourceImpl
    implements BeneficiaryAccountRemoteDatasource {
  const BeneficiaryAccountRemoteDatasourceImpl(this._firestoreService);

  final FirestoreService _firestoreService;

  @override
  Stream<BeneficiaryProfileModel?> watchProfile(String uid) {
    UserModel? latestUser;
    BeneficiaryModel? latestBeneficiary;
    StreamSubscription<UserModel?>? userSub;
    StreamSubscription<BeneficiaryModel?>? beneficiarySub;
    late StreamController<BeneficiaryProfileModel?> controller;

    void emit() {
      if (latestUser == null) return;
      final joinedAt = FirebaseAuth.instance.currentUser?.metadata.creationTime;
      controller.add(
        BeneficiaryProfileModel(
          userModel: latestUser!,
          beneficiaryModel: latestBeneficiary,
          mealsReceived: 0,
          joinedAt: joinedAt,
        ),
      );
    }

    controller = StreamController<BeneficiaryProfileModel?>(
      onListen: () {
        userSub = _firestoreService.watchUser(uid).listen((user) {
          latestUser = user;
          if (user == null) {
            controller.add(null);
          } else {
            emit();
          }
        });
        beneficiarySub = _firestoreService.watchBeneficiaryDoc(uid).listen((b) {
          latestBeneficiary = b;
          emit();
        });
      },
      onCancel: () {
        userSub?.cancel();
        beneficiarySub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<void> updatePersonalInfo(String uid, UserProfileUpdate update) {
    final data = <String, dynamic>{};
    if (update.name != null) data['name'] = update.name;
    if (update.phone != null) data['phone'] = update.phone;
    if (update.location != null) data['location'] = update.location;
    if (update.photoUrl != null) data['photoUrl'] = update.photoUrl;
    return _firestoreService.updateUser(uid, data);
  }

  @override
  Future<void> updateOrgProfile(
    String uid,
    BeneficiaryOrgProfileUpdate update,
  ) {
    final data = <String, dynamic>{};
    if (update.orgName != null) data['name'] = update.orgName;
    if (update.address != null) data['address'] = update.address;
    if (update.orgType != null) data['orgType'] = update.orgType;
    if (update.contactEmail != null) data['contactEmail'] = update.contactEmail;
    if (update.missionStatement != null) {
      data['missionStatement'] = update.missionStatement;
    }
    return _firestoreService.updateBeneficiary(uid, data);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchOrderHistory(
    String uid, {
    String? cursor,
    int limit = 10,
  }) => Stream.value([]);
}
