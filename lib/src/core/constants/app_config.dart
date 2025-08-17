class AppConfig {
  static const String appName = 'Carwaan';
  // static const String baseUrl = 'http://127.0.0.1:8000'; // Local Django server
  static const String baseUrl = 'http://192.168.100.32:8000'; // Fuzail's IP
  // static const String baseUrl = 'http://10.143.228.181:8000'; // Updated with your actual IP
  // static const String baseUrl = 'http://192.168.100.57:8000'; //Hassan's IP
  static const String apiVersion = '/api/v1';
  static const String apiUrl = '$baseUrl$apiVersion';
  
  // Fare Configuration
  static const double baseFareRate = 30.0; // Rs. per km
  static const double peakHourMultiplier = 2.0;
  
  // Peak Hours (24-hour format)
  static const List<int> morningPeakStart = [8, 0]; // 8:00 AM
  static const List<int> morningPeakEnd = [10, 0];   // 10:00 AM
  static const List<int> eveningPeakStart = [17, 0]; // 5:00 PM
  static const List<int> eveningPeakEnd = [19, 0];   // 7:00 PM
  
  // Karachi Coordinates
  static const double karachiLat = 24.8607;
  static const double karachiLng = 67.0011;
  static const double defaultZoom = 12.0;
  
  // Karachi Areas (English Names)
  static const List<Map<String, dynamic>> karachiAreas = [
    {'name': 'Saddar', 'lat': 24.8615, 'lng': 67.0099, 'area': 'Central Karachi'},
    {'name': 'Gulshan-e-Iqbal', 'lat': 24.9207, 'lng': 67.0682, 'area': 'East Karachi'},
    {'name': 'North Nazimabad', 'lat': 24.9345, 'lng': 67.0361, 'area': 'North Karachi'},
    {'name': 'Clifton', 'lat': 24.8138, 'lng': 67.0299, 'area': 'South Karachi'},
    {'name': 'Defence (DHA)', 'lat': 24.8059, 'lng': 67.0756, 'area': 'South Karachi'},
    {'name': 'Korangi', 'lat': 24.8346, 'lng': 67.1157, 'area': 'East Karachi'},
    {'name': 'Malir', 'lat': 24.8943, 'lng': 67.2094, 'area': 'East Karachi'},
    {'name': 'Landhi', 'lat': 24.8593, 'lng': 67.1564, 'area': 'East Karachi'},
    {'name': 'Shah Faisal Colony', 'lat': 24.8857, 'lng': 67.1429, 'area': 'East Karachi'},
    {'name': 'Orangi Town', 'lat': 24.9441, 'lng': 66.9831, 'area': 'West Karachi'},
    {'name': 'New Karachi', 'lat': 24.9607, 'lng': 67.0734, 'area': 'North Karachi'},
    {'name': 'Federal B Area', 'lat': 24.8951, 'lng': 67.0618, 'area': 'Central Karachi'},
    {'name': 'Johar Town', 'lat': 24.9311, 'lng': 67.1421, 'area': 'East Karachi'},
    {'name': 'Gulistan-e-Johar', 'lat': 24.9146, 'lng': 67.1378, 'area': 'East Karachi'},
    {'name': 'Lyari', 'lat': 24.8700, 'lng': 66.9950, 'area': 'Central Karachi'},
    {'name': 'Keamari', 'lat': 24.8059, 'lng': 66.9783, 'area': 'West Karachi'},
    {'name': 'Baldia Town', 'lat': 24.9288, 'lng': 66.9581, 'area': 'West Karachi'},
    {'name': 'SITE', 'lat': 24.8894, 'lng': 66.9900, 'area': 'West Karachi'},
    {'name': 'North Karachi', 'lat': 24.9888, 'lng': 67.0734, 'area': 'North Karachi'},
    {'name': 'Karachi University Area', 'lat': 24.9470, 'lng': 67.1174, 'area': 'Central Karachi'},
    {'name': 'Nazimabad', 'lat': 24.9125, 'lng': 67.0361, 'area': 'Central Karachi'},
    {'name': 'Liaquatabad', 'lat': 24.8951, 'lng': 67.0361, 'area': 'Central Karachi'},
    {'name': 'Gulberg', 'lat': 24.8951, 'lng': 67.0857, 'area': 'Central Karachi'},
    {'name': 'Tariq Road', 'lat': 24.8951, 'lng': 67.0618, 'area': 'Central Karachi'},
    {'name': 'Bahadurabad', 'lat': 24.8753, 'lng': 67.0618, 'area': 'Central Karachi'},
  ];
}
