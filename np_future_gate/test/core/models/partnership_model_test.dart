import 'package:flutter_test/flutter_test.dart';
import 'package:np_future_gate/core/models/partnership_model.dart';

void main() {
  group('PartnershipModel', () {
    final sampleJson = {
      'id': 'p-123',
      'school_id': 'school-456',
      'company_id': 'company-789',
      'status': 'pending',
      'post_limit_count': 10,
      'post_limit_period': 'month',
      'created_at': '2024-01-15T10:30:00.000Z',
      'updated_at': '2024-02-20T14:00:00.000Z',
    };

    test('fromJson creates model with all fields', () {
      final model = PartnershipModel.fromJson(sampleJson);

      expect(model.id, 'p-123');
      expect(model.schoolId, 'school-456');
      expect(model.companyId, 'company-789');
      expect(model.status, 'pending');
      expect(model.postLimitCount, 10);
      expect(model.postLimitPeriod, 'month');
      expect(model.createdAt, DateTime.utc(2024, 1, 15, 10, 30));
      expect(model.updatedAt, DateTime.utc(2024, 2, 20, 14, 0));
    });

    test('fromJson handles null createdAt and updatedAt', () {
      final json = {
        'id': 'p-123',
        'school_id': 'school-456',
        'company_id': 'company-789',
        'status': 'approved',
        'post_limit_count': 5,
        'post_limit_period': 'year',
      };

      final model = PartnershipModel.fromJson(json);

      expect(model.createdAt, isNull);
      expect(model.updatedAt, isNull);
    });

    test('fromJson throws on missing required field: id', () {
      final json = Map<String, dynamic>.from(sampleJson)..remove('id');
      expect(
        () => PartnershipModel.fromJson(json),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('id'),
        )),
      );
    });

    test('fromJson throws on missing required field: school_id', () {
      final json = Map<String, dynamic>.from(sampleJson)..remove('school_id');
      expect(
        () => PartnershipModel.fromJson(json),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('school_id'),
        )),
      );
    });

    test('fromJson throws on missing required field: company_id', () {
      final json = Map<String, dynamic>.from(sampleJson)..remove('company_id');
      expect(
        () => PartnershipModel.fromJson(json),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('company_id'),
        )),
      );
    });

    test('fromJson throws on missing required field: status', () {
      final json = Map<String, dynamic>.from(sampleJson)..remove('status');
      expect(
        () => PartnershipModel.fromJson(json),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('status'),
        )),
      );
    });

    test('fromJson throws on missing required field: post_limit_count', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..remove('post_limit_count');
      expect(
        () => PartnershipModel.fromJson(json),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('post_limit_count'),
        )),
      );
    });

    test('fromJson throws on missing required field: post_limit_period', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..remove('post_limit_period');
      expect(
        () => PartnershipModel.fromJson(json),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('post_limit_period'),
        )),
      );
    });

    test('fromJson throws on invalid status value', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..['status'] = 'invalid';
      expect(
        () => PartnershipModel.fromJson(json),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Invalid status value'),
        )),
      );
    });

    test('fromJson throws on invalid post_limit_period value', () {
      final json = Map<String, dynamic>.from(sampleJson)
        ..['post_limit_period'] = 'week';
      expect(
        () => PartnershipModel.fromJson(json),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Invalid post_limit_period value'),
        )),
      );
    });

    test('toJson produces correct map', () {
      final model = PartnershipModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 'p-123');
      expect(json['school_id'], 'school-456');
      expect(json['company_id'], 'company-789');
      expect(json['status'], 'pending');
      expect(json['post_limit_count'], 10);
      expect(json['post_limit_period'], 'month');
      expect(json['created_at'], '2024-01-15T10:30:00.000Z');
      expect(json['updated_at'], '2024-02-20T14:00:00.000Z');
    });

    test('toJson omits null createdAt and updatedAt', () {
      final model = PartnershipModel(
        id: 'p-1',
        schoolId: 's-1',
        companyId: 'c-1',
        status: 'pending',
        postLimitCount: 3,
        postLimitPeriod: 'month',
      );
      final json = model.toJson();

      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
    });

    test('serialization round trip preserves all fields', () {
      final model = PartnershipModel.fromJson(sampleJson);
      final roundTripped = PartnershipModel.fromJson(model.toJson());

      expect(roundTripped, equals(model));
    });

    test('copyWith creates new instance with updated fields', () {
      final model = PartnershipModel.fromJson(sampleJson);
      final updated = model.copyWith(
        status: 'approved',
        postLimitCount: 20,
      );

      expect(updated.id, model.id);
      expect(updated.schoolId, model.schoolId);
      expect(updated.companyId, model.companyId);
      expect(updated.status, 'approved');
      expect(updated.postLimitCount, 20);
      expect(updated.postLimitPeriod, model.postLimitPeriod);
      expect(updated.createdAt, model.createdAt);
      expect(updated.updatedAt, model.updatedAt);
    });

    test('copyWith with no arguments returns equal instance', () {
      final model = PartnershipModel.fromJson(sampleJson);
      final copy = model.copyWith();

      expect(copy, equals(model));
      expect(identical(copy, model), isFalse);
    });

    test('equality works correctly', () {
      final model1 = PartnershipModel.fromJson(sampleJson);
      final model2 = PartnershipModel.fromJson(sampleJson);

      expect(model1, equals(model2));
      expect(model1.hashCode, equals(model2.hashCode));
    });

    test('inequality when fields differ', () {
      final model1 = PartnershipModel.fromJson(sampleJson);
      final model2 = model1.copyWith(status: 'approved');

      expect(model1, isNot(equals(model2)));
    });

    test('accepts all valid status values', () {
      for (final status in ['pending', 'approved', 'rejected']) {
        final json = Map<String, dynamic>.from(sampleJson)
          ..['status'] = status;
        final model = PartnershipModel.fromJson(json);
        expect(model.status, status);
      }
    });

    test('accepts all valid postLimitPeriod values', () {
      for (final period in ['month', 'year']) {
        final json = Map<String, dynamic>.from(sampleJson)
          ..['post_limit_period'] = period;
        final model = PartnershipModel.fromJson(json);
        expect(model.postLimitPeriod, period);
      }
    });
  });
}
