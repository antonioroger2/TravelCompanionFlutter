import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:thingqbator/home_page.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'TripPlanner.dart';

void main() {
  runApp(const ExplorePage());
}

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Explorer',
      theme: ThemeData().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
        cardColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1E88E5),
          secondary: Color(0xFF64B5F6),
        ),
      ),
      home: const MapExplorerScreen(),
    );
  }
}

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  final Random _random = Random();

  static const String _apiKey = '492cdff6b79e46adb5938059495eacc9';
  static const String _flaskServerUrl = 'http://68.178.238.26:8000/scrape';

  List<Map<String, dynamic>> _searchResults = [];
  Marker? _currentMarker;
  bool _showInfoCard = false;
  Timer? _debounceTimer;

  String _locationName = '';
  String _locationCoordinates = '';
  String _country = '';
  String _currency = '';
  String _timezone = '';
  String _roadInfo = '';
  String _flag = '';
  String _sunrise = '';
  String _sunset = '';
  String _dms = '';
  String _fips = '';
  String _mgrs = '';
  String _maidenhead = '';
  String _geohash = '';
  String _qibla = '';
  String _callingCode = '';
  String _what3words = '';
  String _travelAlert = 'Loading...';

  static const List<Map<String, dynamic>> _majorCities = [
    {'name': 'Tokyo', 'lat': 35.6762, 'lon': 139.6503},
    {'name': 'New York', 'lat': 40.7128, 'lon': -74.0060},
    {'name': 'London', 'lat': 51.5074, 'lon': -0.1278},
    {'name': 'Paris', 'lat': 48.8566, 'lon': 2.3522},
    {'name': 'Dubai', 'lat': 25.2048, 'lon': 55.2708},
    {'name': 'Singapore', 'lat': 1.3521, 'lon': 103.8198},
    {'name': 'Sydney', 'lat': -33.8688, 'lon': 151.2093},
    {'name': 'Rio de Janeiro', 'lat': -22.9068, 'lon': -43.1729},
    {'name': 'Cape Town', 'lat': -33.9249, 'lon': 18.4241},
    {'name': 'Moscow', 'lat': 55.7558, 'lon': 37.6173},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _randomLocation() {
    final city = _majorCities[_random.nextInt(_majorCities.length)];
    final lat = city['lat'] + (_random.nextDouble() - 0.5) * 0.1;
    final lon = city['lon'] + (_random.nextDouble() - 0.5) * 0.1;
    _reverseGeocode(LatLng(lat, lon));
  }

  void _zoomIn() {
    final currentZoom = _mapController.zoom;
    _mapController.move(_mapController.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.zoom;
    _mapController.move(_mapController.center, currentZoom - 1);
  }

  Future<void> _fetchTravelAlert(String city) async {
    try {
      final response = await http.post(
        Uri.parse(_flaskServerUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'city': city}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _travelAlert = data['content'] ?? 'No travel alert available.';
        });
      } else {
        setState(() {
          _travelAlert = 'Failed to fetch travel alert.';
        });
      }
    } catch (e) {
      setState(() {
        _travelAlert = 'Error fetching travel alert: $e';
      });
    }
  }

  Future<void> _handleSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.opencagedata.com/geocode/v1/json?q=${Uri.encodeComponent(query)}&key=$_apiKey&limit=5'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() =>
            _searchResults = List<Map<String, dynamic>>.from(data['results']));
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
  }

  void _updateMap(double lat, double lng, String name, dynamic details) {
    if (!mounted) return;

    setState(() {
      _currentMarker = Marker(
        point: LatLng(lat, lng),
        builder: (ctx) =>
            const Icon(Icons.location_pin, color: Colors.red, size: 40),
      );

      _locationName = 'Location: $name';
      _locationCoordinates =
          'Coordinates: ${lat.toStringAsFixed(6)}°, ${lng.toStringAsFixed(6)}°';
      _country = 'Country: ${_getNestedValue(details, [
                'components',
                'country'
              ]) ?? 'Unknown'}';
      _currency = _formatCurrency(details);
      _timezone = 'Timezone: ${_getNestedValue(details, [
                'annotations',
                'timezone',
                'name'
              ]) ?? 'Unknown'}';
      _sunrise = _formatSunTime(details, 'rise');
      _sunset = _formatSunTime(details, 'set');

      _dms = _formatDMS(details);
      _mgrs = 'MGRS: ${_getNestedValue(details, [
                'annotations',
                'MGRS'
              ]) ?? 'Unknown'}';
      _maidenhead = 'Maidenhead: ${_getNestedValue(details, [
                'annotations',
                'Maidenhead'
              ]) ?? 'Unknown'}';
      _geohash = 'Geohash: ${_getNestedValue(details, [
                'annotations',
                'geohash'
              ]) ?? 'Unknown'}';
      _qibla = 'Qibla: ${_getNestedValue(details, [
                'annotations',
                'qibla'
              ])?.toString() ?? 'Unknown'}°';
      _callingCode = 'Calling Code: ${_getNestedValue(details, [
                'annotations',
                'callingcode'
              ]) ?? 'Unknown'}';
      _what3words = 'What3Words: ${_getNestedValue(details, [
                'annotations',
                'what3words',
                'words'
              ]) ?? 'Unknown'}';

      _showInfoCard = true;
      _searchResults = [];
    });

    _mapController.move(LatLng(lat, lng), 9);
    _fetchTravelAlert(name);
  }

  String? _getNestedValue(dynamic obj, List<String> keys) {
    dynamic current = obj;
    for (final key in keys) {
      if (current is! Map || !current.containsKey(key)) return null;
      current = current[key];
    }
    return current?.toString();
  }

  String _formatCurrency(dynamic details) {
    final name = _getNestedValue(details, ['annotations', 'currency', 'name']);
    final symbol =
        _getNestedValue(details, ['annotations', 'currency', 'symbol']);
    return 'Currency: ${name ?? 'Unknown'} ${symbol != null ? '($symbol)' : ''}';
  }

  String _formatSunTime(dynamic details, String type) {
    final timestamp =
        _getNestedValue(details, ['annotations', 'sun', type, 'apparent']);
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime =
          DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
      return '${type.capitalize()}: ${dateTime.toLocal()}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatDMS(dynamic details) {
    final lat = _getNestedValue(details, ['annotations', 'DMS', 'lat']);
    final lng = _getNestedValue(details, ['annotations', 'DMS', 'lng']);
    return 'DMS: ${lat ?? 'Unknown'}, ${lng ?? 'Unknown'}';
  }

  void _debouncedSearch(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _handleSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: const LatLng(22.0, 78.0),
                minZoom: 2.0,
                maxZoom: 18,
                onTap: (_, pos) => _reverseGeocode(pos),
                interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                bounds: LatLngBounds(
                  LatLng(-85.0, -180.0),
                  LatLng(85.0, 180.0),
                ),
                onPositionChanged: (MapPosition position, bool hasGesture) {
                  if (position.zoom != null && position.zoom! <= 2) {
                    final newCenter =
                        position.center ?? const LatLng(0.0, 78.0);
                    _mapController.move(
                        LatLng(0, newCenter.longitude), position.zoom!);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.map_explorer',
                ),
                if (_currentMarker != null)
                  MarkerLayer(
                    markers: [_currentMarker!],
                  ),
              ],
            ),
            _buildSearchBar(),
            if (_searchResults.isNotEmpty) _buildSearchResults(),
            _buildControls(),
            if (_showInfoCard) _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade200.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
              ),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for a location...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                  filled: true,
                  fillColor: Colors.blueGrey.shade200.withOpacity(0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        const BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.search,
                      color: Color.fromARGB(255, 255, 255, 255)),
                ),
                onChanged: _debouncedSearch,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Positioned(
      top: 76,
      left: 16,
      right: 16,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        color: Colors.blueGrey.shade200.withOpacity(0.9),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final result = _searchResults[index];
            return ListTile(
              title: Text(
                result['formatted'] ?? 'Unknown location',
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () {
                _searchController.text = result['formatted'] ?? '';
                final geometry = result['geometry'];
                if (geometry != null) {
                  _updateMap(
                    (geometry['lat'] as num).toDouble(),
                    (geometry['lng'] as num).toDouble(),
                    result['formatted'] ?? 'Unknown location',
                    result,
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      right: 16,
      bottom: _showInfoCard ? 650 : 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'zoomIn',
            onPressed: _zoomIn,
            backgroundColor: Colors.blueAccent.withOpacity(0.8),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoomOut',
            onPressed: _zoomOut,
            backgroundColor: Colors.blueAccent.withOpacity(0.8),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'random',
            onPressed: _randomLocation,
            backgroundColor: Colors.blueAccent.withOpacity(0.8),
            child: const Icon(Icons.shuffle),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        color: Colors.blueAccent.withOpacity(0.6),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoCardHeader(),
              const SizedBox(height: 8),
              _buildLocationInfo(),
              _buildTravelAlert(),
              _buildTechnicalInfo(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCardHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _locationName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: '',
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => setState(() => _showInfoCard = false),
        ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    final locationInfo = [
      _locationCoordinates,
      _country,
      _currency,
      _timezone,
      _sunrise,
      _sunset,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: locationInfo
          .map((info) => Text(
                info,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ))
          .toList(),
    );
  }

  Widget _buildTravelAlert() {
    return GestureDetector(
      onTap: () => _showTravelAlertDialog(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            '🚨 Travel Alert:',
            style: TextStyle(
              color: Color.fromARGB(255, 255, 55, 55),
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _travelAlert,
            style: const TextStyle(
              fontSize: 15,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Text(
            'Tap to view more...',
            style: TextStyle(
              color: Color.fromARGB(255, 255, 255, 255),
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalInfo() {
    final technicalInfo = [
      _dms,
      _mgrs,
      _maidenhead,
      _geohash,
      _qibla,
      _callingCode,
      _what3words,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: technicalInfo
          .map((info) => Text(
                info,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ))
          .toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            final locationData = {
              'destination': _locationName.replaceAll('Location: ', ''),
              'coordinates': {
                'lat': _currentMarker?.point.latitude,
                'lng': _currentMarker?.point.longitude,
              },
              'country': _country.replaceAll('Country: ', ''),
              'travelAlert': _travelAlert,
            };

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TripPlanner(locationData: locationData),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Plan A Trip',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Using our state-of-the-art AI Planner',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  void _showTravelAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFf8fafc),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Text(
          'Travel Alert',
          style: TextStyle(
            color: const Color.fromARGB(255, 255, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          "$_country ! " + _travelAlert,
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 0, 0),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() {
      _travelAlert = "Loading...";
    });
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.opencagedata.com/geocode/v1/json?q=${pos.latitude}+${pos.longitude}&key=$_apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final result = data['results'][0];
          _updateMap(pos.latitude, pos.longitude,
              result['formatted'] ?? 'Unknown location', result);
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
