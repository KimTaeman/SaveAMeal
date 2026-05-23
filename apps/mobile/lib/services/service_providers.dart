import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saveameal/services/auth_service.dart';
import 'package:saveameal/services/firestore_service.dart';

part 'service_providers.g.dart';

@riverpod
AuthService authService(Ref ref) => AuthService(FirebaseAuth.instance);

@riverpod
FirestoreService firestoreService(Ref ref) =>
    FirestoreService(FirebaseFirestore.instance);
