// Same imports as before
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Responsive Drag Pin Location Picker',
      debugShowCheckedModeBanner: false,
      home: LocationPickerScreen(),
    );
  }
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedLocation = LatLng(17.4239, 78.4483);
  Point<double>? _markerScreenPos;
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  String _selectedAddress = 'Fetching address...';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    await Permission.location.request();
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_selectedLocation, 16);
    _updateMarkerScreenPosition();
    _fetchAddress(_selectedLocation);
  }

  void _updateMarkerScreenPosition() {
    final pos = _mapController.latLngToScreenPoint(_selectedLocation);
    setState(() {
      _markerScreenPos = pos;
    });
  }

  Future<void> _fetchAddress(LatLng latLng) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${latLng.latitude}&lon=${latLng.longitude}';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'flutter-location-picker-app',
      });
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedAddress = data['display_name'] ?? 'Unknown address';
        });
      } else {
        setState(() {
          _selectedAddress = 'Unable to fetch address';
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = 'Error fetching address';
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });

    final url =
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5';

    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'flutter-location-picker-app'
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data.map((item) {
          return SearchResult(
            displayName: item['display_name'],
            lat: double.parse(item['lat']),
            lon: double.parse(item['lon']),
          );
        }).toList();

        setState(() {
          _searchResults = results;
        });
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(SearchResult result) {
    final newLocation = LatLng(result.lat, result.lon);
    setState(() {
      _selectedLocation = newLocation;
      _searchResults = [];
      _searchController.text = result.displayName;
    });
    _mapController.move(newLocation, 16);
    _updateMarkerScreenPosition();
    _fetchAddress(newLocation);
  }

  void _handleMapTap(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
      _searchController.clear();
      _searchResults.clear();
    });
    _updateMarkerScreenPosition();
    _fetchAddress(latLng);
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;
          final iconSize = isDesktop ? 50.0 : 40.0;
          final textSize = isDesktop ? 16.0 : 12.0;
          final cardWidth = isDesktop ? 320.0 : 280.0;
          final pinOffsetY = isDesktop ? 90.0 : 70.0;

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _selectedLocation,
                  zoom: 16,
                  onTap: (tapPosition, latLng) => _handleMapTap(latLng),
                  onPositionChanged: (mapPosition, hasGesture) {
                    _updateMarkerScreenPosition();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation,
                        width: iconSize + 10,
                        height: iconSize + 10,
                        builder: (ctx) => Draggable(
                          feedback: Icon(Icons.location_on,
                              color: Colors.teal, size: iconSize),
                          childWhenDragging: Container(),
                          onDragEnd: (details) {
                            final RenderBox box =
                                context.findRenderObject() as RenderBox;
                            final Offset offset =
                                box.globalToLocal(details.offset);
                            final latLng = _mapController.pixelToLatLng(
                              CustomPoint(offset.dx, offset.dy),
                              context,
                            );
                            setState(() {
                              _selectedLocation = latLng;
                              _searchController.clear();
                              _searchResults.clear();
                            });
                            _updateMarkerScreenPosition();
                            _fetchAddress(latLng);
                          },
                          child: Icon(Icons.location_on,
                              color: Colors.teal, size: iconSize),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Top Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    top: padding.top + 12,
                    left: 12,
                    right: 12,
                    bottom: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back, color: Colors.black),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Select Pickup Location',
                          style: TextStyle(
                              fontSize: textSize + 4,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                        ),
                      ),
                      Opacity(opacity: 0, child: Icon(Icons.arrow_back)),
                    ],
                  ),
                ),
              ),

              // Search box
              Positioned(
                top: padding.top + 70,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6)
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: textSize),
                        decoration: InputDecoration(
                          hintText: 'Search Location',
                          border: InputBorder.none,
                          icon: Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchResults.clear();
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: _searchLocation,
                      ),
                    ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        constraints: BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 6)
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => Divider(height: 1),
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              title: Text(
                                result.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: textSize),
                              ),
                              onTap: () => _selectSearchResult(result),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // Marker overlay
              if (_markerScreenPos != null)
                Positioned(
                  left: (_markerScreenPos!.x - cardWidth / 2)
                      .clamp(16, constraints.maxWidth - cardWidth - 16),
                  top: _markerScreenPos!.y - pinOffsetY,
                  child: Container(
                    width: cardWidth,
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Your order will be picked here\nPlace the pin accurately on the map',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white, fontSize: textSize - 2),
                    ),
                  ),
                ),

              // Bottom address card
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(blurRadius: 8, color: Colors.black12)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_pin, color: Colors.black),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedAddress,
                              style: TextStyle(fontSize: textSize),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text('Change',
                                style: TextStyle(fontSize: textSize)),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          print("Selected: $_selectedLocation");
                          print("Address: $_selectedAddress");
                        },
                        child: Text('Confirm Location',
                            style: TextStyle(fontSize: textSize)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension on MapController {
  LatLng pixelToLatLng(CustomPoint point, BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final localPoint = CustomPoint(
      point.x - box.size.width / 2,
      point.y - box.size.height / 2,
    );
    return center;
  }
}

class SearchResult {
  final String displayName;
  final double lat;
  final double lon;

  SearchResult({
    required this.displayName,
    required this.lat,
    required this.lon,
  });
}
