import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 1. TAMBAH INI untuk memblokir minus di keyboard
import 'database_helper.dart';
import 'login.dart'; // Pastikan meng-import login.dart untuk fitur logout

class BahanBaku extends StatefulWidget {
  @override
  _BahanBakuState createState() => _BahanBakuState();
}

class _BahanBakuState extends State<BahanBaku> {
  final TextEditingController jumlahController = TextEditingController();
  
  String? kondisiTerpilih;
  final List<String> listKondisi = ['Lolos QC (Bagus)', 'Tidak Lolos (Rusak)'];

  List<Map<String, dynamic>> dataList = [];

  int totalBagus = 0;
  int totalRusak = 0;
  
  // 2. VARIABEL BARU UNTUK SINKRONISASI SUPPLIER
  int totalBeli = 0;
  int sisaBelumQC = 0;

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
        SnackBar(content: Text("Semua field harus diisi"), backgroundColor: Colors.red),
      );
      return;
    }

    // 3. PERBAIKAN BUG ANGKA MINUS & TEKS NGAWUR
    int? jumlah = int.tryParse(jumlahText);

    if (jumlah == null || jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Jumlah tidak valid! Masukkan angka lebih dari 0."), backgroundColor: Colors.red),
      );
      return;
    }

    // 4. LOGIKA CERDAS: Cegah input melebihi sisa yang belum di QC
    if (jumlah > sisaBelumQC) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal! Jumlah QC ($jumlah) melebihi sisa telur yang belum diperiksa ($sisaBelumQC)."), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    // Menyimpan data ke SQLite
    await DatabaseHelper.instance.insertBahanBaku(jumlah, kondisiTerpilih!);
    await loadData(); // Memperbarui daftar dan total card otomatis

    jumlahController.clear();
    setState(() {
      kondisiTerpilih = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data penerimaan bahan baku berhasil disimpan"), backgroundColor: Colors.green),
    );
  }

  Future<void> loadData() async {
    // Ambil data histori penerimaan telur
    final data = await DatabaseHelper.instance.getBahanBaku();

    int totalMasukBagus = 0;
    int tempRusak = 0;

    // Hitung total telur kotor yang masuk
    for (var item in data) {
      int jml = item['jumlah'] as int;
      String kualitas = item['kualitas'] as String;

      if (kualitas == 'Lolos QC (Bagus)') {
        totalMasukBagus += jml;
      } else if (kualitas == 'Tidak Lolos (Rusak)') {
        tempRusak += jml;
      }
    }

    // Ambil data telur yang SUDAH DIPAKAI oleh Produsen
    int dipakaiBerhasil = await DatabaseHelper.instance.getTotalProduksiBerhasil();
    int dipakaiGagal = await DatabaseHelper.instance.getTotalProduksiGagal();
    int totalDipakai = dipakaiBerhasil + dipakaiGagal;

    // Hitung SISA REAL-TIME
    int sisaBagus = totalMasukBagus - totalDipakai;

    // 5. AMBIL DATA DARI SUPPLIER & HITUNG SISA BELUM QC
    int beliTotal = await DatabaseHelper.instance.getTotalPembelian();
    int totalSudahDiperiksa = totalMasukBagus + tempRusak; // Telur bagus + rusak adalah telur yang sudah melewati QC

    setState(() {
      dataList = data;
      totalBagus = sisaBagus; 
      totalRusak = tempRusak;
      
      totalBeli = beliTotal;
      sisaBelumQC = totalBeli - totalSudahDiperiksa; // Rumus sisa antrean QC
    });
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
        title: Text("Bahan Baku & QC"),
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
            // 6. CARD BARU: INFORMASI ANTREAN QC DARI SUPPLIER
            Card(
              color: Colors.amber.shade50,
              elevation: 2,
              child: ListTile(
                leading: Icon(Icons.inventory, color: Colors.amber.shade900, size: 35),
                title: Text("Telur Menunggu QC", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Total Pembelian dari Supplier: $totalBeli"),
                trailing: Text(
                  "$sisaBelumQC", 
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.amber.shade900)
                ),
              ),
            ),
            SizedBox(height: 10),

            // --- CARD TOTAL STOK BAHAN BAKU (Lolos QC) ---
            Card(
              color: Colors.green.shade50, // Ubah sedikit warnanya biar beda dengan card di atas
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGradeInfo("Stok Bagus", totalBagus, Colors.green),
                    Container(height: 40, width: 1, color: Colors.grey), 
                    _buildGradeInfo("Total Rusak", totalRusak, Colors.red),
                    Container(height: 40, width: 1, color: Colors.grey),
                    _buildGradeInfo("Total Diperiksa", totalBagus + totalRusak, Colors.blue[800]!),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),

            // --- FORM INPUT PENERIMAAN & QC ---
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              // 7. PENGAMAN KEYBOARD UI (Blokir minus dan titik)
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Jumlah Telur yang di-QC",
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
                minimumSize: Size(double.infinity, 50),
              ),
            ),

            SizedBox(height: 20),
            
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Riwayat Pemeriksaan (QC):",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(height: 10),

            // --- LIST RIWAYAT ---
            Expanded(
              child: ListView.builder(
                itemCount: dataList.length,
                itemBuilder: (context, index) {
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