import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'login.dart'; // Pastikan meng-import login.dart untuk fitur logout

class BahanBaku extends StatefulWidget {
  @override
  _BahanBakuState createState() => _BahanBakuState();
}

class _BahanBakuState extends State<BahanBaku> {
  final TextEditingController jumlahController = TextEditingController();
  
  String? kondisiTerpilih;
  // UPDATE: Disesuaikan dengan FR-006 (Quality Control)
  final List<String> listKondisi = ['Lolos QC (Bagus)', 'Tidak Lolos (Rusak)'];

  List<Map<String, dynamic>> dataList = [];

  // Variabel penampung total telur mentah
  int totalBagus = 0;
  int totalRusak = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    jumlahController.dispose();
    super.dispose();
  }

  Future<void> simpanData() async {
    String jumlahText = jumlahController.text;

    if (jumlahText.isEmpty || kondisiTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Semua field harus diisi")),
      );
      return;
    }

    int jumlah = int.parse(jumlahText);

    // Menyimpan data ke SQLite
    await DatabaseHelper.instance.insertBahanBaku(jumlah, kondisiTerpilih!);
    await loadData(); // Memperbarui daftar dan total card otomatis

    jumlahController.clear();
    setState(() {
      kondisiTerpilih = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data penerimaan bahan baku berhasil disimpan")),
    );
  }

Future<void> loadData() async {
    // 1. Ambil data histori penerimaan telur
    final data = await DatabaseHelper.instance.getBahanBaku();

    int totalMasukBagus = 0;
    int tempRusak = 0;

    // 2. Hitung total telur kotor yang masuk
    for (var item in data) {
      int jml = item['jumlah'] as int;
      String kualitas = item['kualitas'] as String;

      if (kualitas == 'Lolos QC (Bagus)') {
        totalMasukBagus += jml;
      } else if (kualitas == 'Tidak Lolos (Rusak)') {
        tempRusak += jml;
      }
    }

    // 3. Ambil data telur yang SUDAH DIPAKAI oleh Produsen (Sprint 3)
    int dipakaiBerhasil = await DatabaseHelper.instance.getTotalProduksiBerhasil();
    int dipakaiGagal = await DatabaseHelper.instance.getTotalProduksiGagal();
    int totalDipakai = dipakaiBerhasil + dipakaiGagal;

    // 4. Hitung SISA REAL-TIME
    int sisaBagus = totalMasukBagus - totalDipakai;

    setState(() {
      dataList = data;
      totalBagus = sisaBagus; // Tampilkan SISA telur bagus di layar
      totalRusak = tempRusak;
    });
  }

  // Fungsi Logout
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
        title: Text("Dashboard Inventory"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout, // Tombol kembali ke halaman login
            tooltip: "Logout",
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // --- CARD TOTAL STOK BAHAN BAKU ---
            Card(
              color: Colors.orange.shade50,
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGradeInfo("Telur Bagus", totalBagus, Colors.green),
                    Container(height: 40, width: 1, color: Colors.grey), 
                    _buildGradeInfo("Telur Rusak", totalRusak, Colors.red),
                    Container(height: 40, width: 1, color: Colors.grey),
                    // Menampilkan total keseluruhan bahan baku yang diterima
                    _buildGradeInfo("Total Diterima", totalBagus + totalRusak, Colors.blue[800]!),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),

            // --- FORM INPUT PENERIMAAN & QC ---
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Jumlah Telur",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: kondisiTerpilih,
              decoration: InputDecoration(
                labelText: "Kondisi / Quality Control",
                border: OutlineInputBorder(),
              ),
              items: listKondisi.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  kondisiTerpilih = newValue;
                });
              },
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: simpanData,
              child: Text("Simpan Data QC"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // Tombol full width
              ),
            ),

            SizedBox(height: 20),
            
            // Text Header untuk ListView
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Riwayat Penerimaan:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(height: 10),

            // --- LIST RIWAYAT ---
            Expanded(
              child: ListView.builder(
                itemCount: dataList.length,
                itemBuilder: (context, index) {
                  // Membedakan warna icon berdasarkan kondisi telur
                  bool isBagus = dataList[index]['kualitas'] == 'Lolos QC (Bagus)';
                  
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isBagus ? Icons.check_circle : Icons.cancel, 
                        color: isBagus ? Colors.green : Colors.red
                      ),
                      title: Text("Jumlah: ${dataList[index]['jumlah']} butir"),
                      subtitle: Text("Status: ${dataList[index]['kualitas']}"),
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

  // Widget Helper untuk UI Card
  Widget _buildGradeInfo(String label, int total, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        SizedBox(height: 8),
        Text(
          "$total", 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: valueColor)
        ),
      ],
    );
  }
}