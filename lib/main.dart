import 'package:flutter/material.dart';

void main() {
  runApp(const KasirApp());
}

class KasirApp extends StatelessWidget {
  const KasirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kasir Sederhana',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const KasirPage(),
    );
  }
}

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController hargaController = TextEditingController();

  final List<Map<String, dynamic>> items = [];

  int total = 0;

  void tambahItem() {
    final String nama = namaController.text;
    final int harga = int.tryParse(hargaController.text) ?? 0;

    if (nama.isEmpty || harga <= 0) return;

    setState(() {
      items.add({
        'nama': nama,
        'harga': harga,
      });
      total += harga;
    });

    namaController.clear();
    hargaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir Sederhana'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Barang',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: hargaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Harga',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: tambahItem,
                child: const Text('Tambah'),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(items[index]['nama']),
                      trailing: Text(
                        'Rp ${items[index]['harga']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Text(
              'Total: Rp $total',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
