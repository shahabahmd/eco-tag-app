import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const kG1         = Color(0xFF4DBB87);
const kG2         = Color(0xFF7ED6A7);
const kMint       = Color(0xFFEAF7F0);
const kOffWhite   = Color(0xFFF8FBF9);
const kLightGreen = Color(0xFFBFEAD3);
const kTextDark   = Color(0xFF1D3A2C);
const kTextMuted  = Color(0xFF7CA48F);
final kGradient   = const LinearGradient(colors: [kG1, kG2], begin: Alignment.topLeft, end: Alignment.bottomRight);
final kCardShadow = [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 14, offset: const Offset(0, 5))];
// ─────────────────────────────────────────────────────────────────────────────

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  int _totalIssues = 0, _pending = 0, _resolved = 0, _nature = 0;
  List<Map<String, dynamic>> _issues = [], _spots = [];
  late TabController _tabController;
  String? _email;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _email = FirebaseAuth.instance.currentUser?.email;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final snap = await FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: uid)
        .get();

    int ti = 0, p = 0, r = 0, n = 0;
    final List<Map<String, dynamic>> issues = [], spots = [];
    for (final doc in snap.docs) {
      final d = doc.data();
      if (d['type'] == 'nature') {
        n++; spots.add(d);
      } else {
        ti++;
        if ((d['status'] ?? 'pending') == 'resolved') r++; else p++;
        issues.add(d);
      }
    }

    int byTime(Map<String, dynamic> a, Map<String, dynamic> b) {
      final tA = a['timestamp'] as Timestamp?, tB = b['timestamp'] as Timestamp?;
      if (tA == null && tB == null) return 0;
      if (tA == null) return 1;
      if (tB == null) return -1;
      return tB.compareTo(tA);
    }
    issues.sort(byTime);
    spots.sort(byTime);

    if (mounted) {
      setState(() {
        _totalIssues = ti; _pending = p; _resolved = r; _nature = n;
        _issues = issues; _spots = spots; _isLoading = false;
      });
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kMint,
        body: Center(child: CircularProgressIndicator(color: kG1)),
      );
    }
    final name = _email?.split('@').first ?? 'User';

    return Scaffold(
      backgroundColor: kMint,
      // ─── Using Column so inner TabBarView ListView can scroll freely ───────
      body: Column(
        children: [
          // ── Gradient Header ──────────────────────────────────────────────
          _Header(name: name),

          // ── Stat Cards (overlapping the header bottom) ───────────────────
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _StatCards(
                total: _totalIssues, pending: _pending,
                resolved: _resolved, nature: _nature,
              ),
            ),
          ),

          // ── "My Activity" label ──────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('My Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: kTextDark, letterSpacing: 0.3)),
            ),
          ),

          // ── Tab Bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: kLightGreen.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: kTextMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                indicator: BoxDecoration(
                  gradient: kGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [Tab(text: 'My Issues'), Tab(text: 'Nature Spots')],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Tab Views – each ListView is free to scroll independently ────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ActivityList(items: _issues, isNature: false),
                _ActivityList(items: _spots, isNature: true),
              ],
            ),
          ),

          // ── Logout Bar ───────────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Container(
              color: kOffWhite,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                  label: const Text('Logout',
                    style: TextStyle(color: Colors.redAccent,
                        fontWeight: FontWeight.bold, fontSize: 15)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 48),
      decoration: BoxDecoration(
        gradient: kGradient,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back,',
                  style: TextStyle(color: Colors.white70, fontSize: 15, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(name,
                  style: const TextStyle(color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                const SizedBox(height: 6),
                const Text('Your environmental impact',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white54, width: 2),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Cards ───────────────────────────────────────────────────────────────
class _StatCards extends StatelessWidget {
  final int total, pending, resolved, nature;
  const _StatCards({required this.total, required this.pending,
      required this.resolved, required this.nature});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(child: _StatCard('Total', total,
              Icons.folder_open_rounded, [kG1, kG2])),
          const SizedBox(width: 12),
          Expanded(child: _StatCard('Pending', pending,
              Icons.hourglass_bottom_rounded,
              [const Color(0xFFE8B66A), const Color(0xFFF5C882)])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard('Resolved', resolved,
              Icons.task_alt_rounded,
              [const Color(0xFF45C4A4), const Color(0xFF72D8BF)])),
          const SizedBox(width: 12),
          Expanded(child: _StatCard('Nature Spots', nature,
              Icons.eco_rounded,
              [const Color(0xFF6DB875), const Color(0xFF90D498)])),
        ]),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final List<Color> colors;
  const _StatCard(this.label, this.count, this.icon, this.colors);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 24,
                      fontWeight: FontWeight.bold, height: 1.1)),
                Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Activity List ────────────────────────────────────────────────────────────
class _ActivityList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool isNature;
  const _ActivityList({required this.items, required this.isNature});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 68, height: 68,
            decoration: BoxDecoration(
                color: kLightGreen.withValues(alpha: 0.4), shape: BoxShape.circle),
            child: Icon(isNature ? Icons.eco_outlined : Icons.inbox_outlined,
                color: kG1, size: 32)),
          const SizedBox(height: 12),
          Text(isNature ? 'No nature spots yet.' : 'No issues reported yet.',
              style: const TextStyle(color: kTextMuted, fontSize: 15)),
        ]),
      );
    }
    // ClampingScrollPhysics so the inner list scrolls freely without fighting
    // the parent Column
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: items.length,
      itemBuilder: (_, i) =>
          _ActivityCard(data: items[i], isNature: isNature),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isNature;
  const _ActivityCard({required this.data, required this.isNature});

  @override
  Widget build(BuildContext context) {
    final dateStr = data['timestamp'] != null
        ? DateFormat('MMM dd, yyyy')
            .format((data['timestamp'] as Timestamp).toDate())
        : 'Unknown date';
    final status = data['status'] ?? 'pending';
    final statusColor = status == 'resolved'
        ? const Color(0xFF45C4A4)
        : status == 'in progress'
            ? const Color(0xFFE8B66A)
            : const Color(0xFFE07979);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kOffWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            child: data['imageUrl'] != null &&
                    (data['imageUrl'] as String).isNotEmpty
                ? Image.network(data['imageUrl'],
                    width: 80, height: 80, fit: BoxFit.cover)
                : Container(
                    width: 80, height: 80,
                    color: kLightGreen,
                    child: const Icon(Icons.image_outlined, color: kG1)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['description'] ?? 'No description',
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600,
                          fontSize: 14, color: kTextDark)),
                    const SizedBox(height: 5),
                    Text(dateStr,
                        style: const TextStyle(color: kTextMuted, fontSize: 11)),
                  ]),
            ),
          ),
          if (!isNature)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(status.toUpperCase(),
                  style: TextStyle(color: statusColor,
                      fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(gradient: kGradient, shape: BoxShape.circle),
                child: const Icon(Icons.eco_rounded, color: Colors.white, size: 16),
              ),
            ),
        ],
      ),
    );
  }
}
