import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // MENGGUNAKAN FIREBASE AUTH
import 'package:flutter_kasir/produksi.dart';
import 'firebase_service.dart'; // MENGGUNAKAN FIREBASE FIRESTORE

// Import halaman untuk masing-masing role
import 'dashboard_inventory.dart'; 
import 'bahan_baku.dart';
import 'toko_offline.dart';
import 'toko_online.dart';
import 'dashboard_owner.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? roleTerpilih; 
  
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final List<Map<String, dynamic>> listRole = [
    {'nama': 'Manajer Inventory', 'email': 'manajer@admin.com', 'icon': Icons.inventory, 'warna': Colors.orange},
    {'nama': 'Produsen', 'email': 'produsen@admin.com', 'icon': Icons.factory, 'warna': Colors.blue},
    {'nama': 'Staf Offline', 'email': 'kasir@admin.com', 'icon': Icons.storefront, 'warna': Colors.teal},
    {'nama': 'Admin Online', 'email': '', 'icon': Icons.shopping_cart, 'warna': Colors.purple},
    {'nama': 'Owner', 'email': 'owner@admin.com', 'icon': Icons.admin_panel_settings, 'warna': Colors.red},
  ];

  void _pilihRole(String namaRole, String emailDefault) {
    setState(() {
      roleTerpilih = namaRole;
      emailController.text = emailDefault; 
    });
  }

  void _kembali() {
    setState(() {
      roleTerpilih = null;
      emailController.clear();
      passwordController.clear();
    });
  }

  // --- FUNGSI LUPA PASSWORD FIREBASE ---
  void _lupaPassword() {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email tidak boleh kosong!"), backgroundColor: Colors.red),
      );
      return;
    }

    String emailReset = emailController.text;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Reset Password"),
        content: Text("Link untuk mereset password akan dikirim ke email $emailReset. Lanjutkan?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Firebase yang akan otomatis mengirimkan email ke pengguna
                await FirebaseAuth.instance.sendPasswordResetEmail(email: emailReset);
                
                Navigator.pop(ctx); 
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Link reset password telah dikirim ke email Anda!"), backgroundColor: Colors.green),
                );
              } catch (e) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Gagal mengirim email. Pastikan format email benar."), backgroundColor: Colors.red),
                );
              }
            },
            child: Text("Kirim Email Reset"),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA LOGIN FIREBASE ---
  Future<void> handleLogin() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    if (password.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email dan Password harus diisi!"), backgroundColor: Colors.red)
      );
      return;
    }

    // Tampilkan loading screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Minta "Satpam" (Firebase Auth) untuk membukakan pintu
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      // 2. Minta "HRD" (Firestore) untuk mengecek jabatan orang ini
      String? userRole = await FirebaseService.getUserRoleByEmail(email);
      
      Navigator.pop(context); // Tutup loading

      if (userRole != null) {
        // Cocokkan apakah role yang dia klik di awal sesuai dengan aslinya
        if (roleTerpilih != 'Admin Online' && userRole != roleTerpilih) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Akses ditolak! Anda terdaftar sebagai $userRole."), backgroundColor: Colors.red),
          );
          await FirebaseAuth.instance.signOut(); // Tendang keluar lagi
          return;
        }

        Widget destinationPage = LoginPage();

        switch (userRole) {
          case 'Manajer Inventory':
            destinationPage = DashboardInventory(); 
            break;
          case 'Produsen':
            destinationPage = ProduksiPage(); 
            break;
          case 'Owner':
            destinationPage = HomeOwner(); 
            break;
          case 'Staf Offline':
            destinationPage = DashboardTokoOffline(); 
            break;
          case 'Admin Online':
            destinationPage = DashboardTokoOnline(); 
            break;
          default:
            destinationPage = LoginPage(); 
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destinationPage),
        );
      } else {
        // Berhasil login Auth, tapi datanya belum didaftarkan oleh Owner di Firestore (Kelola Akun)
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Akun belum didaftarkan di sistem HRD pabrik!"), backgroundColor: Colors.orange),
        );
      }

    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Tutup loading
      
      String pesanError = "Terjadi kesalahan.";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        pesanError = "Email atau Password salah!";
      } else if (e.code == 'invalid-email') {
        pesanError = "Format email tidak valid!";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesanError), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.egg_alt, size: 80, color: Colors.orange.shade600),
              SizedBox(height: 10),
              Text("SaltIT", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
              Text("Sistem Manajemen Telur Asin", style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 40),

              roleTerpilih != null ? _buildLoginForm() : _buildRoleSelection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      children: [
        Text("Pilih Akses Login Anda:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, 
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.1,
          ),
          itemCount: listRole.length,
          itemBuilder: (context, index) {
            var role = listRole[index];
            return InkWell(
              onTap: () => _pilihRole(role['nama'], role['email']),
              borderRadius: BorderRadius.circular(15),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(role['icon'], size: 40, color: role['warna']),
                    SizedBox(height: 10),
                    Text(
                      role['nama'], 
                      textAlign: TextAlign.center, 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
                  onPressed: _kembali, 
                  tooltip: "Kembali pilih role",
                ),
                Expanded(
                  child: Text(
                    "Login sebagai\n$roleTerpilih", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 48), 
              ],
            ),
            SizedBox(height: 20),
            
            TextField(
              controller: emailController,
              readOnly: roleTerpilih != 'Admin Online', 
              decoration: InputDecoration(
                labelText: "Email Akun",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                fillColor: roleTerpilih == 'Admin Online' ? Colors.white : Colors.grey[200],
                filled: true,
              ),
            ),
            SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _lupaPassword,
                child: Text("Lupa Password?", style: TextStyle(color: Colors.blueGrey)),
              ),
            ),

            SizedBox(height: 10),

            ElevatedButton(
              onPressed: handleLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.orange.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("MASUK", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}