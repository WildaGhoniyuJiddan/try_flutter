import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 1. TAMBAH INI untuk fitur inputFormatters
import 'database_helper.dart';

class ManajemenSupplierPage extends StatefulWidget {
  @override
  _ManajemenSupplierPageState createState() => _ManajemenSupplierPageState();
}

class _ManajemenSupplierPageState extends State<ManajemenSupplierPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();
  final TextEditingController hargaController = TextEditingController();

  List<Map<String, dynamic>> riwayatSupplier = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await DatabaseHelper.instance.getSuppliers();
    setState(() {
      riwayatSupplier = data;
    });
  }

  // 2. LOGIKA VALIDASI DIPERBAIKI DI SINI
  void simpanTransaksi() async {
    // Cek apakah ada form yang kosong
    if (namaController.text.isEmpty || jumlahController.text.isEmpty || hargaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Semua kolom harus diisi!"), backgroundColor: Colors.red)
      );
      return;
    }

    // Coba ubah teks ke angka (kalau gagal/teks ngawur, hasilnya null)
    int? jumlah = int.tryParse(jumlahController.text);
    int? harga = int.tryParse(hargaController.text);

    // Validasi: Cegah angka 0, angka minus, atau input tidak valid
    if (jumlah == null || jumlah <= 0 || harga == null || harga < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Jumlah atau harga tidak valid! Masukkan angka lebih dari 0."),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop proses simpan di sini
    }

    int total = jumlah * harga; // Hitung otomatis total pengeluaran
    String tgl = DateTime.now().toString().split(' ')[0];

    await DatabaseHelper.instance.insertSupplier(
      namaController.text, 
      jumlah, 
      harga, 
      total, 
      tgl
    );

    namaController.clear();
    jumlahController.clear();
    hargaController.clear();
    loadData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data pengadaan berhasil dicatat!"), backgroundColor: Colors.green)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pengadaan Bahan Baku")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // --- FORM INPUT ---
            TextField(
              controller: namaController, 
              decoration: InputDecoration(labelText: "Nama Peternak/Supplier")
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: jumlahController, 
                    keyboardType: TextInputType.number, 
                    // 3. PENGAMAN UI: Mencegah user mengetik minus (-) atau koma/titik sejak awal
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: "Jumlah (Butir)")
                  )
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: hargaController, 
                    keyboardType: TextInputType.number, 
                    // 3. PENGAMAN UI JUGA
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: "Harga/Butir (Rp)")
                  )
                ),
              ],
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: simpanTransaksi,
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 45)),
              child: Text("Catat Pembelian"),
            ),
            
            Divider(height: 40),
            Align(alignment: Alignment.centerLeft, child: Text("Riwayat Pengadaan:", style: TextStyle(fontWeight: FontWeight.bold))),
            
            // --- LIST RIWAYAT ---
            Expanded(
              child: ListView.builder(
                itemCount: riwayatSupplier.length,
                itemBuilder: (context, index) {
                  var item = riwayatSupplier[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['nama_peternak']),
                      subtitle: Text("${item['jumlah_telur']} butir @Rp${item['harga_per_butir']}"),
                      trailing: Text("Rp${item['total_bayar']}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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