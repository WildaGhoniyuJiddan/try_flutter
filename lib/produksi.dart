import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login.dart'; 

class ProduksiPage extends StatefulWidget {
  @override
  _ProduksiPageState createState() => _ProduksiPageState();
}

class _ProduksiPageState extends State<ProduksiPage> {
  final TextEditingController jumlahController = TextEditingController();
  
  String? statusTerpilih;
  final List<String> listStatus = ['Berhasil (Jadi)', 'Gagal (Rusak)'];

  int totalTelurAsin = 0;
  int totalGagal = 0; // Tambahan variabel untuk telur gagal
  int stokBahanBakuMentah = 0;

  @override
  void initState() {
    super.initState();
    loadDashboardData(); 
  }

  // Mengambil total telur asin, gagal, dan MENGHITUNG SISA telur mentah
  Future<void> loadDashboardData() async {
    int totalAsinBerhasil = await DatabaseHelper.instance.getTotalProduksiBerhasil();
    int totalAsinGagal = await DatabaseHelper.instance.getTotalProduksiGagal();
    int totalTelurMentah = await DatabaseHelper.instance.getTotalBahanBakuLolosQC();
    
    // Rumus Dinamis: Sisa Stok Mentah = Telur Mentah - (Berhasil + Gagal)
    int sisaMentah = totalTelurMentah - (totalAsinBerhasil + totalAsinGagal);
    
    setState(() {
      totalTelurAsin = totalAsinBerhasil;
      totalGagal = totalAsinGagal;
      stokBahanBakuMentah = sisaMentah;
    });
  }

  Future<void> simpanData() async {
    String jumlahText = jumlahController.text;

    if (jumlahText.isEmpty || statusTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Jumlah dan Status tidak boleh kosong!")),
      );
      return;
    }

    int jumlah = int.parse(jumlahText);
    
    // Validasi: Cegah produksi jika melebihi sisa stok mentah di gudang
    if (jumlah > stokBahanBakuMentah) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: Jumlah produksi melebihi sisa bahan mentah ($stokBahanBakuMentah butir)!")),
      );
      return;
    }

    String tglSekarang = DateTime.now().toString().split(' ')[0];
    String statusDB = statusTerpilih == 'Berhasil (Jadi)' ? 'Berhasil' : 'Gagal';

    // Simpan ke database
    await DatabaseHelper.instance.insertProduksi(jumlah, tglSekarang, statusDB);
    
    jumlahController.clear();
    setState(() {
      statusTerpilih = null;
    });
    
    await loadDashboardData(); // Refresh UI agar angka langsung berubah

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$jumlah telur $statusDB diproduksi!")),
    );
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Dashboard Produsen"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            
            Row(
              children: [
                // Kotak 1: Sisa Bahan Baku (Orange)
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      child: Column(
                        children: [
                          Text("Sisa Mentah", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          SizedBox(height: 5),
                          Text("$stokBahanBakuMentah", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                ),
                // Kotak 2: Telur Asin Berhasil (Biru)
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      child: Column(
                        children: [
                          Text("Berhasil (Jadi)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          SizedBox(height: 5),
                          Text("$totalTelurAsin", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                ),
                // Kotak 3: Produksi Gagal (Merah)
                Expanded(
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      child: Column(
                        children: [
                          Text("Gagal (Rusak)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          SizedBox(height: 5),
                          Text("$totalGagal", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 30),

            // --- FORM INPUT PRODUKSI ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Input Hasil Produksi Baru:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 10),

            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Jumlah Telur",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.egg),
              ),
            ),

            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: statusTerpilih,
              decoration: InputDecoration(
                labelText: "Status Hasil",
                border: OutlineInputBorder(),
              ),
              items: listStatus.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  statusTerpilih = newValue;
                });
              },
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: simpanData,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), 
              ),
              child: Text("Simpan Hasil Produksi", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}