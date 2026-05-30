import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'screens/login_screen.dart';
import 'services/auth_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// ── Push / local notification helper ─────────────────────────────────────────
class _AppNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(settings: const InitializationSettings(android: android, iOS: ios));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> send(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'eye_resolve',
      'Eye Resolve Alerts',
      channelDescription: 'Health reminders and alerts from Eye Resolve',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails()),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _AppNotifications.init();
  runApp(const EyeApp());
}

class EyeApp extends StatefulWidget {
  const EyeApp({super.key});

  @override
  State<EyeApp> createState() => _EyeAppState();
}

// ── Persistent app settings (in-memory; survives widget rebuilds) ─────────────
class _AppSettings {
  const _AppSettings({
    this.primaryColor = const Color(0xFF003366),
    this.fontScale = 1.0,
    this.phoneNumber = '',
    this.patientName = 'Patient',
    this.isLoggedIn = false,
  });

  final Color primaryColor;
  final double fontScale;
  final String phoneNumber;
  final String patientName;
  final bool isLoggedIn;

  _AppSettings copyWith({
    Color? primaryColor,
    double? fontScale,
    String? phoneNumber,
    String? patientName,
    bool? isLoggedIn,
  }) =>
      _AppSettings(
        primaryColor: primaryColor ?? this.primaryColor,
        fontScale: fontScale ?? this.fontScale,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        patientName: patientName ?? this.patientName,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      );
}

final _settingsNotifier = ValueNotifier<_AppSettings>(const _AppSettings());

class _EyeAppState extends State<EyeApp> {
  @override
  void initState() {
    super.initState();
    _settingsNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    _settingsNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = _settingsNotifier.value;
    return MaterialApp(
      navigatorKey: _rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Eye Resolve',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        colorSchemeSeed: s.primaryColor,
      ),
      // Apply font scale globally via MediaQuery so every Text respects it
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(s.fontScale)),
        child: child!,
      ),
      home: s.isLoggedIn
          ? const MainShell()
          : LoginScreen(
              onLoginSuccess: (name) {
                _settingsNotifier.value = _settingsNotifier.value.copyWith(
                  isLoggedIn: true,
                  patientName: name,
                );
                _rootNavigatorKey.currentState?.pushAndRemoveUntil(
                  PageRouteBuilder<void>(
                    pageBuilder: (_, _, _) => const MainShell(),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                  (_) => false,
                );
              },
            ),
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
    final primary = Theme.of(context).colorScheme.primary;
    const muted = Color(0xFF4A627A);

    return Container(
      height: 88,
      decoration: BoxDecoration(
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
            ValueListenableBuilder<_AppSettings>(
              valueListenable: _settingsNotifier,
              builder: (_, s, _) => Text(
                'Good morning, ${s.patientName}',
                style: TextStyle(
                  color: primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
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

  // Eye clinics state
  List<_ClinicPlace> _clinics = const [];
  bool _isLoading = false;
  String? _errorMessage;
  String _locationLabel = 'your location';
  String? _selectedSpecialty;

  // Pharmacies state
  List<_PharmacyPlace> _pharmacies = const [];
  bool _isLoadingPharmacies = false;
  String? _pharmacyError;

  // 0 = Eye Clinics, 1 = Pharmacies
  int _subTab = 0;

  // Cache last resolved coordinates
  double? _lastLat;
  double? _lastLon;

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
      final pos = await _resolveCurrentPosition();
      _lastLat = pos.latitude;
      _lastLon = pos.longitude;
      final clinics = await _LocationApi.findNearbyEyeClinics(latitude: pos.latitude, longitude: pos.longitude);
      if (!mounted) return;
      setState(() { _clinics = clinics; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _errorMessage = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _loadNearbyPharmacies() async {
    setState(() { _isLoadingPharmacies = true; _pharmacyError = null; });
    try {
      double? lat = _lastLat;
      double? lon = _lastLon;
      if (lat == null || lon == null) {
        final pos = await _resolveCurrentPosition();
        _lastLat = lat = pos.latitude;
        _lastLon = lon = pos.longitude;
      }
      final pharmacies = await _LocationApi.findNearbyPharmacies(latitude: lat, longitude: lon);
      if (!mounted) return;
      setState(() { _pharmacies = pharmacies; _isLoadingPharmacies = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingPharmacies = false; _pharmacyError = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      await _loadNearbyClinics();
      return;
    }
    setState(() { _isLoading = true; _isLoadingPharmacies = true; _errorMessage = null; _pharmacyError = null; });
    try {
      final target = await _LocationApi.geocodeLocation(query);
      if (target == null) throw Exception('No matching location found for "$query".');
      _lastLat = target.latitude;
      _lastLon = target.longitude;
      final clinics = await _LocationApi.findNearbyEyeClinics(latitude: target.latitude, longitude: target.longitude);
      final pharmacies = await _LocationApi.findNearbyPharmacies(latitude: target.latitude, longitude: target.longitude);
      if (!mounted) return;
      setState(() {
        _locationLabel = query;
        _clinics = clinics;
        _pharmacies = pharmacies;
        _isLoading = false;
        _isLoadingPharmacies = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() { _isLoading = false; _isLoadingPharmacies = false; _errorMessage = msg; _pharmacyError = msg; });
    }
  }

  Future<Position> _resolveCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Location services are off. Please enable GPS and retry.');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) throw Exception('Location permission denied.');
    if (perm == LocationPermission.deniedForever) throw Exception('Location permission denied forever. Update it in Settings.');
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
  }

  void _showClinicDetail(_ClinicPlace clinic) {
    const primary = Color(0xFF003366);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.92,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(clinic.name, style: const TextStyle(color: primary, fontSize: 22, fontWeight: FontWeight.w800)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFD5E7FF), borderRadius: BorderRadius.circular(999)),
                    child: Text(clinic.category, style: const TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _detailRow(Icons.place, clinic.distanceLabel, primary),
              const SizedBox(height: 6),
              _detailRow(
                Icons.access_time,
                clinic.statusLabel,
                clinic.statusLabel == 'Open now' ? Colors.green.shade700 : primary,
              ),
              if (clinic.address != 'Address not listed') ...[
                const SizedBox(height: 6),
                _detailRow(Icons.home_work, clinic.address, primary),
              ],
              if (clinic.openingHoursRaw != null) ...[
                const SizedBox(height: 6),
                _detailRow(Icons.schedule, clinic.openingHoursRaw!, primary),
              ],
              if (clinic.phone != null) ...[
                const SizedBox(height: 6),
                _detailRow(Icons.phone, clinic.phone!, primary),
              ],
              if (clinic.website != null) ...[
                const SizedBox(height: 6),
                _detailRow(Icons.language, clinic.website!, primary),
              ],
              const SizedBox(height: 22),
              const Divider(),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openDirections(clinic),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: const Size(double.infinity, 52),
                ),
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              if (clinic.phone != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('tel:${clinic.phone}')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: primary, width: 2),
                  ),
                  icon: const Icon(Icons.call, color: primary),
                  label: const Text('Call Clinic', style: TextStyle(color: primary, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
              if (clinic.website != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(clinic.website!), mode: LaunchMode.externalApplication),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: const BorderSide(color: primary, width: 2),
                  ),
                  icon: const Icon(Icons.language, color: primary),
                  label: const Text('Visit Website', style: TextStyle(color: primary, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text, Color color) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600))),
        ],
      );

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
            const SizedBox(height: 14),
            // ── Sub-tab switcher ──
            Row(
              children: [
                _subTabBtn('Eye Clinics', 0, Icons.remove_red_eye, primary),
                const SizedBox(width: 10),
                _subTabBtn('Pharmacies', 1, Icons.local_pharmacy, primary),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchLocation(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 28, color: primary),
                suffixIcon: IconButton(
                  onPressed: _searchLocation,
                  icon: const Icon(Icons.travel_explore, color: primary),
                ),
                hintText: _subTab == 0
                    ? 'Search town or address for eye clinics'
                    : 'Search town or address for pharmacies',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 3)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primary, width: 3)),
              ),
            ),
            const SizedBox(height: 14),
            // ── Map banner ──
            Container(
              height: 160,
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
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _subTab == 0 ? 'Eye Clinics Near You' : 'Pharmacies Near You',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text('Showing results near $_locationLabel',
                        style: const TextStyle(color: Color(0xFFD2E9FF), fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        _loadNearbyClinics();
                        if (_subTab == 1) _loadNearbyPharmacies();
                      },
                      style: FilledButton.styleFrom(backgroundColor: Colors.white),
                      icon: const Icon(Icons.my_location, color: primary, size: 18),
                      label: const Text('Use My Location', style: TextStyle(color: primary)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ═══════════════════════════════════════
            // EYE CLINICS TAB
            // ═══════════════════════════════════════
            if (_subTab == 0) ...[
              const Text('Eye Clinics',
                  style: TextStyle(color: primary, fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Tap a clinic for full details, directions and contact info.',
                  style: TextStyle(color: Color(0xFF4A627A), fontSize: 14)),
              const SizedBox(height: 12),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(child: CircularProgressIndicator(color: primary)),
                )
              else if (_errorMessage != null)
                _errorWidget(_errorMessage!, _loadNearbyClinics, primary)
              else if (_clinics.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No eye clinics found nearby. Try a wider search or different area.',
                    style: TextStyle(color: Color(0xFF334155), fontSize: 17),
                  ),
                )
              else
                ...(_selectedSpecialty == null
                        ? _clinics
                        : _clinics
                            .where((c) =>
                                c.name.toLowerCase().contains(_selectedSpecialty!.toLowerCase()) ||
                                c.category.toLowerCase().contains(_selectedSpecialty!.toLowerCase()))
                            .toList())
                    .map((clinic) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _ClinicCard(
                            name: clinic.name,
                            distance: clinic.distanceLabel,
                            status: clinic.statusLabel,
                            category: clinic.category,
                            address: clinic.address,
                            onDirections: () => _openDirections(clinic),
                            onTap: () => _showClinicDetail(clinic),
                          ),
                        )),
              const SizedBox(height: 20),
              const Text('SPECIALIZED CARE',
                  style: TextStyle(color: primary, letterSpacing: 2.5, fontWeight: FontWeight.w800)),
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

            // ═══════════════════════════════════════
            // PHARMACIES TAB
            // ═══════════════════════════════════════
            if (_subTab == 1) ...[
              Row(
                children: [
                  const Expanded(
                    child: Text('Nearest Pharmacies',
                        style: TextStyle(color: primary, fontSize: 28, fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFD5E7FF), borderRadius: BorderRadius.circular(999)),
                    child: const Row(
                      children: [
                        Icon(Icons.sort, size: 16, color: primary),
                        SizedBox(width: 4),
                        Text('Closest first', style: TextStyle(color: primary, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Sorted by distance. Tap a pharmacy to get directions or call.',
                style: TextStyle(color: Color(0xFF4A627A), fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (_isLoadingPharmacies)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(child: CircularProgressIndicator(color: primary)),
                )
              else if (_pharmacyError != null)
                _errorWidget(_pharmacyError!, _loadNearbyPharmacies, primary)
              else if (_pharmacies.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No pharmacies found nearby. Try searching a different area.',
                    style: TextStyle(color: Color(0xFF334155), fontSize: 17),
                  ),
                )
              else
                ..._pharmacies.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PharmacyCard(pharmacy: p),
                    )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _subTabBtn(String label, int index, IconData icon, Color primary) {
    final sel = _subTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _subTab = index);
          if (index == 1 && _pharmacies.isEmpty && !_isLoadingPharmacies) {
            _loadNearbyPharmacies();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primary, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: sel ? Colors.white : primary, size: 20),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: sel ? Colors.white : primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
            ],
          ),
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

  Widget _errorWidget(String message, VoidCallback onRetry, Color primary) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE49898), width: 2),
        ),
        child: Column(
          children: [
            Text(message, style: const TextStyle(color: Color(0xFF7B1A1A), fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      );

  Future<void> _openDirections(_ClinicPlace clinic) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${clinic.latitude},${clinic.longitude}');
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
    required this.onTap,
  });

  final String name;
  final String distance;
  final String status;
  final String category;
  final String address;
  final VoidCallback onDirections;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
    ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({required this.pharmacy});

  final _PharmacyPlace pharmacy;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${pharmacy.latitude},${pharmacy.longitude}');
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA3C4F3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFD5E7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_pharmacy, color: primary, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pharmacy.name,
                      style: const TextStyle(color: primary, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(pharmacy.address,
                      style: const TextStyle(color: Color(0xFF4A627A), fontSize: 14)),
                  if (pharmacy.openingHoursRaw != null) ...[
                    const SizedBox(height: 2),
                    Text(pharmacy.openingHoursRaw!,
                        style: const TextStyle(color: Color(0xFF4A627A), fontSize: 13)),
                  ],
                  if (pharmacy.phone != null) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.phone, size: 14, color: Color(0xFF4A627A)),
                      const SizedBox(width: 4),
                      Text(pharmacy.phone!,
                          style: const TextStyle(color: Color(0xFF4A627A), fontSize: 13)),
                    ]),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(pharmacy.distanceLabel,
                    style: const TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 6),
                const Icon(Icons.directions, color: primary, size: 22),
              ],
            ),
          ],
        ),
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
    this.phone,
    this.website,
    this.openingHoursRaw,
  });

  final String name;
  final String address;
  final String category;
  final double distanceMeters;
  final double latitude;
  final double longitude;
  final bool? isOpen;
  final String? phone;
  final String? website;
  final String? openingHoursRaw;

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

class _PharmacyPlace {
  const _PharmacyPlace({
    required this.name,
    required this.address,
    required this.distanceMeters,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.openingHoursRaw,
  });

  final String name;
  final String address;
  final double distanceMeters;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? openingHoursRaw;

  String get distanceLabel {
    final km = distanceMeters / 1000;
    return km < 1
        ? '${distanceMeters.toStringAsFixed(0)} m away'
        : '${km.toStringAsFixed(1)} km away';
  }
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

  static Future<List<_ClinicPlace>> findNearbyEyeClinics({
    required double latitude,
    required double longitude,
  }) async {
    final overpassQuery = '''
[out:json][timeout:25];
(
  node["amenity"~"optometrist|ophthalmologist"](around:15000,$latitude,$longitude);
  way["amenity"~"optometrist|ophthalmologist"](around:15000,$latitude,$longitude);
  relation["amenity"~"optometrist|ophthalmologist"](around:15000,$latitude,$longitude);
  node["healthcare"~"optometrist|ophthalmologist"](around:15000,$latitude,$longitude);
  way["healthcare"~"optometrist|ophthalmologist"](around:15000,$latitude,$longitude);
  node["amenity"~"clinic|hospital"]["name"~"eye|vision|optic|ophthal|retina|glaucoma",i](around:15000,$latitude,$longitude);
  way["amenity"~"clinic|hospital"]["name"~"eye|vision|optic|ophthal|retina|glaucoma",i](around:15000,$latitude,$longitude);
  relation["amenity"~"clinic|hospital"]["name"~"eye|vision|optic|ophthal|retina|glaucoma",i](around:15000,$latitude,$longitude);
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
          phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
          website: tags['website'] as String? ?? tags['contact:website'] as String?,
          openingHoursRaw: tags['opening_hours'] as String?,
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

  static Future<List<_PharmacyPlace>> findNearbyPharmacies({
    required double latitude,
    required double longitude,
  }) async {
    final overpassQuery = '''
[out:json][timeout:25];
(
  node["amenity"="pharmacy"](around:10000,$latitude,$longitude);
  way["amenity"="pharmacy"](around:10000,$latitude,$longitude);
);
out center 15;
''';

    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      headers: _agentHeader,
      body: {'data': overpassQuery},
    );

    if (response.statusCode != 200) {
      throw Exception('Pharmacy search is unavailable. Please retry.');
    }

    final body = jsonDecode(response.body);
    final elements = body['elements'];
    if (elements is! List) return const [];

    final pharmacies = <_PharmacyPlace>[];
    for (final element in elements) {
      if (element is! Map<String, dynamic>) continue;
      final tags = element['tags'];
      if (tags is! Map<String, dynamic>) continue;

      final center = element['center'];
      final lat = _numFrom(element['lat']) ?? (center is Map<String, dynamic> ? _numFrom(center['lat']) : null);
      final lon = _numFrom(element['lon']) ?? (center is Map<String, dynamic> ? _numFrom(center['lon']) : null);
      if (lat == null || lon == null) continue;

      final distance = Geolocator.distanceBetween(latitude, longitude, lat, lon);
      final name = (tags['name'] as String?)?.trim();

      pharmacies.add(_PharmacyPlace(
        name: (name == null || name.isEmpty) ? 'Pharmacy' : name,
        address: _formatAddress(tags),
        distanceMeters: distance,
        latitude: lat,
        longitude: lon,
        phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
        openingHoursRaw: tags['opening_hours'] as String?,
      ));
    }

    pharmacies.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return pharmacies.take(15).toList(growable: false);
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
              onLog: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('\u2713 Dose logged for Latanoprost')),
                );
                _AppNotifications.send('Dose Logged \u2713', 'Latanoprost dose recorded. Keep up the routine!');
              },
              onRefill: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refill alert set for Latanoprost')),
                );
                _AppNotifications.send('Refill Reminder Set', 'You will be reminded to refill Latanoprost. Approx. 4 days remaining.');
              },
            ),
            const SizedBox(height: 12),
            _MedCard(
              name: 'Timolol',
              schedule: 'Twice Daily',
              dose: '1 drop morning/night',
              onLog: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('\u2713 Dose logged for Timolol')),
                );
                _AppNotifications.send('Dose Logged \u2713', 'Timolol dose recorded. Keep up the routine!');
              },
              onRefill: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refill alert set for Timolol')),
                );
                _AppNotifications.send('Refill Reminder Set', 'You will be reminded to refill Timolol.');
              },
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
      if (isHigh) {
        _AppNotifications.send(
          '\u26a0 High Eye Pressure Detected',
          'Your reading of $value mmHg exceeds the normal range (\u226421 mmHg). Please contact your doctor.',
        );
      }
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

// ══════════════════════════════════════════════════════════════════════════════
// SETTINGS PAGE
// ══════════════════════════════════════════════════════════════════════════════
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  static const _colorOptions = [
    (label: 'Navy', color: Color(0xFF003366)),
    (label: 'Blue', color: Color(0xFF1565C0)),
    (label: 'Green', color: Color(0xFF2E7D32)),
    (label: 'Purple', color: Color(0xFF6A1B9A)),
    (label: 'Teal', color: Color(0xFF00695C)),
    (label: 'Red', color: Color(0xFFC62828)),
  ];

  static const _fontScales = [
    (label: 'S', scale: 0.85),
    (label: 'M', scale: 1.0),
    (label: 'L', scale: 1.15),
    (label: 'XL', scale: 1.3),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: _settingsNotifier.value.patientName);
    _phoneCtrl = TextEditingController(text: _settingsNotifier.value.phoneNumber);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _update(_AppSettings Function(_AppSettings) fn) {
    _settingsNotifier.value = fn(_settingsNotifier.value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = _settingsNotifier.value;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 24),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: primary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // ── APPEARANCE ──────────────────────────────────────────────────
          _sectionHeader('APPEARANCE', primary),
          const SizedBox(height: 10),
          _settingsCard([
            _settingRow(
              icon: Icons.palette,
              label: 'Theme Color',
              primary: primary,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _colorOptions.map((opt) {
                  final selected = s.primaryColor.toARGB32() == opt.color.toARGB32();
                  return GestureDetector(
                    onTap: () => _update((s) => s.copyWith(primaryColor: opt.color)),
                    child: Tooltip(
                      message: opt.label,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: opt.color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: opt.color.withValues(alpha: 0.55),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check, color: Colors.white, size: 22)
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            _settingRow(
              icon: Icons.text_fields,
              label: 'Font Size',
              primary: primary,
              child: Row(
                children: _fontScales.map((f) {
                  final selected = (s.fontScale - f.scale).abs() < 0.01;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => _update((s) => s.copyWith(fontScale: f.scale)),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: selected ? primary : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primary, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          f.label,
                          style: TextStyle(
                            color: selected ? Colors.white : primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),

          const SizedBox(height: 22),

          // ── PROFILE ─────────────────────────────────────────────────────
          _sectionHeader('PROFILE', primary),
          const SizedBox(height: 10),
          _settingsCard([
            _settingRow(
              icon: Icons.person,
              label: 'Name',
              primary: primary,
              child: _editableField(
                controller: _nameCtrl,
                hint: 'Enter your name',
                primary: primary,
                onSave: () {
                  final name = _nameCtrl.text.trim();
                  _update((s) => s.copyWith(patientName: name.isEmpty ? 'Patient' : name));
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name updated.')),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            _settingRow(
              icon: Icons.phone,
              label: 'Phone Number',
              primary: primary,
              child: _editableField(
                controller: _phoneCtrl,
                hint: 'e.g. +1 555 000 0000',
                primary: primary,
                keyboardType: TextInputType.phone,
                onSave: () {
                  _update((s) => s.copyWith(phoneNumber: _phoneCtrl.text.trim()));
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number updated.')),
                  );
                },
              ),
            ),
          ]),

          const SizedBox(height: 22),

          // ── ACCOUNT ─────────────────────────────────────────────────────
          _sectionHeader('ACCOUNT', primary),
          const SizedBox(height: 10),
          _settingsCard([
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_outline, color: primary),
              ),
              title: Text(
                s.patientName,
                style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              subtitle: Text(
                s.phoneNumber.isEmpty ? 'No phone number set' : s.phoneNumber,
                style: const TextStyle(color: Color(0xFF4A627A)),
              ),
            ),
          ]),
          const SizedBox(height: 14),

          // Log Out button
          FilledButton.icon(
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              _update((s) => s.copyWith(isLoggedIn: false));
              if (context.mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  PageRouteBuilder<void>(
                    pageBuilder: (_, _, _) => LoginScreen(
                      onLoginSuccess: (name) {
                        _settingsNotifier.value =
                            _settingsNotifier.value.copyWith(
                          isLoggedIn: true,
                          patientName: name,
                        );
                      },
                    ),
                    transitionsBuilder: (_, animation, _, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                  (_) => false,
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              minimumSize: const Size(double.infinity, 54),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Log Out', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, Color primary) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(
          label,
          style: TextStyle(
            color: primary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
      );

  Widget _settingsCard(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA3C4F3), width: 2),
        ),
        child: Column(children: children),
      );

  Widget _settingRow({
    required IconData icon,
    required String label,
    required Color primary,
    required Widget child,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: primary),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: primary, fontWeight: FontWeight.w700, fontSize: 16)),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  Widget _editableField({
    required TextEditingController controller,
    required String hint,
    required Color primary,
    required VoidCallback onSave,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: const Color(0xFFF0F4F8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primary, width: 1.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: primary.withValues(alpha: 0.4), width: 1.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primary, width: 2)),
              ),
              onSubmitted: (_) => onSave(),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// LOGIN PAGE
// ══════════════════════════════════════════════════════════════════════════════
class _LoginPage extends StatefulWidget {
  const _LoginPage();

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    _settingsNotifier.value = _settingsNotifier.value.copyWith(isLoggedIn: true);
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const MainShell(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = _settingsNotifier.value.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.visibility, size: 52, color: primary),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Eye Resolve',
                textAlign: TextAlign.center,
                style: TextStyle(color: primary, fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Log in to manage your eye health',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF4A627A), fontSize: 17),
              ),
              const SizedBox(height: 44),
              // Email
              Text('Email',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined, color: primary),
                  hintText: 'you@example.com',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary, width: 2)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary, width: 2)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary, width: 2.5)),
                ),
              ),
              const SizedBox(height: 18),
              // Password
              Text('Password',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 6),
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline, color: primary),
                  hintText: '••••••••',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary, width: 2)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary, width: 2)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primary, width: 2.5)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePass ? Icons.visibility_off : Icons.visibility,
                      color: primary,
                    ),
                    onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _login,
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Log In',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: primary, width: 3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.visibility, color: primary, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: primary, fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
            ),
            icon: Icon(Icons.settings, color: primary),
          ),
        ],
      ),
    );
  }
}
