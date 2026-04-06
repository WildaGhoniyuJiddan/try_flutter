import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login.dart';


class HomeOwner extends StatefulWidget {
  @override
  _HomeOwnerState createState() => _HomeOwnerState();
}

class _HomeOwnerState extends State<HomeOwner> {
  int totalProduksi = 0;
  int totalTerjualOffline = 0;
  int totalTerjualOnline = 0;
  int pendapatanOffline = 0;
  int pendapatanOnline = 0;
  int totalPendapatan = 0;
  int totalPengeluaran = 0;
  int labaBersih = 0;

  final int hargaOnline = 3500; // Asumsi harga online sedikit lebih mahal

  @override
  void initState() {
    super.initState();
    loadLaporan();
  }

  Future<void> loadLaporan() async {
    // Tarik semua data dari database helper
    int produksi = await DatabaseHelper.instance.getTotalProduksiBerhasil();
    int jualOffline = await DatabaseHelper.instance.getTotalTerjualOffline();
    int jualOnline = await DatabaseHelper.instance.getTotalTerjualOnline();
    int uangOffline = await DatabaseHelper.instance.getTotalPendapatanOffline();
    int pengeluaran = await DatabaseHelper.instance.getTotalPengeluaran();
    
    // Hitung pendapatan online (karena di sprint 6 kita hanya simpan jumlah_beli)
    int uangOnline = jualOnline * hargaOnline;

    // Masukkan SEMUA perhitungan ke dalam setState tanpa kata kunci 'int'
    setState(() {
      totalProduksi = produksi;
      totalPengeluaran = pengeluaran;
      totalTerjualOffline = jualOffline;
      totalTerjualOnline = jualOnline;
      pendapatanOffline = uangOffline;
      pendapatanOnline = uangOnline;
      
      //BUG FIX: Hitung dan langsung ke variabel UI di sini
      totalPendapatan = uangOffline + uangOnline;
      labaBersih = totalPendapatan - pengeluaran;
    });
  }

  // Simulasi PBI-037: Export Laporan
  void exportLaporan() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Export Berhasil"),
        content: Text("Laporan bulan ini berhasil diunduh dan disimpan dalam format PDF di folder Dokumen Anda."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Tutup"),
          )
        ],
      ),
    );
  }

  void _logout() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Dashboard Owner"),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KOTAK PENDAPATAN UTAMA ---
              Card(
                color: Colors.green.shade700,
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text("Total Pendapatan (Omzet)", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      SizedBox(height: 10),
                      Text("Rp $totalPendapatan", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),
              Text("Ringkasan Performa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              // --- GRID STATISTIK ---
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard("Total Produksi", "$totalProduksi", Icons.egg, Colors.orange),
                  _buildStatCard("Total Terjual", "${totalTerjualOffline + totalTerjualOnline}", Icons.check_circle, Colors.blue),
                  _buildStatCard("Penjualan Offline", "Rp $pendapatanOffline", Icons.storefront, Colors.teal),
                  _buildStatCard("Penjualan Online", "Rp $pendapatanOnline", Icons.shopping_cart, Colors.purple),
                  _buildStatCard("Total Pengeluaran", "Rp $totalPengeluaran", Icons.payments, Colors.red),
                  _buildStatCard("Laba Bersih", "Rp $labaBersih", Icons.account_balance_wallet, Colors.green),
                ],
              ),

              SizedBox(height: 30),
              Text("Laporan Bulanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              // --- TOMBOL EXPORT (PBI-037) ---
              ElevatedButton.icon(
                onPressed: exportLaporan,
                icon: Icon(Icons.picture_as_pdf),
                label: Text("Unduh Laporan PDF"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Bantuan untuk kotak statistik kecil
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                SizedBox(width: 5),
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}