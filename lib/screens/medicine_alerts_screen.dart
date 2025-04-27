import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add Firestore import

class MedicineAlertsScreen extends StatefulWidget {
  final int initialTab;

  const MedicineAlertsScreen({super.key, required this.initialTab});

  @override
  _MedicineAlertsScreenState createState() => _MedicineAlertsScreenState();
}

class _MedicineAlertsScreenState extends State<MedicineAlertsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Replace dummy data with dynamically updated lists
  List<Map<String, String>> expiredMedicines = [];
  List<Map<String, String>> nearExpiryMedicines = [];
  List<Map<String, String>> lowStockMedicines = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    fetchAlertsData(); // Fetch data on initialization
  }

  // Simulate data fetch from backend or Firestore
  void fetchAlertsData() async {
    final now = DateTime.now();
    final threeMonthsFromNow = DateTime(now.year, now.month + 3);

    final snapshot = await FirebaseFirestore.instance.collection('medicines').get();

    final List<Map<String, String>> expired = [];
    final List<Map<String, String>> nearExpiry = [];
    final List<Map<String, String>> lowStock = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'] ?? 'Unknown';
      final expiryStr = data['expiry'] ?? '2099-01-01'; // Default fallback
      final stock = data['stock'] ?? 0;
      final threshold = data['threshold'] ?? 0;

      final parts = expiryStr.split('-');
      if (parts.length == 3) {
        final expYear = int.tryParse(parts[0]) ?? 2099;
        final expMonth = int.tryParse(parts[1]) ?? 1;
        final expDay = int.tryParse(parts[2]) ?? 1;
        final expiryDate = DateTime(expYear, expMonth, expDay);

        if (expiryDate.isBefore(now)) {
          expired.add({"name": name, "expiry": expiryStr});
        } else if (expiryDate.isBefore(threeMonthsFromNow)) {
          nearExpiry.add({"name": name, "expiry": expiryStr});
        }
      }

      if (stock <= threshold) {
        lowStock.add({"name": name, "stock": "$stock"});
      }
    }

    setState(() {
      expiredMedicines = expired;
      nearExpiryMedicines = nearExpiry;
      lowStockMedicines = lowStock;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Stock Alerts"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.cancel, color: Colors.red), text: "Expired"),
            Tab(icon: Icon(Icons.warning, color: Colors.orange), text: "Near Expiry"),
            Tab(icon: Icon(Icons.warning_amber, color: Colors.purple), text: "Low Stock"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(expiredMedicines, "Expiry Date"),
          _buildList(nearExpiryMedicines, "Expiry Date"),
          _buildList(lowStockMedicines, "Stock Left"),
        ],
      ),
    );
  }

  // Modify _buildList to handle empty list
  Widget _buildList(List<Map<String, String>> items, String label) {
    if (items.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(Icons.medication, color: Colors.green),
            title: Text(items[index]["name"] ?? ""),
            subtitle: items[index][label.toLowerCase()] != null
                ? Text("$label: ${items[index][label.toLowerCase()]}")
                : null,
          ),
        );
      },
    );
  }
}
