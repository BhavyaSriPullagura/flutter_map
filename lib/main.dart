import 'dart:async'; // For Timer (debouncing)
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:math'; // For Point
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

// Initialize logger
final Logger logger = Logger();

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Responsive Location Picker',
      debugShowCheckedModeBanner: false,
      home: LocationPickerScreen(),
    );
  }
}

// --- NEW CUSTOM WIDGET FOR THE BUBBLE ---
class LocationInfoBubble extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color textColor;
  final double bubbleWidth;
  final double triangleHeight;
  final double triangleWidth;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const LocationInfoBubble({
    super.key,
    required this.title,
    required this.subtitle,
    this.backgroundColor = const Color(0xFF2C3A47), // Dark greyish blue
    this.textColor = Colors.white,
    required this.bubbleWidth,
    this.triangleHeight = 10.0,
    this.triangleWidth = 15.0,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: bubbleWidth,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: bubbleWidth,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center, // Center text
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center, // Center align title
                  style:
                      titleStyle ??
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 14, // Slightly larger for title
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center, // Center align subtitle
                  style:
                      subtitleStyle ??
                      TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontSize: 12, // Slightly smaller for subtitle
                      ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -triangleHeight + 0.5, // Slight overlap for clean join
            child: CustomPaint(
              size: Size(triangleWidth, triangleHeight),
              painter: _TrianglePainter(color: backgroundColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;
    final path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
// --- END OF CUSTOM WIDGET ---

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
  bool _isMapReady = false;
  Timer? _fetchAddressDebounce;

  @override
  void initState() {
    super.initState();
    _initLocationPermissionAndFetch();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _fetchAddressDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initLocationPermissionAndFetch() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      logger.w('Location services are disabled.');
      if (mounted) {
        setState(() => _selectedAddress = 'Enable location services.');
        _fetchAddress(_selectedLocation);
        _schedulePostFrameUpdateMarkerPos();
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        logger.w('Location permissions are denied.');
        if (mounted) {
          setState(() => _selectedAddress = 'Location permission denied.');
          _fetchAddress(_selectedLocation);
          _schedulePostFrameUpdateMarkerPos();
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      logger.w('Location permissions are permanently denied.');
      if (mounted) {
        setState(
          () => _selectedAddress = 'Location permission permanently denied.',
        );
        _fetchAddress(_selectedLocation);
        _schedulePostFrameUpdateMarkerPos();
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final newPos = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = newPos);
      if (_isMapReady) {
        _mapController.move(newPos, 16);
      }
      _fetchAddress(newPos);
      _schedulePostFrameUpdateMarkerPos();
    } catch (e) {
      logger.e("Error getting current location: $e");
      if (mounted) {
        setState(() => _selectedAddress = 'Could not get current location.');
        _fetchAddress(_selectedLocation);
        _schedulePostFrameUpdateMarkerPos();
      }
    }
  }

  void _schedulePostFrameUpdateMarkerPos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isMapReady) _updateMarkerScreenPosition();
    });
  }

  void _updateMarkerScreenPosition() {
    if (!_isMapReady || !mounted) return;
    try {
      final Offset screenOffset = _mapController.camera.latLngToScreenOffset(
        _selectedLocation,
      );
      if (mounted) {
        setState(
          () => _markerScreenPos = Point(screenOffset.dx, screenOffset.dy),
        );
      }
    } catch (e) {
      logger.e(
        "Error in _updateMarkerScreenPosition: $e. Pin might be off-screen or map not ready.",
      );
      if (mounted) {
        setState(() => _markerScreenPos = null);
      }
    }
  }

  Future<void> _fetchAddress(LatLng latLng) async {
    if (!mounted) return;
    setState(() => _selectedAddress = 'Fetching address...');

    if (_fetchAddressDebounce?.isActive ?? false) {
      _fetchAddressDebounce!.cancel();
    }
    _fetchAddressDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${latLng.latitude}&lon=${latLng.longitude}';
      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'flutter_map_picker_app/1.0'},
        );
        if (!mounted) return;
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (mounted) {
            setState(
              () =>
                  _selectedAddress = data['display_name'] ?? 'Unknown address',
            );
          }
        } else {
          logger.w(
            "Nominatim reverse geocode error: ${response.statusCode} - ${response.body}",
          );
          if (mounted) {
            setState(() => _selectedAddress = 'Unable to fetch address');
          }
        }
      } catch (e) {
        logger.e("Error fetching address: $e");
        if (!mounted) return;
        setState(() => _selectedAddress = 'Error fetching address');
      }
    });
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    if (mounted) setState(() => _isSearching = true);
    final url =
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'flutter_map_picker_app/1.0'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results =
            data
                .map(
                  (item) => SearchResult(
                    displayName: item['display_name'],
                    lat: double.parse(item['lat']),
                    lon: double.parse(item['lon']),
                  ),
                )
                .toList();
        if (mounted) setState(() => _searchResults = results);
      } else {
        logger.w(
          "Nominatim search error: ${response.statusCode} - ${response.body}",
        );
        if (mounted) setState(() => _searchResults = []);
      }
    } catch (e) {
      logger.e("Error searching location: $e");
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(SearchResult result) {
    final newLocation = LatLng(result.lat, result.lon);
    if (!mounted) return;
    setState(() {
      _selectedLocation = newLocation;
      _searchResults = [];
      _searchController.text = result.displayName;
      _isSearching = false;
    });
    if (_isMapReady) {
      _mapController.move(newLocation, 16);
    }
    _fetchAddress(newLocation);
    _schedulePostFrameUpdateMarkerPos();
  }

  void _handleMapTap(TapPosition? tapPosition, LatLng latLng) {
    if (!mounted || !_isMapReady) return;
    setState(() {
      _selectedLocation = latLng;
      _searchController.clear();
      _searchResults.clear();
    });
    _fetchAddress(latLng);
    _schedulePostFrameUpdateMarkerPos();
  }

  void _handleMarkerDragEnd(
    DraggableDetails details,
    BuildContext mapWidgetContext,
  ) {
    if (!_isMapReady || !mounted) return;

    final RenderBox? mapRenderBox =
        mapWidgetContext.findRenderObject() as RenderBox?;
    if (mapRenderBox == null || !mapRenderBox.hasSize) {
      logger.w("Map renderBox not found in _handleMarkerDragEnd.");
      return;
    }
    final Offset localPositionOnMap = mapRenderBox.globalToLocal(
      details.offset,
    );
    final LatLng newLatLng = _mapController.camera.screenOffsetToLatLng(
      localPositionOnMap,
    );

    if (!mounted) return;
    setState(() {
      _selectedLocation = newLatLng;
      _searchController.clear();
      _searchResults.clear();
    });
    _fetchAddress(newLatLng);
    _schedulePostFrameUpdateMarkerPos();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;
    final screenWidth = mediaQuery.size.width;

    final isDesktop = screenWidth >= 800;
    final iconSize = isDesktop ? 50.0 : 50.0;
    final textSize = isDesktop ? 16.0 : 14.0;
    // final cardWidth = isDesktop ? 350.0 : (screenWidth - 32); // Not used for bubble width directly

    // --- Constants for the custom bubble ---
    final double customBubbleWidth =
        isDesktop ? 260.0 : 290.0; // Adjusted width for the text
    final double triangleHeight = 60.0; // Matches LocationInfoBubble default
    final double estimatedBubbleRectHeight =
        60.0; // ESTIMATE height of the rectangular part of the bubble
    // This is the main value to TUNE for vertical positioning.
    final double desiredGapAbovePin =
        5.0; // Small gap between pin top and triangle tip

    // pinOffsetY calculation for the custom bubble
    // This is the total vertical distance the *top* of the Positioned bubble widget
    // needs to be shifted upwards from the pin's anchor point (_markerScreenPos.y)
    // to make the triangle's tip sit 'desiredGapAbovePin' above the pin's top.
    final double pinOffsetY =
        estimatedBubbleRectHeight + triangleHeight + desiredGapAbovePin;

    final iconColor = Theme.of(context).colorScheme.primary;

    if (_isMapReady) _schedulePostFrameUpdateMarkerPos();

    return Scaffold(
      body: LayoutBuilder(
        builder: (mapLayoutContext, constraints) {
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation,
                  initialZoom: 16,
                  onTap: _handleMapTap,
                  onPositionChanged: (MapCamera mapCamera, bool hasGesture) {
                    if (mounted) {
                      _schedulePostFrameUpdateMarkerPos();
                    }
                  },
                  onMapReady: () {
                    if (mounted) {
                      setState(() => _isMapReady = true);
                      logger.i("Map ready.");
                      _fetchAddress(_selectedLocation);
                      _schedulePostFrameUpdateMarkerPos();
                      if (_mapController.camera.center.latitude !=
                              _selectedLocation.latitude ||
                          _mapController.camera.center.longitude !=
                              _selectedLocation.longitude) {
                        _mapController.move(
                          _selectedLocation,
                          _mapController.camera.zoom,
                        );
                      }
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName:
                        'com.example.flutter_application_1', // Replace
                  ),
                  if (_isMapReady)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: iconSize,
                          height: iconSize,
                          alignment: Alignment.topCenter,
                          child: Draggable(
                            feedback: Icon(
                              Icons.location_on,
                              color: iconColor.withValues(alpha: 0.7),
                              size: iconSize + 10,
                            ),
                            onDragEnd: (details) {
                              _handleMarkerDragEnd(details, mapLayoutContext);
                            },
                            childWhenDragging: SizedBox(
                              width: iconSize,
                              height: iconSize,
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: iconColor,
                              size: iconSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Top Bar (Your existing code - unchanged)
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
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed:
                            () =>
                                Navigator.canPop(context)
                                    ? Navigator.pop(context)
                                    : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Select Pickup Location',
                          style: TextStyle(
                            fontSize: textSize + 2,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search box and results (Your existing code - unchanged)
              Positioned(
                top: padding.top + 65,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    Material(
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(12),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(fontSize: textSize),
                        decoration: InputDecoration(
                          hintText: 'Search Location or Flat No.',
                          border: InputBorder.none,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      if (mounted) {
                                        setState(() {
                                          _searchController.clear();
                                          _searchResults.clear();
                                          _isSearching = false;
                                        });
                                      }
                                    },
                                  )
                                  : null,
                        ),
                        onChanged: _searchLocation,
                      ),
                    ),
                    if (_isSearching)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    if (!_isSearching && _searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder:
                              (_, __) => const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                              ),
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return ListTile(
                              title: Text(
                                result.displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: textSize - 1),
                              ),
                              onTap: () => _selectSearchResult(result),
                              dense: true,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // --- UPDATED OVERLAY TO USE LocationInfoBubble ---
              if (_markerScreenPos != null &&
                  !_isSearching &&
                  _searchResults.isEmpty)
                Positioned(
                  left: _markerScreenPos!.x - (customBubbleWidth / 2),
                  top: _markerScreenPos!.y - pinOffsetY,
                  child: IgnorePointer(
                    child: LocationInfoBubble(
                      title: "Your order will be picked here",
                      subtitle: "Place the pin accurately on the map",
                      bubbleWidth: customBubbleWidth,
                      // You can pass custom text styles if needed
                      // titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      // subtitleStyle: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ),

              // Bottom address card and confirm button (Your existing code - unchanged)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 6.0,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      padding.bottom + 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_pin,
                              color: iconColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Selected Location",
                                    style: TextStyle(
                                      fontSize: textSize - 2,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedAddress,
                                    style: TextStyle(
                                      fontSize: textSize,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            backgroundColor: iconColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: TextStyle(
                              fontSize: textSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            logger.i(
                              "Selected Location: Lat: ${_selectedLocation.latitude}, Lng: ${_selectedLocation.longitude}",
                            );
                            logger.i("Selected Address: $_selectedAddress");
                          },
                          child: const Text('Confirm Location'),
                        ),
                      ],
                    ),
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
