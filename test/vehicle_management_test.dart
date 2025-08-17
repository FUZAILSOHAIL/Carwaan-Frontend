import 'package:flutter_test/flutter_test.dart';
import 'package:carwaan/src/core/models/vehicle.dart';

void main() {
  group('Vehicle Model Tests', () {
    test('should calculate available seats correctly', () {
      final vehicle = Vehicle(
        id: '1',
        userId: 'user123',
        make: 'Toyota',
        model: 'Corolla',
        year: '2023',
        color: 'White',
        licensePlate: 'ABC123',
        type: VehicleType.sedan,
        totalSeats: 5,
        fuelAverage: 15.0,
        createdAt: DateTime.now(),
      );

      expect(vehicle.availableSeats, equals(4));
    });

    test('should handle fuel average default value', () {
      final vehicle = Vehicle(
        id: '1',
        userId: 'user123',
        make: 'Honda',
        model: 'Civic',
        year: '2022',
        color: 'Blue',
        licensePlate: 'XYZ789',
        type: VehicleType.sedan,
        totalSeats: 5,
        createdAt: DateTime.now(),
      );

      expect(vehicle.fuelAverage, equals(10.0));
    });

    test('should serialize to JSON correctly', () {
      final vehicle = Vehicle(
        id: '1',
        userId: 'user123',
        make: 'Toyota',
        model: 'Corolla',
        year: '2023',
        color: 'White',
        licensePlate: 'ABC123',
        type: VehicleType.sedan,
        totalSeats: 5,
        fuelAverage: 15.0,
        createdAt: DateTime.now(),
      );

      final json = vehicle.toJson();
      
      expect(json['make'], equals('Toyota'));
      expect(json['model'], equals('Corolla'));
      expect(json['seating_capacity'], equals(5));
      expect(json['fuel_average'], equals(15.0));
      expect(json['license_plate'], equals('ABC123'));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': '1',
        'owner': 'user123',
        'make': 'Toyota',
        'model': 'Corolla',
        'year': '2023',
        'color': 'White',
        'license_plate': 'ABC123',
        'vehicle_type': 'sedan',
        'seating_capacity': 5,
        'fuel_average': 15.0,
        'created_at': '2023-12-01T10:00:00Z',
      };

      final vehicle = Vehicle.fromJson(json);
      
      expect(vehicle.make, equals('Toyota'));
      expect(vehicle.model, equals('Corolla'));
      expect(vehicle.totalSeats, equals(5));
      expect(vehicle.availableSeats, equals(4));
      expect(vehicle.fuelAverage, equals(15.0));
      expect(vehicle.licensePlate, equals('ABC123'));
      expect(vehicle.type, equals(VehicleType.sedan));
    });
  });
}
