import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const EyeApp());
}

class EyeApp extends StatelessWidget {
  const EyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Eye Resolve',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        fontFamily: 'Atkinson Hyperlegible Next',
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void navigateTo(int index) => setState(() => _index = index);

  late final List<Widget> _pages = const [
    HomeDashboardPage(),
    ClinicsPage(),
    MedicationsPage(),
    TrackerPage(),
    InboxPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: _BottomNav(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);
    const muted = Color(0xFF4A627A);

    return Container(
      height: 88,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: primary, width: 3)),
      ),
      child: Row(
        children: [
          _navItem(0, Icons.home, 'Home', primary, muted),
          _navItem(1, Icons.medical_services, 'Clinics', primary, muted),
          _navItem(2, Icons.medication, 'Meds', primary, muted),
          _navItem(3, Icons.monitor_heart, 'Tracker', primary, muted),
          _navItem(4, Icons.inbox, 'Inbox', primary, muted),
        ],
      ),
    );
  }

  Widget _navItem(
    int idx,
    IconData icon,
    String label,
    Color primary,
    Color muted,
  ) {
    final selected = idx == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(idx),
        child: Container(
          decoration: selected
              ? BoxDecoration(
                  border: Border(top: BorderSide(color: primary, width: 6)),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? primary : muted, size: 26),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? primary : muted,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeDashboardPage extends StatelessWidget {
  const HomeDashboardPage({super.key});

  static Future<void> _showLogPressureDialog(BuildContext context) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Log Eye Pressure'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Pressure (mmHg)',
            hintText: 'e.g. 14',
            suffixText: 'mmHg',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pressure reading of $value mmHg saved.')),
      );
      context.findAncestorStateOfType<_MainShellState>()?.navigateTo(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF00326B);
    const secondary = Color(0xFF005FAF);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(title: 'Eye Resolve'),
            const SizedBox(height: 22),
            const Text(
              'Good morning, Patient',
              style: TextStyle(
                color: primary,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your eyes are looking healthy today.',
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x3300326B), width: 4),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.monitor_heart, color: secondary, size: 30),
                      SizedBox(width: 8),
                      Text(
                        "TODAY'S EYE PRESSURE",
                        style: TextStyle(
                          color: secondary,
                          letterSpacing: 1.8,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Text(
                    '14',
                    style: TextStyle(
                      color: primary,
                      fontSize: 78,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'mmHg',
                    style: TextStyle(
                      color: Color(0xFF334155),
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      child: Text(
                        'Normal Range',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Last recorded: 2 hours ago',
                    style: TextStyle(
                      color: Color(0x9900326B),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => HomeDashboardPage._showLogPressureDialog(context),
              icon: const Icon(Icons.add_circle, size: 30),
              label: const Text(
                'Quick Log Pressure',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF004494),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary, width: 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Appointment',
                              style: TextStyle(
                                color: Color(0xFFD6E3FF),
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Tomorrow, 10:00 AM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.event, color: Colors.white, size: 34),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuCwyBhj8DrpTV5SnPkwuhirJH2vroHkHfPBI81SECq3FPBgobZzCwLj8tWjFyLuVpfKIk8nHshlPpQx30VlqS4rRKCbaGPE3TilvgQb91bvao2Est0ZceXYrSl75kLDPihjgK9UsAFCsAl-LOUnJaQZPJY3acGXGSK-Xuj2P-QkYF-SVyaTW7hcspi5BbfgdlMl-8R7SmrOTjySCYGzXputnKYRVd1G9xNRCq9Dx81RYDKWDwma5FEU7b61kyuAVvmg8vjN79ZVQ9k',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. Smith',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Ophthalmologist • Main Clinic',
                                style: TextStyle(
                                  color: Color(0xFFD6E3FF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primary,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    onPressed: () async {
                      final uri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=Central+Eye+Clinic+ophthalmologist',
                      );
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Get Directions'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClinicsPage extends StatefulWidget {
  const ClinicsPage({super.key});

  @override
  State<ClinicsPage> createState() => _ClinicsPageState();
}

class _ClinicsPageState extends State<ClinicsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<_ClinicPlace> _clinics = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String _locationLabel = 'your location';
  String? _selectedSpecialty;

  @override
  void initState() {
    super.initState();
    _loadNearbyClinics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyClinics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _locationLabel = 'your location';
    });

    try {
      final position = await _resolveCurrentPosition();
      final clinics = await _LocationApi.findNearbyClinics(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _clinics = clinics;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      await _loadNearbyClinics();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final target = await _LocationApi.geocodeLocation(query);
      if (target == null) {
        throw Exception('No matching location found for "$query".');
      }

      final clinics = await _LocationApi.findNearbyClinics(
        latitude: target.latitude,
        longitude: target.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _locationLabel = query;
        _clinics = clinics;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<Position> _resolveCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are off. Please enable GPS and retry.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied forever. Update it in settings.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(title: 'Clinics'),
            const SizedBox(height: 22),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchLocation(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 30, color: primary),
                suffixIcon: IconButton(
                  onPressed: _searchLocation,
                  icon: const Icon(Icons.travel_explore, color: primary),
                ),
                hintText: 'Search a town or address',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: primary, width: 3),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: primary, width: 3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary, width: 3),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F3760), Color(0xFF1B6EA9)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Live Search Area',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Showing clinics near $_locationLabel',
                      style: const TextStyle(
                        color: Color(0xFFD2E9FF),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _loadNearbyClinics,
                          style: FilledButton.styleFrom(backgroundColor: Colors.white),
                          icon: const Icon(Icons.my_location, color: primary),
                          label: const Text('Use My Location', style: TextStyle(color: primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Nearby Recommendations',
              style: const TextStyle(
                color: primary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(child: CircularProgressIndicator(color: primary)),
              )
            else if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE49898), width: 2),
                ),
                child: Column(
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFF7B1A1A), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadNearbyClinics,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_clinics.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No clinics found for this area yet.',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 18),
                ),
              )
            else
              ...(_selectedSpecialty == null
                      ? _clinics
                      : _clinics
                          .where(
                            (c) =>
                                c.name.toLowerCase().contains(_selectedSpecialty!.toLowerCase()) ||
                                c.category.toLowerCase().contains(_selectedSpecialty!.toLowerCase()),
                          )
                          .toList())
                  .map(
                (clinic) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ClinicCard(
                    name: clinic.name,
                    distance: clinic.distanceLabel,
                    status: clinic.statusLabel,
                    category: clinic.category,
                    address: clinic.address,
                    onDirections: () => _openDirections(clinic),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'SPECIALIZED CARE',
              style: TextStyle(
                color: primary,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chip('Cataracts'),
                _chip('Glaucoma'),
                _chip('Optometry'),
                _chip('Retina'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    final isSelected = _selectedSpecialty == text;
    return OutlinedButton(
      onPressed: () => setState(() => _selectedSpecialty = isSelected ? null : text),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF003366) : null,
        side: const BorderSide(color: Color(0xFF003366), width: 2),
        foregroundColor: isSelected ? Colors.white : const Color(0xFF003366),
      ),
      child: Text(text),
    );
  }

  Future<void> _openDirections(_ClinicPlace clinic) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${clinic.latitude},${clinic.longitude}',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({
    required this.name,
    required this.distance,
    required this.status,
    required this.category,
    required this.address,
    required this.onDirections,
  });

  final String name;
  final String distance;
  final String status;
  final String category;
  final String address;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA3C4F3), width: 3),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$distance • $status',
                      style: const TextStyle(
                        color: Color(0xFF2B4562),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: primary, size: 34),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA3C4F3)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2B4562),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5E7FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Color(0xFF2B4562)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Color(0xFF2B4562),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Directions'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place, size: 18, color: primary),
                    const SizedBox(width: 6),
                    Text(
                      distance,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicPlace {
  const _ClinicPlace({
    required this.name,
    required this.address,
    required this.category,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
    this.isOpen,
  });

  final String name;
  final String address;
  final String category;
  final double distanceMeters;
  final double latitude;
  final double longitude;
  final bool? isOpen;

  String get distanceLabel {
    final km = distanceMeters / 1000;
    return km < 1 ? '${distanceMeters.toStringAsFixed(0)} m away' : '${km.toStringAsFixed(1)} km away';
  }

  String get statusLabel {
    if (isOpen == true) {
      return 'Open now';
    }

    if (isOpen == false) {
      return 'Currently closed';
    }

    return 'Hours not listed';
  }
}

class _MapPoint {
  const _MapPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class _LocationApi {
  static const _agentHeader = {
    'User-Agent': 'VisionCare/1.0 (location-finder)',
  };

  static Future<_MapPoint?> geocodeLocation(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
    });

    final response = await http.get(uri, headers: _agentHeader);
    if (response.statusCode != 200) {
      throw Exception('Could not search for location right now.');
    }

    final data = jsonDecode(response.body);
    if (data is! List || data.isEmpty) {
      return null;
    }

    final top = data.first;
    final latitude = _numFrom(top['lat']);
    final longitude = _numFrom(top['lon']);
    if (latitude == null || longitude == null) {
      return null;
    }

    return _MapPoint(latitude: latitude, longitude: longitude);
  }

  static Future<List<_ClinicPlace>> findNearbyClinics({
    required double latitude,
    required double longitude,
  }) async {
    final overpassQuery = '''
[out:json][timeout:25];
(
  node["amenity"~"clinic|doctors|hospital|optometrist|ophthalmologist"](around:12000,$latitude,$longitude);
  way["amenity"~"clinic|doctors|hospital|optometrist|ophthalmologist"](around:12000,$latitude,$longitude);
  relation["amenity"~"clinic|doctors|hospital|optometrist|ophthalmologist"](around:12000,$latitude,$longitude);
);
out center 20;
''';

    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      headers: _agentHeader,
      body: {'data': overpassQuery},
    );

    if (response.statusCode != 200) {
      throw Exception('Nearby clinic service is unavailable. Please retry.');
    }

    final body = jsonDecode(response.body);
    final elements = body['elements'];
    if (elements is! List) {
      return const [];
    }

    final clinics = <_ClinicPlace>[];
    for (final element in elements) {
      if (element is! Map<String, dynamic>) {
        continue;
      }

      final tags = element['tags'];
      if (tags is! Map<String, dynamic>) {
        continue;
      }

      final center = element['center'];
      final lat = _numFrom(element['lat']) ?? (center is Map<String, dynamic> ? _numFrom(center['lat']) : null);
      final lon = _numFrom(element['lon']) ?? (center is Map<String, dynamic> ? _numFrom(center['lon']) : null);
      if (lat == null || lon == null) {
        continue;
      }

      final distance = Geolocator.distanceBetween(latitude, longitude, lat, lon);
      final name = (tags['name'] as String?)?.trim();
      final category = (tags['amenity'] as String?)?.replaceAll('_', ' ') ?? 'Clinic';
      final address = _formatAddress(tags);

      clinics.add(
        _ClinicPlace(
          name: (name == null || name.isEmpty) ? 'Eye care provider' : name,
          address: address,
          category: _capitalize(category),
          distanceMeters: distance,
          latitude: lat,
          longitude: lon,
          isOpen: tags['opening_hours'] != null ? null : null,
        ),
      );
    }

    clinics.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return clinics.take(12).toList(growable: false);
  }

  static String _formatAddress(Map<String, dynamic> tags) {
    final house = tags['addr:housenumber'] as String?;
    final street = tags['addr:street'] as String?;
    final city = tags['addr:city'] as String?;
    final area = tags['addr:suburb'] as String?;
    final parts = [house, street, area, city].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'Address not listed';
    }

    return parts.join(', ');
  }

  static String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  static double? _numFrom(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}

class MedicationsPage extends StatelessWidget {
  const MedicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(title: 'Medications'),
            const SizedBox(height: 20),
            const Text(
              'My Active Meds',
              style: TextStyle(color: primary, fontSize: 31, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Keep track of your daily eye care routine and refill alerts.',
              style: TextStyle(color: Color(0xFF334155), fontSize: 19),
            ),
            const SizedBox(height: 16),
            _MedCard(
              name: 'Latanoprost',
              schedule: 'Nightly',
              dose: '1 drop nightly',
              onLog: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('\u2713 Dose logged for Latanoprost')),
              ),
              onRefill: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refill alert set for Latanoprost')),
              ),
            ),
            const SizedBox(height: 12),
            _MedCard(
              name: 'Timolol',
              schedule: 'Twice Daily',
              dose: '1 drop morning/night',
              onLog: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('\u2713 Dose logged for Timolol')),
              ),
              onRefill: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refill alert set for Timolol')),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA3C5FF), width: 2),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Compliance',
                    style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "You've completed 94% of your doses this week. Keep it up!",
                    style: TextStyle(color: Color(0xFFD1E3FF), fontSize: 18),
                  ),
                  SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: 0.94,
                    minHeight: 10,
                    color: Color(0xFFD1E3FF),
                    backgroundColor: Color(0x33FFFFFF),
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '13/14 Doses Done',
                      style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFD1E3FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary, width: 3),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: primary,
                    child: Icon(Icons.warning, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Latanoprost Refill Needed',
                          style: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Approx. 4 days remaining',
                          style: TextStyle(color: primary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pharmacy ordering partner coming soon!')),
                      );
                    },
                    child: const Text('Order Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  const _MedCard({
    required this.name,
    required this.schedule,
    required this.dose,
    required this.onLog,
    required this.onRefill,
  });

  final String name;
  final String schedule;
  final String dose;
  final VoidCallback onLog;
  final VoidCallback onRefill;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  schedule,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1E3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication, color: primary, size: 30),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              name,
              style: const TextStyle(color: primary, fontSize: 29, fontWeight: FontWeight.w800),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              dose,
              style: const TextStyle(color: Color(0xFF334155), fontSize: 19),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: primary),
                  onPressed: onLog,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Log Dose'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRefill,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Refill Alert'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

typedef _Reading = ({String value, String time, bool highlighted, IconData icon});

class _TrackerPageState extends State<TrackerPage> {
  final List<_Reading> _readings = [
    (value: '12.1 mmHg', time: 'Today, 08:30 AM', highlighted: false, icon: Icons.water_drop),
    (value: '14.0 mmHg', time: 'Yesterday, 09:15 PM', highlighted: false, icon: Icons.water_drop),
    (value: '16.5 mmHg', time: 'Oct 26, 07:45 AM', highlighted: true, icon: Icons.warning),
    (value: '14.5 mmHg', time: 'Oct 25, 08:20 AM', highlighted: false, icon: Icons.water_drop),
  ];

  Future<void> _addReading() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('New Pressure Reading'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Pressure (mmHg)',
            hintText: 'e.g. 14',
            suffixText: 'mmHg',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty || !mounted) return;
    final num = double.tryParse(value);
    final isHigh = num != null && num > 21;
    setState(() {
      _readings.insert(0, (
        value: '$value mmHg',
        time: 'Just now',
        highlighted: isHigh,
        icon: isHigh ? Icons.warning : Icons.water_drop,
      ));
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reading of $value mmHg saved.')),
      );
    }
  }

  void _showAllReadings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          children: [
            const Text('All Readings', style: TextStyle(color: Color(0xFF002A5C), fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            ..._readings.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReadingCard(value: r.value, time: r.time, icon: r.icon, highlighted: r.highlighted),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF002A5C);
    const primaryContainer = Color(0xFFD1E3FF);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(title: 'Pressure Tracker'),
            const SizedBox(height: 20),
            const _TrackerTrendCard(),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                minimumSize: const Size(double.infinity, 76),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _addReading,
              icon: const Icon(Icons.add_circle, size: 34),
              label: const Text('Add New Reading', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Recent Readings', style: TextStyle(color: primary, fontSize: 28, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: _showAllReadings,
                  child: const Text(
                    'View All',
                    style: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._readings.take(4).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReadingCard(value: r.value, time: r.time, icon: r.icon, highlighted: r.highlighted),
            )),
            const SizedBox(height: 6),
            Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary, width: 4),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuD526DjZOVL5752p9PAybYnKVCNQoYNcN9E_AS4w9HKjsGgn0LyPbjOyjCmQF0LMlhEoQ7Zxz3kZjDab-WdtWJNS9w-EMQcPk6BCNVrPHhomzhywdSdG0R7edG9bd9wi7Df5qewRo6fRO37hNF_8v3i4qL2W0s0BrIkNYI5_q976xSk7GCLaDnucQpnUeSvsElz9CXplp0wII0wERkSujnxQTb5b8e1yQOkgqMomEaMD_PN0PBX5dgG8aku92q31AiZS-dnKl_dIoQ',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Understanding Pressure',
                      style: TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Why tracking intraocular pressure is vital for your vision.',
                      style: TextStyle(color: primaryContainer, fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackerTrendCard extends StatelessWidget {
  const _TrackerTrendCard();

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF002A5C);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary, width: 4),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7-Day Trend',
                      style: TextStyle(color: primary, letterSpacing: 1.6, fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        text: '14.2 ',
                        style: TextStyle(color: primary, fontSize: 36, fontWeight: FontWeight.w700),
                        children: [
                          TextSpan(
                            text: 'mmHg Avg',
                            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(999)),
                child: const Row(
                  children: [
                    Icon(Icons.trending_down, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text('-2.1%', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const SizedBox(height: 220, child: _TrendChart()),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DayLabel('Mon'),
              _DayLabel('Tue'),
              _DayLabel('Wed'),
              _DayLabel('Thu'),
              _DayLabel('Fri'),
              _DayLabel('Sat'),
              _DayLabel('Sun', active: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ChartPainter(), size: Size.infinite);
  }
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const lineColor = Color(0xFF002A5C);
    const gridColor = Color(0xFFDCE4EF);

    final points = [
      Offset(0.00, 0.56),
      Offset(0.16, 0.72),
      Offset(0.32, 0.38),
      Offset(0.48, 0.78),
      Offset(0.64, 0.62),
      Offset(0.80, 0.67),
      Offset(0.96, 0.88),
    ].map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 2;

    for (var i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = const Color(0x1A002A5C));

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final p in points) {
      canvas.drawCircle(p, 7, Paint()..color = lineColor);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DayLabel extends StatelessWidget {
  const _DayLabel(this.day, {this.active = false});

  final String day;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF002A5C);

    return Text(
      day,
      style: TextStyle(
        color: primary,
        fontSize: 18,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        decoration: active ? TextDecoration.underline : TextDecoration.none,
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.value,
    required this.time,
    required this.icon,
    this.highlighted = false,
  });

  final String value;
  final String time;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF002A5C);
    const primaryContainer = Color(0xFFD1E3FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlighted ? primaryContainer : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary, width: 4),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: highlighted ? primary : primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: highlighted ? Colors.white : primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(color: primary, fontSize: 24, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: primary, size: 30),
        ],
      ),
    );
  }
}

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  int _tabIndex = 0;

  static const _tabs = ['All Messages', 'Community', 'Alerts'];

  void _openMessage(String title, String body) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF004A77), fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text(body, style: const TextStyle(fontSize: 18, height: 1.4)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _composeMessage() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Message', style: TextStyle(color: Color(0xFF004A77), fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Write your message...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    controller.dispose();
                    Navigator.pop(sheetCtx);
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    final text = controller.text.trim();
                    controller.dispose();
                    Navigator.pop(sheetCtx);
                    if (text.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message sent!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF004A77);

    // Determine which content cards are visible per tab
    // Tab 0 = All, Tab 1 = Community, Tab 2 = Alerts/Medical
    final showGroup = _tabIndex == 0 || _tabIndex == 1;
    final showSupport = _tabIndex == 0 || _tabIndex == 1;
    final showMedical = _tabIndex == 0 || _tabIndex == 2;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TopBar(title: 'Inbox'),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (i) => Padding(
                  padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                  child: _tab(_tabs[i], i),
                )),
              ),
            ),
            const SizedBox(height: 14),
            if (showGroup) ...[
              GestureDetector(
                onTap: () => _openMessage(
                  'Support Group (Weekly Q&A)',
                  'Live discussion starts in 2 hours. Join 45 others discussing eye care and glaucoma management.',
                ),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECF1F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7B8C8), width: 2),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        label: Text('Featured Group'),
                        backgroundColor: Color(0xFF005FAF),
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Support Group (Weekly Q&A)',
                        style: TextStyle(color: primary, fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Live discussion starts in 2 hours. Join 45 others.',
                        style: TextStyle(color: Color(0xFF4A627A), fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (showMedical) ...[
              GestureDetector(
                onTap: () => _openMessage(
                  'Dr. Smith (Follow-up)',
                  'The results from your visual field test look promising. Let\'s discuss your next steps during our call tomorrow.',
                ),
                child: const _MessageItem(
                  title: 'Dr. Smith (Follow-up)',
                  time: '10:24 AM',
                  body: 'The results from your visual field test look promising. Let\'s discuss your next steps during our call tomorrow.',
                  leadingImage:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuD0GDso6a2JbaTFI5jkTZxUCXr19WvmKq6wzUt45C8k6E5HSB7BghWAkxRgRuov-xxT4LCXAIrFXygGgeaYHez_hLHKzA6DtlQe8g0BxY0SMxKB70S88oW_d1eWYooNfV88SmbKBYnteO7a8KIVZD2H3SRoBiOmTQzRjofxYypNoFIJpahc5A0K1D9vYlNJFfRT-JLMEYYR9ueKyrtt89OyZeWw2xcxvXAnHD5cNP4h1RvXtkKtOJ_bSlCOaN9SarYITth8aHYqpuE',
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _openMessage(
                  'Care Team (Appointment Confirmed)',
                  'Your annual eye exam is scheduled for Tuesday, Oct 24 at 9:15 AM at Central Vision Clinic.',
                ),
                child: const _MessageItem(
                  title: 'Care Team (Appointment Confirmed)',
                  time: 'Yesterday',
                  body: 'Your annual eye exam is scheduled for Tuesday, Oct 24 at 9:15 AM at Central Vision Clinic.',
                  icon: Icons.medical_services,
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (showSupport)
              GestureDetector(
                onTap: () => _openMessage(
                  'Support Group (Weekly Q&A)',
                  'New topic: Managing light sensitivity at night. What are your best tips for evening walks?',
                ),
                child: const _MessageItem(
                  title: 'Support Group (Weekly Q&A)',
                  time: 'Mon',
                  body: 'New topic: Managing light sensitivity at night. What are your best tips for evening walks?',
                  icon: Icons.groups,
                ),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _composeMessage,
                style: FilledButton.styleFrom(backgroundColor: primary, minimumSize: const Size(180, 60)),
                icon: const Icon(Icons.edit),
                label: const Text('New Message', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(String text, int index) {
    final selected = index == _tabIndex;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF004A77) : const Color(0xFFECF1F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFA7B8C8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF004A77),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  const _MessageItem({
    required this.title,
    required this.time,
    required this.body,
    this.leadingImage,
    this.icon,
  });

  final String title;
  final String time;
  final String body;
  final String? leadingImage;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF004A77);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7B8C8), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leadingImage != null)
            CircleAvatar(radius: 30, backgroundImage: NetworkImage(leadingImage!))
          else
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFD1E3F8),
              child: Icon(icon ?? Icons.mail, color: primary, size: 30),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: primary,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(color: Color(0xFF4A627A), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(color: Color(0xFF4A627A), fontSize: 17, height: 1.3)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: primary, size: 30),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);

    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: primary, width: 3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.visibility, color: primary, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: primary, fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Settings'),
                content: const Text('Profile and app settings coming soon.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.settings, color: primary),
          ),
        ],
      ),
    );
  }
}
