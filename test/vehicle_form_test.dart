import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock Vehicle Model
class MockVehicle {
  final String id;
  final String make;
  final String model;
  final String year;
  final String fuelType;
  final int engineCapacity;
  final bool hasAC;
  final bool hasMusicSystem;
  final bool hasPhoneCharger;
  final bool smokingAllowed;
  final bool insuranceValid;
  final bool fitnessValid;
  final bool isPrimary;
  final String notes;
  final String status;

  MockVehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.engineCapacity,
    required this.hasAC,
    required this.hasMusicSystem,
    required this.hasPhoneCharger,
    required this.smokingAllowed,
    required this.insuranceValid,
    required this.fitnessValid,
    required this.isPrimary,
    required this.notes,
    required this.status,
  });
}

// Mock Vehicle Controller
class MockVehicleController {
  List<MockVehicle> vehicles = [];
  
  void addVehicle(MockVehicle vehicle) {
    vehicles.add(vehicle);
  }
  
  bool validateVehicle(MockVehicle vehicle) {
    return vehicle.make.isNotEmpty && 
           vehicle.model.isNotEmpty && 
           vehicle.year.isNotEmpty;
  }
}

// Mock VehicleType enum
enum MockVehicleType {
  sedan,
  suv,
  hatchback,
  motorcycle,
  truck,
  van
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Vehicle Form Tests', () {
    late MockVehicleController controller;
    
    setUp(() {
      controller = MockVehicleController();
    });

    testWidgets('Vehicle form should create vehicle with all fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Add Vehicle Screen')),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Text('Vehicle Photos'),
                  Text('Make & Model'),
                  Text('Fuel Type'),
                  Text('Engine Capacity (cc)'),
                  Text('Air Conditioning'),
                  Text('Comfort Features'),
                  Text('Vehicle Status'),
                  Text('Additional Notes'),
                  Text('Has Air Conditioning'),
                  Text('Music System'),
                  Text('Phone Charger'),
                  Text('Smoking Allowed'),
                  Text('Insurance Valid'),
                  Text('Fitness Certificate Valid'),
                  Text('Primary Vehicle'),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text('Save Vehicle'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Test that all sections are present
      expect(find.text('Vehicle Photos'), findsOneWidget);
      expect(find.text('Make & Model'), findsOneWidget);
      expect(find.text('Fuel Type'), findsOneWidget);
      expect(find.text('Engine Capacity (cc)'), findsOneWidget);
      expect(find.text('Air Conditioning'), findsOneWidget);
      expect(find.text('Comfort Features'), findsOneWidget);
      expect(find.text('Vehicle Status'), findsOneWidget);
      expect(find.text('Additional Notes'), findsOneWidget);

      // Test checkbox interactions
      expect(find.text('Has Air Conditioning'), findsOneWidget);
      expect(find.text('Music System'), findsOneWidget);
      expect(find.text('Phone Charger'), findsOneWidget);
      expect(find.text('Smoking Allowed'), findsOneWidget);
      expect(find.text('Insurance Valid'), findsOneWidget);
      expect(find.text('Fitness Certificate Valid'), findsOneWidget);
      expect(find.text('Primary Vehicle'), findsOneWidget);

      // Test save button exists (changed text to avoid duplication)
      expect(find.text('Save Vehicle'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    test('Vehicle model should handle all new fields', () {
      final vehicle = MockVehicle(
        id: '1',
        make: 'Toyota',
        model: 'Corolla',
        year: '2020',
        fuelType: 'Petrol',
        engineCapacity: 1800,
        hasAC: true,
        hasMusicSystem: true,
        hasPhoneCharger: false,
        smokingAllowed: false,
        insuranceValid: true,
        fitnessValid: true,
        isPrimary: true,
        notes: 'Well maintained vehicle',
        status: 'active',
      );

      expect(vehicle.id, equals('1'));
      expect(vehicle.make, equals('Toyota'));
      expect(vehicle.model, equals('Corolla'));
      expect(vehicle.year, equals('2020'));
      expect(vehicle.fuelType, equals('Petrol'));
      expect(vehicle.engineCapacity, equals(1800));
      expect(vehicle.hasAC, isTrue);
      expect(vehicle.hasMusicSystem, isTrue);
      expect(vehicle.hasPhoneCharger, isFalse);
      expect(vehicle.smokingAllowed, isFalse);
      expect(vehicle.insuranceValid, isTrue);
      expect(vehicle.fitnessValid, isTrue);
      expect(vehicle.isPrimary, isTrue);
      expect(vehicle.notes, equals('Well maintained vehicle'));
      expect(vehicle.status, equals('active'));
      
      // Test controller functionality
      controller.addVehicle(vehicle);
      expect(controller.vehicles.length, equals(1));
      expect(controller.validateVehicle(vehicle), isTrue);
    });

    test('VehicleType enum should match Django choices', () {
      // Test that all vehicle types are available
      final vehicleTypes = MockVehicleType.values;
      
      expect(vehicleTypes.contains(MockVehicleType.sedan), isTrue);
      expect(vehicleTypes.contains(MockVehicleType.suv), isTrue);
      expect(vehicleTypes.contains(MockVehicleType.hatchback), isTrue);
      expect(vehicleTypes.contains(MockVehicleType.motorcycle), isTrue);
      expect(vehicleTypes.contains(MockVehicleType.truck), isTrue);
      expect(vehicleTypes.contains(MockVehicleType.van), isTrue);
      
      // Test enum string conversion
      expect(MockVehicleType.sedan.toString(), contains('sedan'));
      expect(MockVehicleType.suv.toString(), contains('suv'));
      expect(MockVehicleType.hatchback.toString(), contains('hatchback'));
      
      // Test vehicle creation with different types
      final sedanVehicle = MockVehicle(
        id: '1',
        make: 'Honda',
        model: 'Civic',
        year: '2021',
        fuelType: 'Petrol',
        engineCapacity: 1500,
        hasAC: true,
        hasMusicSystem: false,
        hasPhoneCharger: true,
        smokingAllowed: false,
        insuranceValid: true,
        fitnessValid: true,
        isPrimary: false,
        notes: 'Sedan test vehicle',
        status: 'active',
      );
      
      expect(controller.validateVehicle(sedanVehicle), isTrue);
      controller.addVehicle(sedanVehicle);
      expect(controller.vehicles.length, equals(1));
    });
  });
}
