import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pharmcare/services/notification_service.dart';  // ✅ Correct import
import 'package:cloud_firestore/cloud_firestore.dart';  // Import Firestore

class RestockListScreen extends StatefulWidget {
  const RestockListScreen({super.key});

  @override
  _RestockListScreenState createState() => _RestockListScreenState();
}

class _RestockListScreenState extends State<RestockListScreen> {
  List<Map<String, dynamic>> restockList = [];  // Replace hardcoded restockList

  String selectedFilter = "All";

  @override
  void initState() {  // Call fetchRestockData in initState
    super.initState();
    fetchRestockData();
  }

  Future<void> fetchRestockData() async {  // Fetch data from Firestore
    final snapshot = await FirebaseFirestore.instance.collection('medicines').get();

    final List<Map<String, dynamic>> fetchedList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['stock'] != null && data['threshold'] != null && data['stock'] <= data['threshold']) {
        fetchedList.add({
          "name": data['name'] ?? 'Unnamed',
          "stock": data['stock'],
          "category": data['category'] ?? '',
          "urgency": data['stock'] <= 2 ? 'Critical' : 'Low',
        });
      }
    }

    setState(() {
      restockList = fetchedList;
    });
  }

  void checkLowStock() {
    for (var medicine in restockList) {
      if (medicine["stock"] <= 2) {  // ✅ Low stock alert (threshold: 2)
        NotificationService.showNotification(
          "Low Stock Alert!",
          "${medicine['name']} is running low on stock (${medicine['stock']} left).",
        );
      }
    }
  }

  void markAsRestocked(String medicineName) async {  // Update Firestore if needed
    setState(() {
      restockList.removeWhere((medicine) => medicine["name"] == medicineName);
      checkLowStock();
    });
    // Add Firestore update logic here if needed
  }

  List<Map<String, dynamic>> getFilteredRestockList() {
    if (selectedFilter == "All") return restockList;
    return restockList
        .where((item) => item["urgency"] == selectedFilter)
        .toList();
  }

  Future<void> exportToPDF() async {
    final pdf = pdfWidgets.Document();
    pdf.addPage(
      pdfWidgets.Page(
        build: (context) => pdfWidgets.Column(
          children: getFilteredRestockList()
              .map((medicine) => pdfWidgets.Text(
                  "${medicine["name"]} - Stock: ${medicine["stock"]} - ${medicine["urgency"]}"))
              .toList(),
        ),
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = getFilteredRestockList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Restock List"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            // Sort & Filter Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: selectedFilter,
                  items: ["All", "Critical", "Low"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text("Filter: $value"),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedFilter = newValue!;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: exportToPDF,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: Text("Export PDF"),
                ),
              ],
            ),
            SizedBox(height: 10),

            // Restock List
            Expanded(
              child: filteredList.isEmpty
                  ? Center(child: Text("🎉 No medicines need restocking!"))
                  : ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final medicine = filteredList[index];
                        Color urgencyColor = medicine["urgency"] == "Critical"
                            ? Colors.red
                            : Colors.orange;

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading:
                                Icon(Icons.medication, color: urgencyColor),
                            title: Text(medicine["name"]),
                            subtitle: Text("Stock: ${medicine["stock"]}"),
                            trailing: ElevatedButton(
                              onPressed: () =>
                                  markAsRestocked(restockList[index]["name"]),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: Text("Restocked"),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}