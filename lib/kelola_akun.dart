import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart'; // MENGGUNAKAN FIREBASE

class KelolaPenggunaPage extends StatefulWidget {
  @override
  _KelolaPenggunaPageState createState() => _KelolaPenggunaPageState();
}

class _KelolaPenggunaPageState extends State<KelolaPenggunaPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String? _roleTerpilih;
  final List<String> _listRole = [
    'Manajer Inventory',
    'Produsen',
    'Admin Online',
    'Staf Offline',
    'Owner'
  ];

  // Fungsi untuk menampilkan Form (bisa untuk Tambah atau Edit)
  // Perhatikan: id sekarang bertipe String (Doc ID dari Firebase), bukan int
  void _showForm(String? docId, [Map<String, dynamic>? existingData]) async {
    if (docId != null && existingData != null) {
      _namaController.text = existingData['nama'] ?? '';
      _emailController.text = existingData['email'] ?? '';
      _passwordController.text = existingData['password'] ?? '';
      _roleTerpilih = existingData['role'];
    } else {
      _namaController.text = '';
      _emailController.text = '';
      _passwordController.text = '';
      _roleTerpilih = null;
    }

    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom + 15,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
              child: Text(
                docId == null ? 'Tambah Data Karyawan' : 'Edit Data Karyawan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _namaController,
              decoration: InputDecoration(labelText: 'Nama Lengkap'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'E-mail'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password (Hanya Catatan)', 
                helperText: '*Untuk login asli, tetap harus didaftarkan di Firebase Console',
              ),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _roleTerpilih,
              decoration: InputDecoration(labelText: 'Pilih Role / Jabatan'),
              items: _listRole.map((String val) {
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(val),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _roleTerpilih = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_namaController.text.isEmpty || _emailController.text.isEmpty || _roleTerpilih == null) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Nama, Email, dan Role wajib diisi!')));
                   return;
                }

                // Tampilkan loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(child: CircularProgressIndicator()),
                );

                Map<String, dynamic> userData = {
                  'nama': _namaController.text,
                  'email': _emailController.text,
                  'password': _passwordController.text,
                  'role': _roleTerpilih,
                };

                if (docId == null) {
                  await FirebaseService.insertUser(userData);
                } else {
                  await FirebaseService.updateUser(docId, userData);
                }

                Navigator.pop(context); // Tutup loading
                Navigator.of(context).pop(); // Tutup form bottom sheet
                
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data berhasil disimpan!')));
              },
              child: Text(docId == null ? 'Simpan Baru' : 'Update Data'),
            )
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menghapus user
  void _deleteUser(String docId) async {
    await FirebaseService.deleteUser(docId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data berhasil dihapus dari Cloud')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buku Data Karyawan'),
      ),
      // MENGGUNAKAN STREAMBUILDER UNTUK REAL-TIME
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseService.streamUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Belum ada data karyawan."));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id; // Mengambil ID dari Firestore

              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(Icons.person),
                    backgroundColor: Colors.blue.shade100,
                  ),
                  title: Text(data['nama'] ?? 'Tanpa Nama'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${data['email'] ?? '-'}"),
                      Text("Role: ${data['role'] ?? '-'}", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showForm(docId, data),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text("Konfirmasi"),
                                content: Text("Yakin ingin menghapus data ini?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: Text("Batal"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _deleteUser(docId);
                                    },
                                    child: Text("Hapus", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}