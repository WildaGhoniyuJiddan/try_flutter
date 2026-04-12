import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart'; // MENGGUNAKAN FIREBASE
import 'login.dart';
import 'dart:math';

class DashboardTokoOnline extends StatefulWidget {
  @override
  _DashboardTokoOnlineState createState() => _DashboardTokoOnlineState();
}

class _DashboardTokoOnlineState extends State<DashboardTokoOnline> {
  int stokTersedia = 0;

  @override
  void initState() {
    super.initState();
    loadStokToko();
  }

  // Validasi stok (Mengambil data dari Modul 3 dan Modul 5)
  Future<void> loadStokToko() async {
    int totalAlokasiOnline = await FirebaseService.getTotalAlokasiByTujuan('Toko Online');
    int totalTerjual = await FirebaseService.getTotalTerjualOnline();

    setState(() {
      stokTersedia = totalAlokasiOnline - totalTerjual;
    });
  }

  // Simulasi Tarik Data dari Marketplace ke Firestore
  void tarikPesananBaru() async {
    List<String> namaDummy = ['Budi (Shopee)', 'Siti (Tokopedia)', 'Agus (Lazada)', 'Rina (TikTok)'];
    String namaPembeli = namaDummy[Random().nextInt(namaDummy.length)];
    int jumlahAcak = Random().nextInt(15) + 1; // Random beli 1 sampai 15 butir

    // Simpan ke Firestore
    await FirebaseService.insertPesananOnline(namaPembeli, jumlahAcak);
    
    // Pesanan masuk tidak mengurangi stok sebelum dikirim, tapi kita refresh saja
    await loadStokToko(); 

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Berhasil menarik pesanan baru dari Marketplace!")),
    );
  }

  // Proses Kirim Barang (Update status di Firestore)
  void prosesKirim(String idPesanan, int jumlahBeli) async {
    if (jumlahBeli > stokTersedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal! Stok online tersisa $stokTersedia butir, tidak cukup untuk pesanan ini."), backgroundColor: Colors.red),
      );
      return;
    }

    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    await FirebaseService.updateStatusPesananOnline(idPesanan);
    
    Navigator.pop(context); // Tutup loading
    await loadStokToko(); // Refresh UI agar sisa kuota berkurang

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Barang berhasil dikirim (Status: SHIPPED)!")),
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
        title: Text("Admin Toko Online"),
        actions: [
          IconButton(
            icon: Icon(Icons.vpn_key),
            tooltip: "Ubah Password",
            onPressed: _ubahPassword,
          ),
          IconButton(
            icon: Icon(Icons.logout), 
            onPressed: _logout,
            tooltip: "Logout"
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // --- KOTAK SISA STOK ONLINE ---
            Card(
              color: Colors.purple.shade50,
              elevation: 4,
              child: ListTile(
                leading: Icon(Icons.shopping_cart, size: 40, color: Colors.purple),
                title: Text("Sisa Kuota Stok Online", style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("$stokTersedia Butir", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple)),
              ),
            ),
            
            SizedBox(height: 20),

            // --- TOMBOL TARIK PESANAN ---
            ElevatedButton.icon(
              onPressed: tarikPesananBaru,
              icon: Icon(Icons.cloud_download),
              label: Text("Tarik Pesanan Baru (Sync Marketplace)"),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 20),
            Align(alignment: Alignment.centerLeft, child: Text("Daftar Pesanan Masuk (Real-time):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            SizedBox(height: 10),

            // --- LIST PESANAN REAL-TIME DARI FIREBASE ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.streamPesananOnline(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("Belum ada pesanan dari marketplace."));
                  }

                  var docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      String docId = docs[index].id; // Ambil ID Dokumen asli dari Firestore
                      
                      bool isPending = data['status'] == 'PENDING';
                      
                      // Format Waktu
                      String waktu = "Waktu memproses...";
                      if (data['timestamp'] != null) {
                        Timestamp ts = data['timestamp'];
                        waktu = ts.toDate().toString().split('.')[0]; 
                      }

                      return Card(
                        margin: EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(data['nama_pembeli'] ?? 'Anonim', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Order: ${data['jumlah_beli']} Butir\nWaktu: $waktu"),
                          isThreeLine: true,
                          trailing: isPending
                              ? ElevatedButton(
                                  onPressed: () => prosesKirim(docId, data['jumlah_beli']),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  child: Text("Kirim Barang", style: TextStyle(color: Colors.white)),
                                )
                              : Text("SHIPPED", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
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