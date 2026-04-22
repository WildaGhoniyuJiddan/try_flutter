import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_service.dart'; // MENGGUNAKAN FIREBASE

class AlokasiStokPage extends StatefulWidget {
  @override
  _AlokasiStokPageState createState() => _AlokasiStokPageState();
}

class _AlokasiStokPageState extends State<AlokasiStokPage> {
  final TextEditingController jumlahController = TextEditingController();
  
  String? tujuanTerpilih;
  final List<String> listTujuan = ['Toko Offline', 'Toko Online'];

  int stokSiapAlokasi = 0;
  int stokOffline = 0;
  int stokOnline = 0;

  @override
  void initState() {
    super.initState();
    loadDataAlokasi();
  }

  Future<void> loadDataAlokasi() async {
    // 1. Ambil total telur asin yang BERHASIL diproduksi
    int totalProduksiBerhasil = await FirebaseService.getTotalProduksiByStatus('Berhasil');
    
    // 2. Ambil total yang sudah dialokasikan dari gudang utama
    int totalSudahAlokasi = await FirebaseService.getTotalSemuaAlokasi();
    
    // 3. Ambil jatah (modal) masing-masing toko
    int totalAlokasiOffline = await FirebaseService.getTotalAlokasiByTujuan('Toko Offline');
    int totalAlokasiOnline = await FirebaseService.getTotalAlokasiByTujuan('Toko Online');

    // 4. Ambil data telur yang SUDAH LAKU TERJUAL di kedua platform
    int totalTerjualOffline = await FirebaseService.getTotalTerjualOffline();
    int totalTerjualOnline = await FirebaseService.getTotalTerjualOnline(); // <-- INI DIA KUNCINYA

    if (!mounted) return;
    setState(() {
      // Rumus Gudang: Sisa yang bisa dibagikan = Total Jadi - Total yang sudah dibagi
      stokSiapAlokasi = totalProduksiBerhasil - totalSudahAlokasi;
      
      // RUMUS BARU ETALASE: Sisa Stok = Total Jatah - Total Terjual
      stokOffline = totalAlokasiOffline - totalTerjualOffline;
      stokOnline = totalAlokasiOnline - totalTerjualOnline; // <-- SEKARANG ONLINE JUGA REAL-TIME
    });
  }

  Future<void> simpanAlokasi() async {
    String jumlahText = jumlahController.text;

    if (jumlahText.isEmpty || tujuanTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Jumlah dan Tujuan harus diisi!")));
      return;
    }

   int? jumlah = int.tryParse(jumlahText);

    // Cegah angka 0 atau input tidak valid
    if (jumlah == null || jumlah <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Jumlah tidak valid! Harus lebih dari 0."), backgroundColor: Colors.red)
      );
      return;
    }

    // VALIDASI: Tidak boleh alokasi melebihi stok yang ada
    if (jumlah > stokSiapAlokasi) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: Stok siap alokasi hanya tersisa $stokSiapAlokasi butir!")),
      );
      return;
    }

    // Tampilkan loading karena butuh waktu nyimpan ke internet
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    // Simpan ke database Firestore
    await FirebaseService.insertAlokasi(tujuanTerpilih!, jumlah);

    // Tutup dialog loading
    Navigator.pop(context);

    jumlahController.clear();
    setState(() {
      tujuanTerpilih = null;
    });

    await loadDataAlokasi(); // Refresh angka di layar secara langsung

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$jumlah butir berhasil dialokasikan ke $tujuanTerpilih")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Alokasi Stok Produk Jadi")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // --- CARD INFO ---
            Card(
              color: Colors.green.shade50,
              child: ListTile(
                title: Text("Telur Asin Siap Alokasi", style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("$stokSiapAlokasi Butir", style: TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.storefront, color: Colors.blue),
                          SizedBox(height: 5),
                          Text("Offline", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("$stokOffline", style: TextStyle(fontSize: 20, color: Colors.blue)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.purple.shade50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.shopping_cart, color: Colors.purple),
                          SizedBox(height: 5),
                          Text("Online", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("$stokOnline", style: TextStyle(fontSize: 20, color: Colors.purple)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 30),

            // --- FORM INPUT ---
            Align(alignment: Alignment.centerLeft, child: Text("Form Pembagian Stok:", style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(height: 10),

            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: "Jumlah Telur", border: OutlineInputBorder()),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: tujuanTerpilih,
              decoration: InputDecoration(labelText: "Tujuan Alokasi", border: OutlineInputBorder()),
              items: listTujuan.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
              onChanged: (val) => setState(() => tujuanTerpilih = val),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: simpanAlokasi,
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
              child: Text("Simpan Alokasi", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}