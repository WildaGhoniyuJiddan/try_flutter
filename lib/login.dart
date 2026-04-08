import 'package:flutter/material.dart';
import 'package:flutter_kasir/produksi.dart';
import 'database_helper.dart';

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
  // Variabel penentu UI: Kalau null = Tampil menu pilihan. Kalau ada isi = Tampil form.
  String? roleTerpilih; 
  
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Daftar Role beserta warna dan ikonnya
  final List<Map<String, dynamic>> listRole = [
    {'nama': 'Manajer Inventory', 'email': 'manajer@admin.com', 'icon': Icons.inventory, 'warna': Colors.orange},
    {'nama': 'Produsen', 'email': 'produsen@admin.com', 'icon': Icons.factory, 'warna': Colors.blue},
    {'nama': 'Staf Offline', 'email': 'kasir@admin.com', 'icon': Icons.storefront, 'warna': Colors.teal},
    {'nama': 'Admin Online', 'email': '', 'icon': Icons.shopping_cart, 'warna': Colors.purple},
    {'nama': 'Owner', 'email': 'owner@admin.com', 'icon': Icons.admin_panel_settings, 'warna': Colors.red},
  ];

  // Fungsi saat Role diklik
  void _pilihRole(String namaRole, String emailDefault) {
    setState(() {
      roleTerpilih = namaRole;
      emailController.text = emailDefault; // Auto-fill email
    });
  }

  // Fungsi tombol kembali (Back) ke pemilihan Role
  void _kembali() {
    setState(() {
      roleTerpilih = null;
      emailController.clear();
      passwordController.clear();
    });
  }

  // --- FUNGSI BARU: LUPA PASSWORD ---
  void _lupaPassword() {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email tidak boleh kosong!"), backgroundColor: Colors.red),
      );
      return;
    }

    String emailReset = emailController.text;

    // Tampilkan konfirmasi
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Reset Password"),
        content: Text("Password untuk akun $emailReset akan direset menjadi '123456'. Apakah Anda yakin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              // Panggil fungsi update password dari database
              await DatabaseHelper.instance.updatePassword(emailReset, '123456');
              
              Navigator.pop(ctx); // Tutup dialog
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Password berhasil direset! Silakan login dengan password baru."), backgroundColor: Colors.green),
              );
            },
            child: Text("Reset Password"),
          ),
        ],
      ),
    );
  }

  // LOGIKA LOGIN ASLIMU (Terhubung ke SQLite)
  Future<void> handleLogin() async {
    String email = emailController.text;
    String password = passwordController.text;

    // Validasi input kosong
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password harus diisi!"), backgroundColor: Colors.red)
      );
      return;
    }

    // Pengecekan ke Database (Sesuai kodemu)
    String? userRole = await DatabaseHelper.instance.login(email, password);

    if (userRole != null) {
      Widget destinationPage = LoginPage();

      // Navigasi bersyarat berdasarkan Role dari Database
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password salah!"), backgroundColor: Colors.red),
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
              // Logo Aplikasi
              Icon(Icons.egg_alt, size: 80, color: Colors.orange.shade600),
              SizedBox(height: 10),
              Text("SaltIT", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
              Text("Sistem Manajemen Telur Asin", style: TextStyle(color: Colors.grey[600])),
              SizedBox(height: 40),

              // LOGIKA UI: Tampilkan Form JIKA role sudah dipilih, jika belum tampilkan Pilihan Role
              roleTerpilih != null ? _buildLoginForm() : _buildRoleSelection(),
            ],
          ),
        ),
      ),
    );
  }

  // TAMPILAN 1: GRID PILIHAN ROLE
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

  // TAMPILAN 2: FORM LOGIN (Setelah klik Role)
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
            
            // Field Email (Otomatis terisi, diset read-only / abu-abu)
            TextField(
              controller: emailController,
              readOnly: roleTerpilih != 'Admin Online', // Hanya Admin Online yang bisa edit email
              decoration: InputDecoration(
                labelText: "Email Akun",
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                fillColor: roleTerpilih == 'Admin Online' ? Colors.white : Colors.grey[200],
                filled: true,
              ),
            ),
            SizedBox(height: 15),

            // Field Password
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            
            // --- FUNGSI BARU: TOMBOL LUPA PASSWORD ---
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _lupaPassword,
                child: Text("Lupa Password?", style: TextStyle(color: Colors.blueGrey)),
              ),
            ),

            SizedBox(height: 10),

            // Tombol Login (Memanggil handleLogin aslimu)
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