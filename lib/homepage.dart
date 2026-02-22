import 'package:flutter/material.dart';
import 'bahan_baku.dart';
import 'produksi.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: ListView(
        children: [

          ListTile(
            title: Text("Bahan Baku"),
            leading: Icon(Icons.inventory),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BahanBaku(),
                ),
              );
            },
          ),

          ListTile(
            title: Text("Produksi"),
            leading: Icon(Icons.factory),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProduksiPage(),
                ),
              );
            },
          ),

          ListTile(
            title: Text("Stok"),
            leading: Icon(Icons.storage),
            onTap: () {},
          ),

          ListTile(
            title: Text("Penjualan"),
            leading: Icon(Icons.point_of_sale),
            onTap: () {},
          ),

        ],
      ),
    );
  }
}