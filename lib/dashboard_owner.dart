import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // MENGGUNAKAN FIREBASE AUTH
import 'firebase_service.dart'; // MENGGUNAKAN FIREBASE FIRESTORE
import 'login.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class HomeOwner extends StatefulWidget {
  @override
  _HomeOwnerState createState() => _HomeOwnerState();
}

class _HomeOwnerState extends State<HomeOwner> {
  int totalProduksi = 0;
  int totalTerjualOffline = 0;
  int totalTerjualOnline = 0;
  int pendapatanOffline = 0;
  int pendapatanOnline = 0;
  int totalPendapatan = 0;
  int totalPengeluaran = 0;
  int labaBersih = 0;

  final int hargaOnline = 3500; // Asumsi harga online sedikit lebih mahal

  @override
  void initState() {
    super.initState();
    loadLaporan();
  }

  Future<void> loadLaporan() async {
    // Tarik semua data dari Cloud Firestore
    int produksi = await FirebaseService.getTotalProduksiByStatus('Berhasil');
    int jualOffline = await FirebaseService.getTotalTerjualOffline();
    int jualOnline = await FirebaseService.getTotalTerjualOnline();
    
    int uangOffline = await FirebaseService.getTotalPendapatanOffline();
    int pengeluaran = await FirebaseService.getTotalPengeluaran();
    
    // Hitung pendapatan online
    int uangOnline = jualOnline * hargaOnline;

    setState(() {
      totalProduksi = produksi;
      totalPengeluaran = pengeluaran;
      totalTerjualOffline = jualOffline;
      totalTerjualOnline = jualOnline;
      pendapatanOffline = uangOffline;
      pendapatanOnline = uangOnline;
      
      // Hitung dan langsung ke variabel UI di sini
      totalPendapatan = uangOffline + uangOnline;
      labaBersih = totalPendapatan - pengeluaran;
    });
  }

// Fungsi Export Laporan PDF Asli
  Future<void> exportLaporan() async {
    // 1. Tampilkan loading agar user tahu sistem sedang membuat PDF
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    // 2. Siapkan kertas PDF kosong
    final pdf = pw.Document();

    // 3. Gambar isi laporannya
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("LAPORAN KEUANGAN SALT-IT", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text("Periode: ${DateTime.now().toString().split(' ')[0]}"),
              ),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              
              pw.Text("A. Ringkasan Operasional", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("1. Total Produksi Berhasil : $totalProduksi Butir"),
              pw.Text("2. Total Terjual           : ${totalTerjualOffline + totalTerjualOnline} Butir"),
              pw.SizedBox(height: 20),
              
              pw.Text("B. Ringkasan Keuangan", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("1. Pendapatan Toko Offline : Rp $pendapatanOffline"),
              pw.Text("2. Pendapatan Toko Online  : Rp $pendapatanOnline"),
              pw.Text("3. Total Pengeluaran       : Rp $totalPengeluaran"),
              pw.Divider(),
              pw.Text("TOTAL OMZET                : Rp $totalPendapatan", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("LABA BERSIH                : Rp $labaBersih", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              
              pw.SizedBox(height: 40),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text("Mengetahui,"),
                    pw.SizedBox(height: 40),
                    pw.Text("( Owner SaltIT )", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ]
                )
              )
            ],
          );
        },
      ),
    );

    // 4. Tutup loading dialog
    Navigator.pop(context);

    // 5. Munculkan menu Share bawaan HP untuk menyimpan atau mengirim PDF
    await Printing.sharePdf(
      bytes: await pdf.save(), 
      filename: 'Laporan_Keuangan_SaltIT.pdf'
    );
  }

  // --- FUNGSI UBAH PASSWORD FIREBASE ---
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
        title: Text("Dashboard Owner"),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(Icons.vpn_key),
            tooltip: "Ubah Password",
            onPressed: _ubahPassword,
          ),
          IconButton(
            icon: Icon(Icons.refresh), // Tombol tambahan untuk Owner
            tooltip: "Refresh Data",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Menyinkronkan data dari Cloud...")));
              loadLaporan();
            },
          ),
          IconButton(icon: Icon(Icons.logout), onPressed: _logout)
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- KOTAK PENDAPATAN UTAMA ---
              Card(
                color: Colors.green.shade700,
                elevation: 5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text("Total Pendapatan (Omzet)", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      SizedBox(height: 10),
                      Text("Rp $totalPendapatan", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),
              Text("Ringkasan Performa", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              // --- GRID STATISTIK ---
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard("Total Produksi", "$totalProduksi", Icons.egg, Colors.orange),
                  _buildStatCard("Total Terjual", "${totalTerjualOffline + totalTerjualOnline}", Icons.check_circle, Colors.blue),
                  _buildStatCard("Penjualan Offline", "Rp $pendapatanOffline", Icons.storefront, Colors.teal),
                  _buildStatCard("Penjualan Online", "Rp $pendapatanOnline", Icons.shopping_cart, Colors.purple),
                  _buildStatCard("Total Pengeluaran", "Rp $totalPengeluaran", Icons.payments, Colors.red),
                  _buildStatCard("Laba Bersih", "Rp $labaBersih", Icons.account_balance_wallet, Colors.green),
                ],
              ),

              SizedBox(height: 30),
              Text("Laporan Bulanan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              // --- TOMBOL EXPORT (PBI-037) ---
              ElevatedButton.icon(
                onPressed: exportLaporan,
                icon: Icon(Icons.picture_as_pdf),
                label: Text("Unduh Laporan PDF"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Bantuan untuk kotak statistik kecil
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                SizedBox(width: 5),
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}