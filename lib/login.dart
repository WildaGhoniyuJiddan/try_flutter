import 'package:flutter/material.dart';
import 'package:flutter_kasir/produksi.dart';
import 'database_helper.dart';
// Import halaman untuk masing-masing role
import 'dashboard_inventory.dart'; 
import 'bahan_baku.dart';
import 'toko_offline.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Update controller menjadi email
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> handleLogin() async {
    String email = emailController.text;
    String password = passwordController.text;

    // Update fungsi login agar mengembalikan Map atau String berupa 'role' (misal: 'Manajer', 'Owner', 'Kasir')
    // Asumsi: jika gagal login, mengembalikan nilai null
    String? userRole = await DatabaseHelper.instance.login(email, password);

    if (userRole != null) {
      Widget destinationPage = LoginPage();

      // Navigasi bersyarat berdasarkan Role
      switch (userRole) {
        case 'Manajer Inventory':
          destinationPage = DashboardInventory(); // Arahkan ke halaman Manajer
          break;
        case 'Produsen':
          destinationPage = ProduksiPage(); // Arahkan ke halaman Produsen
        break;
        case 'Owner':
          //destinationPage = HomeOwner(); // Arahkan ke halaman Owner
          break;
        case 'Staf Offline':
          destinationPage = DashboardTokoOffline(); // Arahkan ke kasir
          break;
        default:
          destinationPage = LoginPage(); // Fallback opsional
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destinationPage),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email atau Password salah!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController, // Diubah menjadi email
              decoration: InputDecoration(labelText: "E-mail"), // Label disesuaikan mockup
            ),
            SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: handleLogin,
              child: Text("MASUK"), // Teks tombol disesuaikan mockup
            ),
          ],
        ),
      ),
    );
  }
}