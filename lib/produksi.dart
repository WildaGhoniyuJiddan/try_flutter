import 'package:flutter/material.dart';
import 'database_helper.dart';

class ProduksiPage extends StatelessWidget {
  final TextEditingController jumlahController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Input Produksi")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Masukkan Jumlah Telur Asin",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // 1. Ambil angka dari inputan
                int jumlah = int.parse(jumlahController.text);
                
                // 2. Panggil database
                final db = await DatabaseHelper.instance.database;
                await db.insert('produksi', {
                  'jumlah_hasil': jumlah,
                  'tgl_produksi': '2023-10-27',
                });

                // 3. Kasih tau kalau berhasil
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Data $jumlah Telur Berhasil Disimpan!")),
                );

                // 4. Kosongkan inputan
                jumlahController.clear();
              },
              child: Text("Simpan Data"),
            ),
          ],
        ),
      ),
    );
  }
}