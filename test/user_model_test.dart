import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurantos/features/auth/data/models/user_model.dart';
import 'package:restaurantos/features/auth/domain/entities/user_entity.dart';

void main() {
  final tCreatedAt = DateTime.utc(2026, 7, 3, 12, 0, 0);
  final tUpdatedAt = DateTime.utc(2026, 7, 3, 12, 30, 0);

  final tUserModel = UserModel(
    uid: '123',
    name: 'John Doe',
    email: 'john@example.com',
    phoneNumber: '+1234567890',
    role: 'customer',
    isActive: true,
    createdAt: tCreatedAt,
    updatedAt: tUpdatedAt,
  );

  group('UserModel Serialization Tests', () {
    test('should be a subclass of UserEntity', () {
      expect(tUserModel, isA<UserEntity>());
    });

    test('should parse from standard JSON with ISO-8601 strings', () {
      final Map<String, dynamic> jsonMap = {
        'uid': '123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phoneNumber': '+1234567890',
        'role': 'customer',
        'isActive': true,
        'createdAt': '2026-07-03T12:00:00.000Z',
        'updatedAt': '2026-07-03T12:30:00.000Z',
      };

      final result = UserModel.fromJson(jsonMap);

      expect(result.uid, '123');
      expect(result.name, 'John Doe');
      expect(result.email, 'john@example.com');
      expect(result.phoneNumber, '+1234567890');
      expect(result.role, 'customer');
      expect(result.isActive, true);
      expect(result.createdAt, tCreatedAt);
      expect(result.updatedAt, tUpdatedAt);
    });

    test('should parse from Firestore map with Timestamp objects', () {
      final Map<String, dynamic> firestoreMap = {
        'uid': '123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phoneNumber': '+1234567890',
        'role': 'customer',
        'isActive': true,
        'createdAt': Timestamp.fromDate(tCreatedAt),
        'updatedAt': Timestamp.fromDate(tUpdatedAt),
      };

      final result = UserModel.fromJson(firestoreMap);

      expect(result.createdAt.toUtc(), tCreatedAt);
      expect(result.updatedAt.toUtc(), tUpdatedAt);
    });

    test('should convert to standard JSON Map (ISO-8601 strings)', () {
      final result = tUserModel.toJson();

      final expectedJsonMap = {
        'uid': '123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phoneNumber': '+1234567890',
        'role': 'customer',
        'isActive': true,
        'createdAt': '2026-07-03T12:00:00.000Z',
        'updatedAt': '2026-07-03T12:30:00.000Z',
      };

      expect(result, expectedJsonMap);
    });

    test('should convert to Firestore map (Timestamps)', () {
      final result = tUserModel.toFirestore();

      expect(result['createdAt'], isA<Timestamp>());
      expect((result['createdAt'] as Timestamp).toDate().toUtc(), tCreatedAt);
      expect(result['updatedAt'], isA<Timestamp>());
      expect((result['updatedAt'] as Timestamp).toDate().toUtc(), tUpdatedAt);
    });
  });
}
