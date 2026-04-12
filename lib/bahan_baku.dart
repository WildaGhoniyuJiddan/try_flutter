import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart';

class BahanBaku extends StatefulWidget {
  @override
  _BahanBakuPageState createState() => _BahanBakuPageState();
}

class _BahanBakuPageState extends State<BahanBaku> {
  final TextEditingController jumlahController = TextEditingController();
  
  String? statusTerpilih;
  final List<String> listStatus = ['Lolos QC', 'Gagal QC'];

  int stokBelumQC = 0;
  int totalBagus = 0;
  int totalJelek = 0;

  @override
  void initState() {
    super.initState();
    loadDataGudang();
  }

  // Fungsi untuk mengambil data dari Supplier dan hasil QC
  Future<void> loadDataGudang() async {
    int totalBeliSupplier = await FirebaseService.getTotalBeliDariSupplier();
    int bagus = await FirebaseService.getTotalBahanBakuLolosQC();
    int jelek = await FirebaseService.getTotalBahanBakuGagalQC();

    setState(() {
      totalBagus = bagus;
      totalJelek = jelek;
      // Rumus: Sisa yang belum disortir = Total Beli - (Yang Bagus + Yang Jelek)
      stokBelumQC = totalBeliSupplier - (bagus + jelek);
    });
  }

  void simpanData() async {
    String jumlahText = jumlahController.text;

    if (jumlahText.isEmpty || statusTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Jumlah dan Status QC harus diisi!"), backgroundColor: Colors.red),
      );
      return;
    }

    int? jumlah = int.tryParse(jumlahText);

    if (jumlah == null || jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Jumlah tidak valid! Harus lebih dari 0."), backgroundColor: Colors.red)
      );
      return;
    }

    // Validasi Logika: Tidak bisa men-QC telur lebih banyak dari yang dibeli
    if (jumlah > stokBelumQC) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: Anda hanya memiliki $stokBelumQC butir telur yang belum di-QC!"), backgroundColor: Colors.orange),
      );
      return;
    }

    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    // Simpan ke Firestore
    await FirebaseService.insertBahanBaku(jumlah, statusTerpilih!);

    Navigator.pop(context); // Tutup loading

    jumlahController.clear();
    setState(() {
      statusTerpilih = null;
    });

    await loadDataGudang(); // Refresh indikator angka

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data QC berhasil dicatat!"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // INI YANG MEMUNCULKAN TOMBOL BACK KE DASHBOARD
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Bahan Baku & QC"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // --- KOTAK INDIKATOR STOK ---
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.grey.shade200,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      child: Column(
                        children: [
                          Text("Belum QC", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text("$stokBelumQC", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      child: Column(
                        children: [
                          Text("Lolos (Bagus)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text("$totalBagus", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      child: Column(
                        children: [
                          Text("Gagal (Jelek)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 5),
                          Text("$totalJelek", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 30),

            // --- FORM INPUT QC ---
            Align(
              alignment: Alignment.centerLeft, 
              child: Text("Form Sortir (QC) Telur:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            ),
            SizedBox(height: 10),

            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Jumlah Telur Disortir",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.egg),
              ),
            ),
            SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: statusTerpilih,
              decoration: InputDecoration(
                labelText: "Hasil Sortir (Status QC)",
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
              child: Text("Simpan Hasil QC", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}