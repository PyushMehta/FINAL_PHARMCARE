import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String selectedCategory = "All";

  // Dummy Medicine List (Replace with real database data)
  List<Map<String, dynamic>> medicines = [];

  @override
  void initState() {
    super.initState();
    fetchMedicines();
  }

  Future<void> fetchMedicines() async {
    final snapshot = await FirebaseFirestore.instance.collection('medicines').get();
    setState(() {
      medicines = snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
    });
  }

  // Filtered medicine list based on search and category
  List<Map<String, dynamic>> get filteredMedicines {
    String query = _searchController.text.toLowerCase();
    return medicines.where((medicine) {
      bool matchesSearch = medicine["name"].toLowerCase().contains(query);
      bool matchesCategory = selectedCategory == "All" || medicine["category"] == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: Text("Inventory", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Colors.green),
            onPressed: () {
              // TODO: Implement barcode scanner function
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search Medicines...",
                prefixIcon: Icon(Icons.search, color: Colors.green),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
            SizedBox(height: 10),

            // Category Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["All", "Tablet", "Syrup", "Injection"]
                    .map((category) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: ChoiceChip(
                            label: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
                            selected: selectedCategory == category,
                            selectedColor: Colors.green,
                            onSelected: (selected) {
                              setState(() {
                                selectedCategory = category;
                              });
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
            SizedBox(height: 10),

            // Medicine List
            Expanded(
              child: filteredMedicines.isEmpty
                  ? Center(child: Text("No medicines found", style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : ListView.builder(
                      itemCount: filteredMedicines.length,
                      itemBuilder: (context, index) {
                        var medicine = filteredMedicines[index];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: Icon(medicine["icon"], color: Colors.green, size: 30),
                            title: Text(medicine["name"], style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Stock: ${medicine["stock"]} | Threshold: ${medicine["threshold"]} | Expiry: ${medicine["expiry"]}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    _showEditMedicineDialog(medicine);
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _deleteMedicine(medicine);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        icon: Icon(Icons.add),
        label: Text("Add Medicine"),
        onPressed: () {
          _showAddMedicineDialog();
        },
      ),
    );
  }

  // Function to add a new medicine
  void _showAddMedicineDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController stockController = TextEditingController();
    TextEditingController expiryController = TextEditingController();
    TextEditingController thresholdController = TextEditingController();
    String selectedCategory = "Tablets";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add Medicine"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: stockController, decoration: InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
            TextField(controller: expiryController, decoration: InputDecoration(labelText: "Expiry (MM/YYYY)")),
            TextField(
              controller: thresholdController,
              decoration: InputDecoration(labelText: "Threshold"),
              keyboardType: TextInputType.number,
            ),
            DropdownButtonFormField(
              value: selectedCategory,
              items: ["Tablets", "Syrups", "Injections"].map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                selectedCategory = value!;
              },
              decoration: InputDecoration(labelText: "Category"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('medicines').add({
                "name": nameController.text,
                "stock": int.parse(stockController.text),
                "expiry": expiryController.text,
                "threshold": int.parse(thresholdController.text),
                "category": selectedCategory,
              });
              fetchMedicines(); // Refresh local list
              Navigator.pop(context);
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  // Function to edit a medicine
  void _showEditMedicineDialog(Map<String, dynamic> medicine)  {
    TextEditingController nameController = TextEditingController(text: medicine["name"]);
    TextEditingController stockController = TextEditingController(text: medicine["stock"].toString());
    TextEditingController expiryController = TextEditingController(text: medicine["expiry"]);
    TextEditingController thresholdController = TextEditingController(text: medicine["threshold"].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Medicine"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Name")),
            TextField(controller: stockController, decoration: InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
            TextField(controller: expiryController, decoration: InputDecoration(labelText: "Expiry (MM/YYYY)")),
            TextField(
              controller: thresholdController,
              decoration: InputDecoration(labelText: "Threshold"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('medicines').doc(medicine['id']).update({
                "name": nameController.text,
                "stock": int.parse(stockController.text),
                "expiry": expiryController.text,
                "threshold": int.parse(thresholdController.text),
              });
              fetchMedicines();
              Navigator.pop(context);
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  // Function to delete a medicine
  void _deleteMedicine(Map<String, dynamic> medicine) async {
    final snapshot = await FirebaseFirestore.instance
      .collection('medicines')
      .where('name', isEqualTo: medicine['name'])
      .where('expiry', isEqualTo: medicine['expiry'])
      .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    fetchMedicines();
  }
}
