
import 'package:flutter/material.dart';
import 'services/api_service.dart';

class CustomerMenuPage extends StatefulWidget {
  final String tableNumber;

  const CustomerMenuPage({
    super.key,
    required this.tableNumber,
  });

  @override
  State<CustomerMenuPage> createState() => _CustomerMenuPageState();
}

class _CustomerMenuPageState extends State<CustomerMenuPage> {
  List<Map<String, dynamic>> menus = [];
  final Map<int, int> cart = {};

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = true;
  bool isSubmitting = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadMenus();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> loadMenus() async {
    try {
      final result = await ApiService.getPublicMenus();

      if (!mounted) return;

      setState(() {
        menus = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int get totalItems => cart.values.fold(0, (sum, qty) => sum + qty);

  double get totalPrice {
    double total = 0;

    for (final menu in menus) {
      final id = int.tryParse(menu['id'].toString());
      if (id == null) continue;

      final qty = cart[id] ?? 0;
      final price = double.tryParse(menu['price'].toString()) ?? 0;

      total += price * qty;
    }

    return total;
  }

  void changeQuantity(int menuId, int change) {
    setState(() {
      final newQuantity = (cart[menuId] ?? 0) + change;

      if (newQuantity <= 0) {
        cart.remove(menuId);
      } else {
        cart[menuId] = newQuantity;
      }
    });
  }

  String formatRupiah(num value) {
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  Future<void> submitOrder() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan isi nama pelanggan.')),
      );
      return;
    }

    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu menu.')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final items = cart.entries.map((entry) {
        return <String, dynamic>{
          'menu_id': entry.key,
          'quantity': entry.value,
        };
      }).toList();

      final result = await ApiService.createPublicOrder(
        customerName: nameController.text.trim(),
        customerPhone: phoneController.text.trim(),
        tableNumber: widget.tableNumber,
        items: items,
      );

      if (!mounted) return;

      setState(() => isSubmitting = false);

      final orderId = result['id'] ?? '-';

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 56,
            ),
            title: const Text('Pesanan Berhasil!'),
            content: Text(
              'Terima kasih, ${nameController.text.trim()}.\n\n'
              'Nomor pesanan: $orderId\n'
              'Nomor meja: ${widget.tableNumber}\n'
              'Total: ${formatRupiah(totalPrice)}',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Selesai'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      setState(() {
        cart.clear();
        nameController.clear();
        phoneController.clear();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const coffeeColor = Color(0xFF6F4E37);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      appBar: AppBar(
        backgroundColor: coffeeColor,
        foregroundColor: Colors.white,
        title: const Text('Warkop Digital'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Meja ${widget.tableNumber}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off,
                          size: 56,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              errorMessage = null;
                            });
                            loadMenus();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadMenus,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: coffeeColor,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Mau pesan apa hari ini?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Pilih menu favoritmu dan pesan langsung dari meja.',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Daftar Menu',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (menus.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Belum ada menu tersedia. Silakan coba lagi nanti.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ...menus.map((menu) {
                        final menuId = int.tryParse(menu['id'].toString());
                        final name = menu['name']?.toString() ?? 'Menu';
                        final description =
                            menu['description']?.toString() ?? '';
                        final price =
                            double.tryParse(menu['price'].toString()) ?? 0;
                        final quantity =
                            menuId == null ? 0 : (cart[menuId] ?? 0);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9DCCB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.coffee,
                                    color: coffeeColor,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        formatRupiah(price),
                                        style: const TextStyle(
                                          color: coffeeColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (menuId != null)
                                  quantity == 0
                                      ? IconButton.filled(
                                          onPressed: () =>
                                              changeQuantity(menuId, 1),
                                          icon: const Icon(Icons.add),
                                          style: IconButton.styleFrom(
                                            backgroundColor: coffeeColor,
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: () =>
                                                  changeQuantity(menuId, -1),
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                            ),
                                            Text(
                                              '$quantity',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  changeQuantity(menuId, 1),
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                color: coffeeColor,
                                              ),
                                            ),
                                          ],
                                        ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data Pemesan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  labelText: 'Nama pelanggan *',
                                  prefixIcon: Icon(Icons.person_outline),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Nomor HP (opsional)',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Jumlah item'),
                                  Text('$totalItems item'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total pembayaran',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(totalPrice),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: coffeeColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: isSubmitting || cart.isEmpty
                                      ? null
                                      : submitOrder,
                                  icon: isSubmitting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.shopping_cart_checkout),
                                  label: Text(
                                    isSubmitting
                                        ? 'Mengirim Pesanan...'
                                        : 'Pesan Sekarang',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: coffeeColor,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
