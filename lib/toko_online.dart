import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login.dart';
import 'dart:math'; // Untuk membuat pesanan acak

class DashboardTokoOnline extends StatefulWidget {
  @override
  _DashboardTokoOnlineState createState() => _DashboardTokoOnlineState();
}

class _DashboardTokoOnlineState extends State<DashboardTokoOnline> {
  int stokTersedia = 0;
  List<Map<String, dynamic>> pesananList = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // PBI-033: Validasi stok dan muat pesanan
  Future<void> loadData() async {
    int totalAlokasiOnline = await DatabaseHelper.instance.getTotalAlokasiByTujuan('Toko Online');
    int totalTerjual = await DatabaseHelper.instance.getTotalTerjualOnline();
    final dataPesanan = await DatabaseHelper.instance.getPesananOnline();

    setState(() {
      stokTersedia = totalAlokasiOnline - totalTerjual;
      pesananList = dataPesanan;
    });
  }

  // PBI-032: Simulasi Tarik Data dari Marketplace
  void tarikPesananBaru() async {
    List<String> namaDummy = ['Budi (Shopee)', 'Siti (Tokopedia)', 'Agus (Lazada)', 'Rina (TikTok)'];
    String namaPembeli = namaDummy[Random().nextInt(namaDummy.length)];
    int jumlahAcak = Random().nextInt(15) + 1; // Random beli 1 sampai 15 butir
    String tglSekarang = DateTime.now().toString().split(' ')[0];

    await DatabaseHelper.instance.insertPesananOnline(namaPembeli, jumlahAcak, tglSekarang);
    await loadData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Berhasil menarik pesanan baru dari sistem Marketplace!")),
    );
  }

  // PBI-033: Proses Kirim Barang
  void prosesKirim(int idPesanan, int jumlahBeli) async {
    if (jumlahBeli > stokTersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal! Stok online tersisa $stokTersedia butir, tidak cukup untuk pesanan ini.")),
      );
      return;
    }

    await DatabaseHelper.instance.updateStatusPesananOnline(idPesanan);
    await loadData(); // Refresh UI agar stok langsung berkurang

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Barang berhasil dikirim (Status: SHIPPED)!")),
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
        title: Text("Admin Toko Online"),
        actions: [IconButton(icon: Icon(Icons.logout), onPressed: _logout)],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // --- KOTAK SISA STOK ONLINE ---
            Card(
              color: Colors.purple.shade50,
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.shopping_cart, size: 40, color: Colors.purple),
                title: Text("Sisa Kuota Stok Online", style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("$stokTersedia Butir", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
              ),
            ),
            
            SizedBox(height: 20),

            // --- TOMBOL TARIK PESANAN ---
            ElevatedButton.icon(
              onPressed: tarikPesananBaru,
              icon: Icon(Icons.cloud_download),
              label: Text("Tarik Pesanan Baru (Sync Marketplace)"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 20),
            Align(alignment: Alignment.centerLeft, child: Text("Daftar Pesanan Masuk:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            SizedBox(height: 10),

            // --- LIST PESANAN ---
            Expanded(
              child: pesananList.isEmpty
                  ? Center(child: Text("Belum ada pesanan dari marketplace."))
                  : ListView.builder(
                      itemCount: pesananList.length,
                      itemBuilder: (context, index) {
                        var pesanan = pesananList[index];
                        bool isPending = pesanan['status'] == 'PENDING';

                        return Card(
                          margin: EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(pesanan['nama_pembeli'], style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Order: ${pesanan['jumlah_beli']} Butir\nTanggal: ${pesanan['tgl_pesanan']}"),
                            isThreeLine: true,
                            trailing: isPending
                                ? ElevatedButton(
                                    onPressed: () => prosesKirim(pesanan['id'], pesanan['jumlah_beli']),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                    child: Text("Kirim Barang", style: TextStyle(color: Colors.white)),
                                  )
                                : Text("SHIPPED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
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