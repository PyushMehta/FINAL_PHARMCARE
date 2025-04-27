import 'dart:math'; // For generating random sold quantities
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pharmcare/screens/signup_screen.dart';
import 'inventory_screen.dart';
import 'package:pharmcare/screens/medicine_alerts_screen.dart';
import 'package:pharmcare/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:pharmcare/providers/user_provider.dart'; // Import your provider file
import 'package:flutter/foundation.dart';
import 'package:pharmcare/screens/restock_list_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isDarkMode = false;
  String selectedGraph = "Revenue"; // Toggle between Revenue & Profit
  String selectedTimeFrame = "Daily"; // Daily, Weekly, Monthly
  int expiredCount = 0;
  int nearExpiryCount = 0;
  int lowStockCount = 0;
  int restockCount = 0;
  List<BarChartGroupData> profitGraphData = [];
  List<String> medicineNames = [];
  int currentPage = 0;
  int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    fetchStockAlertCounts();
    fetchProfitGraphData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'PharmCare Dashboard',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 2,
      ),
      drawer: _buildSidebarMenu(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            SizedBox(height: 20),
            _buildAnalyticsSection(),
            _buildProfitGraph(),
            SizedBox(height: 20),
            _buildStockAlertsSection(context),
            SizedBox(height: 20),
            _buildBestSellingList(),
          ],
        ),
      ),
    );
  }

  // Sidebar Drawer
  Widget _buildSidebarMenu(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              return UserAccountsDrawerHeader(
                accountName:
                    Text(userProvider.userName, style: TextStyle(fontSize: 18)),
                accountEmail: Text("example@gmail.com"),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: kIsWeb
                      ? (userProvider.profileImageBytes != null
                          ? MemoryImage(userProvider.profileImageBytes!)
                          : null)
                      : (userProvider.profileImageFile != null
                          ? FileImage(userProvider.profileImageFile!)
                          : null),
                  child: (userProvider.profileImageBytes == null &&
                          userProvider.profileImageFile == null)
                      ? Icon(Icons.person, color: Colors.green, size: 40)
                      : null,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.green, Colors.teal]),
                ),
              );
            },
          ),
          _buildDrawerItem(Icons.dashboard, "Dashboard", () {
            Navigator.pop(context);
          }),
          _buildDrawerItem(Icons.inventory, "Inventory", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => InventoryScreen()));
          }),
          _buildDrawerItem(Icons.person, "Profile", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ProfileScreen()));
          }),
          _buildDrawerItem(Icons.logout, "Logout", () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => SignupScreen()));
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  // Welcome Card
  Widget _buildWelcomeCard() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.green.shade300,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.local_pharmacy, size: 50, color: Colors.white),
            SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome Back!",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text("Manage your pharmacy with ease.",
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Analytics Cards
  Widget _buildAnalyticsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoCard(
            Icons.attach_money, "Total Sales", "₹1,20,000", Colors.green),
        _buildInfoCard(Icons.show_chart, "Profit", "₹40,000", Colors.teal),
      ],
    );
  }

Widget _buildStockAlertsSection(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Stock Alerts",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Expired Medicines
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MedicineAlertsScreen(initialTab: 0)),
                );
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.red,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.cancel, color: Colors.white, size: 30),
                      SizedBox(height: 8),
                      Text("Expired",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),

          // Near Expiry Medicines
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MedicineAlertsScreen(initialTab: 1)),
                );
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.orange,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 30),
                      SizedBox(height: 8),
                      Text("Near Expiry",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),

          // Low Stock Medicines
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MedicineAlertsScreen(initialTab: 2)),
                );
              },
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                color: Colors.purple,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.white, size: 30),
                      SizedBox(height: 8),
                      Text("Low Stock",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: 10),

      // Restock List
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RestockListScreen()),
          );
        },
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          color: Colors.teal,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.inventory, color: Colors.white, size: 30),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Restock List",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                      ],
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}



  // Info Card (Fixed Missing Method)
  Widget _buildInfoCard(
      IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              SizedBox(height: 8),
              Text(title,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text(value,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // Top Selling Medicines
  Widget _buildBestSellingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Top Medicines",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        _buildMedicineCard("Paracetamol", "500 units sold"),
        _buildMedicineCard("Amoxicillin", "300 units sold"),
      ],
    );
  }

  Widget _buildMedicineCard(String name, String details) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(Icons.medication, color: Colors.green),
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(details),
      ),
    );
  }

  Future<void> fetchStockAlertCounts() async {
    final now = DateTime.now();
    final threeMonthsFromNow = DateTime(now.year, now.month + 3);

    final snapshot = await FirebaseFirestore.instance.collection('medicines').get();

    int expired = 0;
    int nearExpiry = 0;
    int lowStock = 0;
    int restock = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final stock = data['stock'] ?? 0;
      final threshold = data['threshold'] ?? 0;
      final expiryStr = data['expiry'] ?? '01/2099';

      if (stock <= threshold) {
        lowStock++;
        restock++;
      }

      final parts = expiryStr.split('/');
      if (parts.length == 2) {
        final expMonth = int.tryParse(parts[0]) ?? 1;
        final expYear = int.tryParse(parts[1]) ?? 2099;
        final expiryDate = DateTime(expYear, expMonth + 1, 0);

        if (expiryDate.isBefore(now)) {
          expired++;
        } else if (expiryDate.isBefore(threeMonthsFromNow)) {
          nearExpiry++;
        }
      }
    }

    setState(() {
      expiredCount = expired;
      nearExpiryCount = nearExpiry;
      lowStockCount = lowStock;
      restockCount = restock;
    });
  }
  // Fetch profit graph data - moved inside _DashboardScreenState
  Future<void> fetchProfitGraphData() async {
    final snapshot = await FirebaseFirestore.instance.collection('medicines').get();

    List<BarChartGroupData> tempData = [];
    List<String> tempNames = [];
    int index = 0;
    Random random = Random();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final price = (data['price'] ?? 0).toDouble();
      final sell = (data['sell'] ?? 0).toDouble();
      final medName = data['name'] ?? '';

      if (price == 0 || sell == 0) continue;

      final quantitySold = random.nextInt(100) + 1;
      final profit = (sell - price) * quantitySold;

      tempData.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: profit,
              color: Colors.green,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
      tempNames.add(medName);
      index++;
    }

    // Sort by profit descending
    tempData.sort((a, b) => b.barRods.first.toY.compareTo(a.barRods.first.toY));
    // Names stay in sync separately if needed (for now, keep original order for names)

    setState(() {
      profitGraphData = tempData;
      medicineNames = tempNames;
    });
  }

  // Build profit graph widget - moved inside _DashboardScreenState
  Widget _buildProfitGraph() {
    // Pagination logic
    final start = currentPage * itemsPerPage;
    final end = (start + itemsPerPage) > profitGraphData.length
        ? profitGraphData.length
        : (start + itemsPerPage);
    final visibleProfitGraphData = profitGraphData.sublist(start, end);
    final visibleMedicineNames = (medicineNames.length == profitGraphData.length)
        ? medicineNames.sublist(start, end)
        : List<String>.generate(visibleProfitGraphData.length, (i) => 'Med ${start + i + 1}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Profit Earned Per Medicine",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      int idx = value.toInt();
                      if (idx < 0 || idx >= visibleMedicineNames.length) {
                        return Container();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          visibleMedicineNames[idx],
                          style: TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                    interval: 1,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
              barGroups: visibleProfitGraphData.asMap().entries.map((entry) {
                int idx = entry.key;
                var group = entry.value;
                return BarChartGroupData(
                  x: idx,
                  barRods: group.barRods.map((rod) {
                    return rod.copyWith(
                      toY: double.parse(rod.toY.toStringAsFixed(0)),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: currentPage > 0
                  ? () {
                      setState(() {
                        currentPage--;
                      });
                    }
                  : null,
            ),
            Text("Page ${currentPage + 1}"),
            IconButton(
              icon: Icon(Icons.arrow_forward),
              onPressed: (currentPage + 1) * itemsPerPage < profitGraphData.length
                  ? () {
                      setState(() {
                        currentPage++;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}