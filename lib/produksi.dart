import 'package:flutter/material.dart';
import 'database_helper.dart';

class ProduksiPage extends StatefulWidget {
  @override
  _ProduksiPageState createState() => _ProduksiPageState();
}

class _ProduksiPageState extends State<ProduksiPage> {
  final TextEditingController jumlahController = TextEditingController();
  
  // Variabel untuk menyimpan angka total di layar
  int totalTelurProduksi = 0;

  @override
  void initState() {
    super.initState();
    loadTotalProduksi(); // Ambil angka total saat halaman pertama kali dibuka
  }

  // Fungsi untuk mengambil total dari database lalu menampilkannya
  Future<void> loadTotalProduksi() async {
    int total = await DatabaseHelper.instance.getTotalProduksi();
    setState(() {
      totalTelurProduksi = total;
    });
  }

  // Fungsi saat tombol simpan ditekan
  Future<void> simpanData() async {
    String jumlahText = jumlahController.text;

    if (jumlahText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Jumlah tidak boleh kosong!")),
      );
      return;
    }

    int jumlah = int.parse(jumlahText);
    
    // Ambil tanggal hari ini secara otomatis (format YYYY-MM-DD)
    String tglSekarang = DateTime.now().toString().split(' ')[0];

    // Simpan ke database
    await DatabaseHelper.instance.insertProduksi(jumlah, tglSekarang);
    
    // Bersihkan kolom input
    jumlahController.clear();
    
    // PANGGIL LAGI fungsi load agar angka di layar otomatis berganti
    await loadTotalProduksi();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$jumlah telur berhasil diproduksi!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Proses Produksi")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            
            // Kotak besar untuk menampilkan Total Telur
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text("Total Telur Asin Diproduksi", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text(
                      "$totalTelurProduksi Butir", 
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 30),

            // Form Input
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Input Jumlah Telur Asin Baru",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.egg),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: simpanData,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // Tombolnya jadi panjang
              ),
              child: Text("Simpan Hasil Produksi", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}