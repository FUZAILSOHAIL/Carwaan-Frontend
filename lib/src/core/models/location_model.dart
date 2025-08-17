import 'package:latlong2/latlong.dart';

class LocationData {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? area;
  final String? city;
  final String? urduName;

  const LocationData({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.area,
    this.city,
    this.urduName,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      area: json['area'],
      city: json['city'],
      urduName: json['urduName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'area': area,
      'city': city,
      'urduName': urduName,
    };
  }

  LatLng get latLng => LatLng(latitude, longitude);

  LocationData copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? area,
    String? city,
    String? urduName,
  }) {
    return LocationData(
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      area: area ?? this.area,
      city: city ?? this.city,
      urduName: urduName ?? this.urduName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationData &&
        other.name == name &&
        other.address == address &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.area == area &&
        other.city == city &&
        other.urduName == urduName;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        address.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        area.hashCode ^
        city.hashCode ^
        urduName.hashCode;
  }

  @override
  String toString() {
    return area != null ? '$name, $area' : name;
  }
}

class PlaceSearchResult {
  final String placeId;
  final String name;
  final String description;
  final double? latitude;
  final double? longitude;

  const PlaceSearchResult({
    required this.placeId,
    required this.name,
    required this.description,
    this.latitude,
    this.longitude,
  });

  factory PlaceSearchResult.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  LocationData toLocationData() {
    return LocationData(
      name: name,
      address: description,
      latitude: latitude ?? 0.0,
      longitude: longitude ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaceSearchResult &&
        other.placeId == placeId &&
        other.name == name &&
        other.description == description &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode {
    return placeId.hashCode ^
        name.hashCode ^
        description.hashCode ^
        latitude.hashCode ^
        longitude.hashCode;
  }
}
