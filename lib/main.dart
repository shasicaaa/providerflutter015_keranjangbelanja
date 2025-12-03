import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 1. MODEL BARANG (Perbaikan: Menambahkan operator == dan hashCode)
class Item {
  final String name;
  final int price;
  const Item({required this.name, required this.price});

  // Penting: Mengoverride operator == dan hashCode agar Item yang sama
  // (berdasarkan nama dan harga) dianggap sama sebagai kunci Map.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => name.hashCode ^ price.hashCode;
}

// 2. PROVIDER CART
class CartProvider with ChangeNotifier {
  final Map<Item, int> _items = {};

  Map<Item, int> get items => _items;

  int get count => _items.values.fold(0, (sum, qty) => sum + qty);

  int get totalPrice => _items.entries.fold(
    0,
    (sum, entry) => sum + (entry.key.price * entry.value),
  );

  void addToCart(Item item) {
    // Mencari item yang sudah ada menggunakan logika operator == yang telah di-override
    final existingEntry = _items.keys.cast<Item?>().firstWhere(
      (i) => i == item,
      orElse: () => null,
    );

    if (existingEntry != null) {
      _items[existingEntry] = _items[existingEntry]! + 1;
    } else {
      _items[item] = 1;
    }
    notifyListeners();
  }

  void removeItem(Item item) {
    // Mencari item yang sudah ada
    final existingEntry = _items.keys.cast<Item?>().firstWhere(
      (i) => i == item,
      orElse: () => null,
    );

    if (existingEntry != null) {
      if (_items[existingEntry] == 1) {
        _items.remove(existingEntry);
      } else {
        _items[existingEntry] = _items[existingEntry]! - 1;
      }
      notifyListeners();
    }
  }

  void checkout() {
    _items.clear();
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => CartProvider(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'keranjangbelanja_providerflutter015',
      home: HomePage(),
    );
  }
}

// 3. WIDGET BARU UNTUK SETIAP ITEM (Untuk Optimasi Rebuild)
class ItemCard extends StatelessWidget {
  final Item item;
  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer: Hanya widget ini yang akan di-rebuild ketika
    // jumlah item ini (qty) di cart berubah.
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        // Dapatkan jumlah item saat ini, default 0 jika belum ada di keranjang
        final qty = cart.items.entries
            .firstWhere(
              (entry) => entry.key == item,
              orElse: () => MapEntry(item, 0),
            )
            .value;

        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(item.name),
            subtitle: Text("Rp ${item.price}  |  Jumlah: $qty"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tombol Kurang (-)
                IconButton(
                  icon: const Icon(Icons.remove),
                  // Nonaktifkan tombol jika jumlah 0
                  onPressed: qty > 0 ? () => cart.removeItem(item) : null,
                ),
                // Tombol Tambah (+)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => cart.addToCart(item),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 4. HALAMAN UTAMA (Diperbaiki untuk menggunakan ItemCard)
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<Item> dummyItems = const [
    Item(name: "Sabun", price: 5000),
    Item(name: "Shampoo", price: 12000),
    Item(name: "Sikat Gigi", price: 8000),
    Item(name: "Odol", price: 9000),
    Item(name: "Minyak Goreng", price: 15000),
  ];

  @override
  Widget build(BuildContext context) {
    // Tidak menggunakan Provider.of di sini agar HomePage tidak di-rebuild
    // kecuali bagian AppBar actions yang menggunakan Consumer.
    return Scaffold(
      appBar: AppBar(
        title: const Text("Keranjang Belanja"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
          // Menggunakan Consumer hanya untuk menampilkan total count
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(child: Text(cart.count.toString())),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: dummyItems.length,
        itemBuilder: (context, index) {
          final item = dummyItems[index];
          // Menggunakan ItemCard yang sudah memiliki Consumer
          return ItemCard(item: item);
        },
      ),
    );
  }
}

// 5. HALAMAN CART (Diperbaiki untuk menggunakan Consumer dan validasi kosong)
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer agar CartPage me-rebuild saat terjadi checkout/remove item
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          appBar: AppBar(title: const Text("Keranjang Anda")),
          body: Column(
            children: [
              Expanded(
                // Tampilkan pesan jika keranjang kosong
                child: cart.items.isEmpty
                    ? const Center(
                        child: Text(
                          "Keranjang kosong. Tambahkan item di halaman utama.",
                        ),
                      )
                    : ListView(
                        children: cart.items.entries.map((entry) {
                          final item = entry.key;
                          final qty = entry.value;

                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text("Harga: Rp ${item.price} x $qty"),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              // removeItem akan mengurangi 1 atau menghapus jika sisa 1
                              onPressed: () => cart.removeItem(item),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Total Harga: Rp ${cart.totalPrice}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tombol Checkout (Dinonaktifkan jika keranjang kosong)
                    ElevatedButton(
                      onPressed: cart.items.isEmpty
                          ? null
                          : () {
                              final total = cart
                                  .totalPrice; // Ambil total sebelum checkout
                              cart.checkout();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Checkout berhasil! Total Pembelian Anda: Rp $total",
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );

                              // Kembali ke HomePage setelah checkout
                              Navigator.pop(context);
                            },
                      child: const Text("Checkout"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
