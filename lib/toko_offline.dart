import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Tambahan untuk Auth
import 'firebase_service.dart'; // MENGGUNAKAN FIREBASE
import 'login.dart';

class DashboardTokoOffline extends StatefulWidget {
  @override
  _DashboardTokoOfflineState createState() => _DashboardTokoOfflineState();
}

class _DashboardTokoOfflineState extends State<DashboardTokoOffline> {
  final TextEditingController jumlahController = TextEditingController();
  
  int stokTersedia = 0;
  final int hargaPerButir = 3000; // Asumsi harga telur asin per butir

  @override
  void initState() {
    super.initState();
    loadStokToko();
  }

  // Mengambil sisa stok khusus untuk Toko Offline dari Cloud
  Future<void> loadStokToko() async {
    // 1. Ambil jatah dari Manajer (Modul 3)
    int totalAlokasiOffline = await FirebaseService.getTotalAlokasiByTujuan('Toko Offline');
    // 2. Ambil total yang sudah laku terjual (Modul 4)
    int totalTerjual = await FirebaseService.getTotalTerjualOffline();
    
    setState(() {
      // Rumus: Stok Tersedia = (Total Jatah Offline dari Manajer) - (Total Terjual)
      stokTersedia = totalAlokasiOffline - totalTerjual;
    });
  }

  void prosesPembayaran() {
    String jumlahText = jumlahController.text;

    if (jumlahText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Masukkan jumlah beli!")));
      return;
    }

    int? jumlahBeli = int.tryParse(jumlahText);

    // Validasi ketersediaan stok & cegah angka 0
    if (jumlahBeli == null || jumlahBeli <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Jumlah tidak valid! Harus lebih dari 0."), backgroundColor: Colors.red));
      return;
    }
    if (jumlahBeli > stokTersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Stok tidak cukup! Hanya tersisa $stokTersedia butir di etalase toko.")),
      );
      return;
    }

    int totalHarga = jumlahBeli * hargaPerButir;

    // Munculkan Pop-up Konfirmasi Pembayaran & Cetak Nota
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text("Konfirmasi & Nota Transaksi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Pembelian: $jumlahBeli Butir Telur Asin"),
            Text("Harga Satuan: Rp $hargaPerButir"),
            Divider(),
            Text("Total Bayar: Rp $totalHarga", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Tampilkan loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(child: CircularProgressIndicator()),
              );

              // Simpan ke database Firestore
              await FirebaseService.insertTransaksiOffline(jumlahBeli, totalHarga);
              
              Navigator.pop(context); // Tutup loading
              Navigator.pop(ctx); // Tutup dialog konfirmasi
              
              jumlahController.clear();
              await loadStokToko(); // Refresh sisa stok
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Transaksi Berhasil! Data tersimpan di Cloud.")),
              );
            },
            child: Text("Bayar & Selesai"),
          ),
        ],
      ),
    );
  }

  // --- FUNGSI BARU: UBAH PASSWORD FIREBASE ---
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Kasir Toko Offline"),
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
            // Card Info Stok Etalase
            Card(
              color: Colors.blue.shade50,
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text("Sisa Stok di Etalase Toko", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text("$stokTersedia Butir", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 30),

            // Form Kasir
            Align(alignment: Alignment.centerLeft, child: Text("Input Penjualan Baru:", style: TextStyle(fontWeight: FontWeight.bold))),
            SizedBox(height: 10),

            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Jumlah Beli (Butir)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_basket),
              ),
            ),
            
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: prosesPembayaran,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 55),
                backgroundColor: Colors.green,
              ),
              child: Text("Proses Pembayaran", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}