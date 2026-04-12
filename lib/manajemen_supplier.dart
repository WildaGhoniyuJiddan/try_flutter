import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahan Firestore
import 'firebase_service.dart'; // MENGGUNAKAN FIREBASE

class ManajemenSupplierPage extends StatefulWidget {
  @override
  _ManajemenSupplierPageState createState() => _ManajemenSupplierPageState();
}

class _ManajemenSupplierPageState extends State<ManajemenSupplierPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();
  final TextEditingController hargaController = TextEditingController();

  void simpanTransaksi() async {
    // Cek apakah ada form yang kosong
    if (namaController.text.isEmpty || jumlahController.text.isEmpty || hargaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Semua kolom harus diisi!"), backgroundColor: Colors.red)
      );
      return;
    }

    // Coba ubah teks ke angka
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
      return;
    }

    int total = jumlah * harga; 

    // Tampilkan loading saat mengirim data ke internet
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    // Simpan ke Firestore
    await FirebaseService.insertSupplier(
      namaController.text, 
      jumlah, 
      harga, 
      total
    );

    Navigator.pop(context); // Tutup loading

    namaController.clear();
    jumlahController.clear();
    hargaController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data pengadaan berhasil dicatat di Cloud!"), backgroundColor: Colors.green)
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
              decoration: InputDecoration(
                labelText: "Nama Peternak/Supplier",
                border: OutlineInputBorder(),
              )
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: jumlahController, 
                    keyboardType: TextInputType.number, 
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "Jumlah (Butir)",
                      border: OutlineInputBorder(),
                    )
                  )
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: hargaController, 
                    keyboardType: TextInputType.number, 
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "Harga/Butir (Rp)",
                      border: OutlineInputBorder(),
                    )
                  )
                ),
              ],
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: simpanTransaksi,
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              child: Text("Catat Pembelian", style: TextStyle(fontSize: 16)),
            ),
            
            SizedBox(height: 20),
            Align(alignment: Alignment.centerLeft, child: Text("Riwayat Pengadaan (Real-time):", style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(height: 10),
            
            // --- LIST RIWAYAT MENGGUNAKAN STREAM BUILDER ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.streamSuppliers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("Belum ada riwayat pengadaan."));
                  }

                  var docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      
                      String waktu = "Memproses waktu...";
                      if (data['timestamp'] != null) {
                        Timestamp ts = data['timestamp'];
                        // Ambil format tanggalnya saja YYYY-MM-DD
                        waktu = ts.toDate().toString().split(' ')[0]; 
                      }

                      return Card(
                        margin: EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: Icon(Icons.local_shipping, color: Colors.green),
                          ),
                          title: Text(data['nama_peternak'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${data['jumlah_telur']} butir @Rp${data['harga_per_butir']}\nTanggal: $waktu"),
                          trailing: Text("Rp${data['total_bayar']}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                          isThreeLine: true,
                        ),
                      );
                    },
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