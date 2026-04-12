import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Tambahan untuk ubah password Auth
import 'firebase_service.dart'; // MENGGUNAKAN FIREBASE, BUKAN SQLITE
import 'login.dart'; 

class ProduksiPage extends StatefulWidget {
  @override
  _ProduksiPageState createState() => _ProduksiPageState();
}

class _ProduksiPageState extends State<ProduksiPage> {
  final TextEditingController jumlahController = TextEditingController();
  
  String? statusTerpilih;
  final List<String> listStatus = ['Berhasil (Jadi)', 'Gagal (Rusak)'];

  int totalTelurAsin = 0;
  int totalGagal = 0; 
  int stokBahanBakuMentah = 0;

  @override
  void initState() {
    super.initState();
    loadDashboardData(); 
  }

  // Mengambil data dari Firebase Firestore
  Future<void> loadDashboardData() async {
    // 1. Ambil Total Telur Mentah (Bahan Baku)
    int totalTelurMentah = await FirebaseService.getTotalBahanBakuLolosQC();
    
    // 2. Ambil Total Produksi
    int totalAsinBerhasil = await FirebaseService.getTotalProduksiByStatus('Berhasil');
    int totalAsinGagal = await FirebaseService.getTotalProduksiByStatus('Gagal');
    
    // 3. Kalkulasi Sisa Mentah
    int sisaMentah = totalTelurMentah - (totalAsinBerhasil + totalAsinGagal);
    
    setState(() {
      totalTelurAsin = totalAsinBerhasil;
      totalGagal = totalAsinGagal;
      stokBahanBakuMentah = sisaMentah; // Akan minus jika data awal tidak sinkron
    });
  }

  Future<void> simpanData() async {
    String jumlahText = jumlahController.text;

    if (jumlahText.isEmpty || statusTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Jumlah dan Status tidak boleh kosong!")),
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
    
    // Validasi: Cegah produksi jika melebihi sisa stok mentah di gudang
    if (jumlah > stokBahanBakuMentah) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: Jumlah produksi melebihi sisa bahan mentah ($stokBahanBakuMentah butir)!")),
      );
      return;
    }

    // Tampilkan loading saat menyimpan ke internet
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    String statusDB = statusTerpilih == 'Berhasil (Jadi)' ? 'Berhasil' : 'Gagal';

    // Simpan ke Firestore
    await FirebaseService.insertProduksi(jumlah, statusDB);
    
    Navigator.pop(context); // Tutup loading

    jumlahController.clear();
    setState(() {
      statusTerpilih = null;
    });
    
    await loadDashboardData(); // Refresh UI agar angka langsung berubah

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$jumlah telur $statusDB diproduksi!")),
    );
  }

  // --- FUNGSI BARU: UBAH PASSWORD (FIREBASE AUTH) ---
  void _ubahPassword() {
    final TextEditingController passwordBaruController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Ubah Password"),
        content: TextField(
          controller: passwordBaruController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Password Baru",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordBaruController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Password baru tidak boleh kosong!"), backgroundColor: Colors.red),
                );
                return;
              }

              try {
                // Di Firebase, ganti password dilakukan pada user yang SEDANG LOGIN saat ini
                User? userSaatIni = FirebaseAuth.instance.currentUser;
                
                if (userSaatIni != null) {
                  await userSaatIni.updatePassword(passwordBaruController.text);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Password berhasil diubah!"), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Gagal: Anda harus login ulang!"), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                   SnackBar(content: Text("Error: Gagal mengubah password (Mungkin perlu re-login)"), backgroundColor: Colors.red),
                );
              }
            },
            child: Text("Simpan"),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut(); // Logout dari Firebase
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Dashboard Produsen"),
        actions: [
          IconButton(
            icon: Icon(Icons.vpn_key),
            tooltip: "Ubah Password",
            onPressed: _ubahPassword,
          ),
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
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      child: Column(
                        children: [
                          Text("Sisa Mentah", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          SizedBox(height: 5),
                          Text("$stokBahanBakuMentah", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                      child: Column(
                        children: [
                          Text("Berhasil (Jadi)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          SizedBox(height: 5),
                          Text("$totalTelurAsin", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
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
                          Text("Gagal (Rusak)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          SizedBox(height: 5),
                          Text("$totalGagal", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 30),

            Align(
              alignment: Alignment.centerLeft,
              child: Text("Input Hasil Produksi Baru:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 10),

            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Jumlah Telur",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.egg),
              ),
            ),

            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: statusTerpilih,
              decoration: InputDecoration(
                labelText: "Status Hasil",
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
              child: Text("Simpan Hasil Produksi", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}