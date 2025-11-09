import 'package:flutter/material.dart';
import '../services/session.dart';
import '../Widgets/AuthDialog.dart';

class OrganizationsPage extends StatelessWidget {
  const OrganizationsPage({super.key});

  Future<void> _handleAddEdit(BuildContext context) async {
    if (!Session.isLoggedIn) {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const AuthDialog(),
      );
      if (ok != true) return;
    }
    if (!Session.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only administrators can add or edit')),
      );
      return;
    }

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const SizedBox(height: 8),
            Text('Student',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            Text('Organizations',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 20),

            // Stats row
            Row(
              children: [
                _chip('300,000 Organizations'),
                const SizedBox(width: 16),
                _chip('400,000,000 Events'),
              ],
            ),
            const SizedBox(height: 10),

            // Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => _handleAddEdit(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Add/Edit'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Filter'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Grid of org cards (placeholder UI)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.25,
              ),
              itemCount: 8,
              itemBuilder: (context, i) => _orgCard(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),

      // persistent bottom menu like your mock
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        backgroundColor: const Color(0xFFF3C84C),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.login), label: ''),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _orgCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text('🛡️',
                    style: TextStyle(fontSize: 32, color: Colors.white)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Organization Name'),
        ],
      ),
    );
  }
}
