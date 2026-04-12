import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // TAMBAHAN 1: Import Firebase Core
import 'firebase_options.dart'; // TAMBAHAN 2: Import opsi Firebase hasil generate

import 'package:flutter_kasir/dashboard_inventory.dart';
import 'bahan_baku.dart';
import 'login.dart';
import 'produksi.dart';

// TAMBAHAN 3: Ubah main() menjadi async
void main() async {
  // TAMBAHAN 4: Pastikan pondasi Flutter siap sebelum memuat Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // TAMBAHAN 5: Nyalakan mesin Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyTelur());
}

class MyTelur extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telur Asin App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
      //home: BahanBaku(),
    );
  }
}

class HomePage extends StatelessWidget {
  final List<Map<String, dynamic>> menu = [
    {"title": "Bahan Baku", "icon": Icons.inventory},
    {"title": "Produksi", "icon": Icons.factory},
    {"title": "Stok", "icon": Icons.storage},
    {"title": "Penjualan", "icon": Icons.point_of_sale},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sistem Telur Asin")),
      body: ListView.builder(
        itemCount: menu.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: Icon(menu[index]["icon"]),
              title: Text(menu[index]["title"]),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                if (menu[index]["title"] == "Bahan Baku") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardInventory()),
                  );
                } 
                else if (menu[index]["title"] == "Produksi") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProduksiPage()),
                  );
                } 
                else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Menu ${menu[index]["title"]} belum dibuat")),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}