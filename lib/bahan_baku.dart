import 'package:flutter/material.dart';
import 'database_helper.dart';

class BahanBaku extends StatefulWidget {
  @override
  _BahanBakuState createState() => _BahanBakuState();
}

class _BahanBakuState extends State<BahanBaku> {

  final TextEditingController jumlahController = TextEditingController();
  
  String? kualitasTerpilih;
  final List<String> listKualitas = ['Grade AA', 'Grade A', 'Grade B'];

  List<Map<String, dynamic>> dataList = [];

  // Variabel baru untuk menampung total per grade
  int totalAA = 0;
  int totalA = 0;
  int totalB = 0;

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

    if (jumlahText.isEmpty || kualitasTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Semua field harus diisi")),
      );
      return;
    }

    int jumlah = int.parse(jumlahText);

    await DatabaseHelper.instance.insertBahanBaku(jumlah, kualitasTerpilih!);
    await loadData(); // Ini akan otomatis memperbarui Card dan List

    jumlahController.clear();
    setState(() {
      kualitasTerpilih = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data berhasil disimpan")),
    );
  }

  Future<void> loadData() async {
    final data = await DatabaseHelper.instance.getBahanBaku();

    // Reset nilai hitungan sementara
    int tempAA = 0;
    int tempA = 0;
    int tempB = 0;

    // Menghitung total masing-masing grade dari data database
    for (var item in data) {
      int jml = item['jumlah'] as int;
      String kualitas = item['kualitas'] as String;

      if (kualitas == 'Grade AA') {
        tempAA += jml;
      } else if (kualitas == 'Grade A') {
        tempA += jml;
      } else if (kualitas == 'Grade B') {
        tempB += jml;
      }
    }

    setState(() {
      dataList = data;
      // Masukkan hasil hitungan ke variabel utama agar tampil di layar
      totalAA = tempAA;
      totalA = tempA;
      totalB = tempB;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Input Bahan Baku")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            
            // --- CARD BARU UNTUK TOTAL GRADE ---
            Card(
              color: Colors.orange.shade50,
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGradeInfo("Grade AA", totalAA),
                    Container(height: 40, width: 1, color: Colors.grey), // Garis pemisah
                    _buildGradeInfo("Grade A", totalA),
                    Container(height: 40, width: 1, color: Colors.grey), // Garis pemisah
                    _buildGradeInfo("Grade B", totalB),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            // ------------------------------------

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
              value: kualitasTerpilih,
              decoration: InputDecoration(
                labelText: "Kualitas",
                border: OutlineInputBorder(),
              ),
              items: listKualitas.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  kualitasTerpilih = newValue;
                });
              },
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: simpanData,
              child: Text("Simpan"),
            ),

            SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: dataList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.egg, color: Colors.brown),
                    title: Text("Jumlah: ${dataList[index]['jumlah']}"),
                    subtitle: Text("Kualitas: ${dataList[index]['kualitas']}"),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi tambahan (Widget Helper) agar kode Card di atas lebih rapi
  Widget _buildGradeInfo(String gradeName, int total) {
    return Column(
      children: [
        Text(gradeName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        SizedBox(height: 8),
        Text("$total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.deepOrange)),
      ],
    );
  }
}