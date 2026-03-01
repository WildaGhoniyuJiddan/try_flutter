import 'package:flutter/material.dart';
import 'database_helper.dart';

class KelolaPenggunaPage extends StatefulWidget {
  @override
  _KelolaPenggunaPageState createState() => _KelolaPenggunaPageState();
}

class _KelolaPenggunaPageState extends State<KelolaPenggunaPage> {
  List<Map<String, dynamic>> userList = [];

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

  @override
  void initState() {
    super.initState();
    _refreshUserList();
  }

  // Fungsi untuk mengambil data user terbaru dari database
  Future<void> _refreshUserList() async {
    final data = await DatabaseHelper.instance.getUsers();
    setState(() {
      userList = data;
    });
  }

  // Fungsi untuk menampilkan Form (bisa untuk Tambah atau Edit)
  void _showForm(int? id) async {
    // Jika id tidak null, berarti kita sedang Edit. Tarik data lama ke form.
    if (id != null) {
      final existingUser = userList.firstWhere((element) => element['id'] == id);
      _namaController.text = existingUser['nama'];
      _emailController.text = existingUser['email'];
      _passwordController.text = existingUser['password'];
      _roleTerpilih = existingUser['role'];
    } else {
      // Kosongkan form jika Tambah Data Baru
      _namaController.text = '';
      _emailController.text = '';
      _passwordController.text = '';
      _roleTerpilih = null;
    }

    // Menampilkan form melayang dari bawah (Bottom Sheet)
    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 15,
          left: 15,
          right: 15,
          // Mencegah keyboard menutupi form
          bottom: MediaQuery.of(context).viewInsets.bottom + 15,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
              child: Text(
                id == null ? 'Tambah Pengguna Baru' : 'Edit Pengguna',
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
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
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
                // Validasi input
                if (_namaController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || _roleTerpilih == null) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Semua field wajib diisi!')));
                   return;
                }

                // Simpan atau Update data
                if (id == null) {
                  await DatabaseHelper.instance.insertUser({
                    'nama': _namaController.text,
                    'email': _emailController.text,
                    'password': _passwordController.text,
                    'role': _roleTerpilih,
                  });
                } else {
                  await DatabaseHelper.instance.updateUser({
                    'id': id,
                    'nama': _namaController.text,
                    'email': _emailController.text,
                    'password': _passwordController.text,
                    'role': _roleTerpilih,
                  });
                }

                _namaController.text = '';
                _emailController.text = '';
                _passwordController.text = '';
                
                Navigator.of(context).pop(); // Tutup form
                _refreshUserList(); // Refresh data di layar
              },
              child: Text(id == null ? 'Simpan Baru' : 'Update Data'),
            )
          ],
        ),
      ),
    );
  }

  // Fungsi untuk menghapus user
  void _deleteUser(int id) async {
    await DatabaseHelper.instance.deleteUser(id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pengguna berhasil dihapus')));
    _refreshUserList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Akun Pengguna'),
      ),
      body: userList.isEmpty
          ? Center(child: Text("Belum ada data pengguna."))
          : ListView.builder(
              itemCount: userList.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                      backgroundColor: Colors.blue.shade100,
                    ),
                    title: Text(userList[index]['nama']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Email: ${userList[index]['email']}"),
                        Text("Role: ${userList[index]['role']}", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          // Tombol Edit
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _showForm(userList[index]['id']),
                          ),
                          // Tombol Delete
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Dialog konfirmasi sebelum menghapus
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text("Konfirmasi"),
                                  content: Text("Yakin ingin menghapus akun ini?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: Text("Batal"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _deleteUser(userList[index]['id']);
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
            ),
      // Tombol Tambah Data (+)
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}