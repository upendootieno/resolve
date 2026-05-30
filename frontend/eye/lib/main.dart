import 'package:flutter/material.dart';

void main() {
  runApp(const EyeApp());
}

class EyeApp extends StatelessWidget {
  const EyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VisionCare',
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
            const _TopBar(title: 'VisionCare'),
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
              onPressed: () {},
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
                    onPressed: () {},
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

class ClinicsPage extends StatelessWidget {
  const ClinicsPage({super.key});

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
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 30, color: primary),
                hintText: 'Find nearby clinics',
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
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary, width: 3),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCMZ4THjVrO577_60OXDe_K-XWlmb4-P20uDmHUh3TrZ4wPocI6iJr_2Iovr0k7RHiJl_ly9nrzqJbe2Xv-yhufWxiRzcdESXRBLll7wtiS47MPUnWPwtpQwxDmxfV_gy7vscZVdxAUWG-JKa0Hbf7KDCZXiDgyaY-MTCt8TbyrvoS27i2IHMVXUE5ctem9WSir34fhSro04mRaxbpctbnmZmHQSE7MXc--wpKruQAzzChahbzrveaEBCx28mKnm_5OXYdtveaolmQ',
                  ),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
                ),
              ),
              child: Center(
                child: FilledButton.icon(
                  onPressed: () {},
                  style: FilledButton.styleFrom(backgroundColor: primary),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Show map view'),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Nearby Recommendations',
              style: TextStyle(
                color: primary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const _ClinicCard(
              name: 'Central Eye Clinic',
              distance: '0.5 miles away',
              status: 'Open now',
              price: r'$45.00',
              tag: 'Cheapest in your area for this service',
              progress: 0.33,
            ),
            const SizedBox(height: 14),
            const _ClinicCard(
              name: 'Vision Center',
              distance: '1.2 miles away',
              status: 'Closes at 6 PM',
              price: r'$62.00',
              tag: 'Premium facility with shortest wait times',
              progress: 0.66,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 66),
                side: const BorderSide(color: primary, width: 3),
              ),
              icon: const Icon(Icons.list, color: primary),
              label: const Text(
                'View 12 more clinics',
                style: TextStyle(
                  color: primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
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
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF003366), width: 2),
        foregroundColor: const Color(0xFF003366),
      ),
      child: Text(text),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({
    required this.name,
    required this.distance,
    required this.status,
    required this.price,
    required this.tag,
    required this.progress,
  });

  final String name;
  final String distance;
  final String status;
  final String price;
  final String tag;
  final double progress;

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
                  children: [
                    const Expanded(
                      child: Text(
                        'Standard Check-up',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: primary,
                  backgroundColor: const Color(0xFFD1E3F8),
                ),
                const SizedBox(height: 8),
                Text(
                  tag,
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
            const _MedCard(name: 'Latanoprost', schedule: 'Nightly', dose: '1 drop nightly'),
            const SizedBox(height: 12),
            const _MedCard(name: 'Timolol', schedule: 'Twice Daily', dose: '1 drop morning/night'),
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
                  FilledButton(onPressed: null, child: Text('Order Now')),
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
  const _MedCard({required this.name, required this.schedule, required this.dose});

  final String name;
  final String schedule;
  final String dose;

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
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Log Dose'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
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

class TrackerPage extends StatelessWidget {
  const TrackerPage({super.key});

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
              onPressed: () {},
              icon: const Icon(Icons.add_circle, size: 34),
              label: const Text('Add New Reading', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Text('Recent Readings', style: TextStyle(color: primary, fontSize: 28, fontWeight: FontWeight.w700)),
                Spacer(),
                Text('View All', style: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            const _ReadingCard(value: '12.1 mmHg', time: 'Today, 08:30 AM', icon: Icons.water_drop),
            const SizedBox(height: 12),
            const _ReadingCard(value: '14.0 mmHg', time: 'Yesterday, 09:15 PM', icon: Icons.water_drop),
            const SizedBox(height: 12),
            const _ReadingCard(
              value: '16.5 mmHg',
              time: 'Oct 26, 07:45 AM',
              icon: Icons.warning,
              highlighted: true,
            ),
            const SizedBox(height: 12),
            const _ReadingCard(value: '14.5 mmHg', time: 'Oct 25, 08:20 AM', icon: Icons.water_drop),
            const SizedBox(height: 18),
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

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF004A77);

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
                children: [
                  _tab('All Messages', true),
                  const SizedBox(width: 8),
                  _tab('Community', false),
                  const SizedBox(width: 8),
                  _tab('Alerts', false),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
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
            const SizedBox(height: 14),
            const _MessageItem(
              title: 'Dr. Smith (Follow-up)',
              time: '10:24 AM',
              body:
                  'The results from your visual field test look promising. Let\'s discuss your next steps during our call tomorrow.',
              leadingImage:
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuD0GDso6a2JbaTFI5jkTZxUCXr19WvmKq6wzUt45C8k6E5HSB7BghWAkxRgRuov-xxT4LCXAIrFXygGgeaYHez_hLHKzA6DtlQe8g0BxY0SMxKB70S88oW_d1eWYooNfV88SmbKBYnteO7a8KIVZD2H3SRoBiOmTQzRjofxYypNoFIJpahc5A0K1D9vYlNJFfRT-JLMEYYR9ueKyrtt89OyZeWw2xcxvXAnHD5cNP4h1RvXtkKtOJ_bSlCOaN9SarYITth8aHYqpuE',
            ),
            const SizedBox(height: 10),
            const _MessageItem(
              title: 'Care Team (Appointment Confirmed)',
              time: 'Yesterday',
              body: 'Your annual eye exam is scheduled for Tuesday, Oct 24 at 9:15 AM at Central Vision Clinic.',
              icon: Icons.medical_services,
            ),
            const SizedBox(height: 10),
            const _MessageItem(
              title: 'Support Group (Weekly Q&A)',
              time: 'Mon',
              body: 'New topic: Managing light sensitivity at night. What are your best tips for evening walks?',
              icon: Icons.groups,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {},
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

  Widget _tab(String text, bool selected) {
    return DecoratedBox(
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
            onPressed: () {},
            icon: const Icon(Icons.settings, color: primary),
          ),
        ],
      ),
    );
  }
}
