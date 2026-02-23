import 'package:flutter/material.dart';
import 'database_helper.dart';

class BahanBaku extends StatefulWidget {
  @override
  _BahanBakuState createState() => _BahanBakuState();
}

class _BahanBakuState extends State<BahanBaku> {

  final TextEditingController jumlahController = TextEditingController();
  
  // 1. Variabel baru khusus untuk menampung pilihan Dropdown
  String? kualitasTerpilih;
  final List<String> listKualitas = ['Grade AA', 'Grade A', 'Grade B'];

  List<Map<String, dynamic>> dataList = [];

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

    // VALIDASI DULU (Sedikit diubah biar ngecek dropdown juga)
    if (jumlahText.isEmpty || kualitasTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Semua field harus diisi")),
      );
      return;
    }

    int jumlah = int.parse(jumlahText);

    await DatabaseHelper.instance.insertBahanBaku(jumlah, kualitasTerpilih!);
    await loadData();

    jumlahController.clear();
    // 2. Kosongkan dropdown setelah simpan ditekan
    setState(() {
      kualitasTerpilih = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Data berhasil disimpan")),
    );
  }

  Future<void> loadData() async {
    final data = await DatabaseHelper.instance.getBahanBaku();

    setState(() {
      dataList = data;
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

            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Jumlah Telur",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 16),

            // 3. BAGIAN INI SAJA YANG BERUBAH JADI DROPDOWN
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
}