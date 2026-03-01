import 'package:flutter/material.dart';
import 'login.dart';
import 'bahan_baku.dart';
import 'kelola_akun.dart';

class DashboardInventory extends StatelessWidget {
  
  // Fungsi Logout
  void _logout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Menu Manajer Inventory"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: "Logout",
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Selamat Datang, Manajer!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              "Pilih menu operasional di bawah ini:",
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            
            // Grid Menu
            Expanded(
              child: GridView.count(
                crossAxisCount: 2, // 2 kotak ke samping
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context,
                    title: "Kelola Pengguna",
                    icon: Icons.manage_accounts,
                    color: Colors.blue,
                    destination: KelolaPenggunaPage(),
                  ),
                  _buildMenuCard(
                    context,
                    title: "Bahan Baku & QC",
                    icon: Icons.egg,
                    color: Colors.orange,
                    destination: BahanBaku(), // Mengarah ke form telurmu
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Pembantu untuk membuat Kotak Menu
  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required Color color, Widget? destination}) {
    return InkWell(
      onTap: () {
        if (destination != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Fitur $title masih dalam tahap pengembangan (Sprint berikutnya).")),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 30, color: color),
            ),
            SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}