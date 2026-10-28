import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() => runApp(const WarkopApp());

const coffee = Color(0xFF6F4E37);
const cream = Color(0xFFFFF8F0);
const ink = Color(0xFF28231F);
const green = Color(0xFF2E7D5B);

class WarkopApp extends StatelessWidget {
  const WarkopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Warkop Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(seedColor: coffee),
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFEDE5DC)),
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class MenuItemData {
  MenuItemData({
    required this.name,
    required this.category,
    required this.price,
    this.available = true,
  });
  String name;
  String category;
  int price;
  bool available;
}

class OrderData {
  OrderData({
    required this.number,
    required this.customer,
    required this.table,
    required this.items,
    required this.total,
    this.status = 'Menunggu',
    this.paid = false,
  });
  String number;
  String customer;
  String table;
  String items;
  int total;
  String status;
  bool paid;
}

class ExpenseData {
  ExpenseData(this.title, this.amount, this.date);
  String title;
  int amount;
  DateTime date;
}

class AppData {
  static final menus = <MenuItemData>[
    MenuItemData(name: 'Kopi Hitam', category: 'Kopi', price: 5000),
    MenuItemData(name: 'Kopi Susu', category: 'Kopi', price: 8000),
    MenuItemData(name: 'Es Teh Manis', category: 'Minuman', price: 4000),
    MenuItemData(name: 'Mi Goreng', category: 'Makanan', price: 12000),
    MenuItemData(name: 'Roti Bakar', category: 'Makanan', price: 10000),
  ];

  static final orders = <OrderData>[
    OrderData(number: 'WK-001', customer: 'Andi', table: 'Meja 2',
        items: '2x Kopi Susu, 1x Roti Bakar', total: 26000, status: 'Diproses'),
    OrderData(number: 'WK-002', customer: 'Siti', table: 'Meja 4',
        items: '1x Mi Goreng, 1x Es Teh Manis', total: 16000),
    OrderData(number: 'WK-003', customer: 'Budi', table: 'Meja 1',
        items: '2x Kopi Hitam', total: 10000, status: 'Selesai', paid: true),
  ];

  static final expenses = <ExpenseData>[
    ExpenseData('Belanja bahan', 120000, DateTime.now()),
    ExpenseData('Gas memasak', 25000, DateTime.now()),
  ];

  static int get revenue => orders.where((o) => o.paid).fold(0, (s, o) => s + o.total);
  static int get pendingOrders => orders.where((o) => !o.paid).length;
  static int get expenseTotal => expenses.fold(0, (s, e) => s + e.amount);
  static String rupiah(int n) => 'Rp${n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  String? error;
  bool isLoading = false;

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Email dan password wajib diisi.');
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      await ApiService.login(
        email: email.text.trim(),
        password: password.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminShell()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 86,
                  width: 86,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: coffee, borderRadius: BorderRadius.circular(26)),
                  child: const Icon(Icons.coffee_rounded, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 24),
                const Text('Warkop Digital', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: ink)),
                const SizedBox(height: 8),
                const Text('Masuk ke dashboard Admin/Kasir', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 28),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: password,
                  obscureText: true,
                  onSubmitted: (_) => login(),
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isLoading ? null : login,
                  style: FilledButton.styleFrom(
                    backgroundColor: coffee,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Masuk'),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Masuk menggunakan akun admin yang dikonfigurasi di backend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int selected = 0;
  final pages = const [DashboardPage(), OrdersPage(), MenuPage(), FinancePage()];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 760;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: const [
          Icon(Icons.coffee_rounded, color: coffee),
          SizedBox(width: 10),
          Text('Warkop Digital', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Row(children: [
        if (wide)
          NavigationRail(
            selectedIndex: selected,
            onDestinationSelected: (i) => setState(() => selected = i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
              NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Pesanan')),
              NavigationRailDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu), label: Text('Menu')),
              NavigationRailDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: Text('Keuangan')),
            ],
          ),
        Expanded(child: IndexedStack(index: selected, children: pages)),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => selected = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu), label: 'Menu'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Keuangan'),
        ],
      ),
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.title, required this.subtitle, required this.child, this.action});
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
            ])),
            ?action,
          ]),
          const SizedBox(height: 22),
          child,
        ]),
      ),
    ),
  );
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    final paidOrders = AppData.orders.where((o) => o.paid).length;
    return PageFrame(
      title: 'Dashboard',
      subtitle: 'Ringkasan aktivitas warkop hari ini.',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutBuilder(builder: (context, constraints) {
          final cols = constraints.maxWidth > 700 ? 4 : 2;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth > 700 ? 1.55 : 1.25,
            children: [
              StatCard(title: 'Omzet dibayar', value: AppData.rupiah(AppData.revenue), icon: Icons.payments_outlined, tint: const Color(0xFFE1F3E9)),
              StatCard(title: 'Pesanan belum lunas', value: '${AppData.pendingOrders}', icon: Icons.pending_actions, tint: const Color(0xFFFFEED8)),
              StatCard(title: 'Transaksi lunas', value: '$paidOrders', icon: Icons.receipt_long, tint: const Color(0xFFE3ECFF)),
              StatCard(title: 'Pengeluaran tercatat', value: AppData.rupiah(AppData.expenseTotal), icon: Icons.trending_down, tint: const Color(0xFFFFE4E1)),
            ],
          );
        }),
        const SizedBox(height: 24),
        const Text('Pesanan terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...AppData.orders.reversed.take(3).map((o) => OrderTile(order: o, onChanged: () => setState(() {}))),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF0E6DC), borderRadius: BorderRadius.circular(18)),
          child: const Row(children: [
            Icon(Icons.info_outline, color: coffee),
            SizedBox(width: 12),
            Expanded(child: Text('Angka pada aplikasi ini adalah data demo. Hubungkan ke database untuk pemakaian nyata.')),
          ]),
        ),
      ]),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.title, required this.value, required this.icon, required this.tint});
  final String title;
  final String value;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: coffee)),
        Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
      ]),
    ),
  );
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String filter = 'Semua';
  @override
  Widget build(BuildContext context) {
    final items = AppData.orders.where((o) {
      if (filter == 'Belum bayar') return !o.paid;
      if (filter == 'Lunas') return o.paid;
      return true;
    }).toList().reversed.toList();
    return PageFrame(
      title: 'Pesanan',
      subtitle: 'Periksa pesanan dan perbarui status pembayaran.',
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(spacing: 8, children: ['Semua', 'Belum bayar', 'Lunas'].map((f) =>
            ChoiceChip(label: Text(f), selected: filter == f, onSelected: (_) => setState(() => filter = f))).toList()),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Belum ada pesanan.'))
        else ...items.map((o) => OrderTile(order: o, onChanged: () => setState(() {}))),
      ]),
    );
  }
}

class OrderTile extends StatelessWidget {
  const OrderTile({super.key, required this.order, required this.onChanged});
  final OrderData order;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final statusColor = order.paid ? green : coffee;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${order.number} • ${order.customer}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: order.paid ? const Color(0xFFE1F3E9) : const Color(0xFFFFEED8), borderRadius: BorderRadius.circular(20)), child: Text(order.paid ? 'Lunas' : 'Belum lunas', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 6),
          Text('${order.table} • ${order.items}', style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text(AppData.rupiah(order.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
            DropdownButton<String>(
              value: order.status,
              underline: const SizedBox(),
              items: const ['Menunggu', 'Diproses', 'Siap disajikan', 'Selesai', 'Dibatalkan'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) { if (v != null) { order.status = v; onChanged(); } },
            ),
            const SizedBox(width: 6),
            if (!order.paid)
              FilledButton.tonal(
                onPressed: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi pembayaran'),
                  content: Text('Tandai pesanan ${order.number} sebesar ${AppData.rupiah(order.total)} sebagai lunas?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                    FilledButton(onPressed: () { order.paid = true; Navigator.pop(ctx); onChanged(); }, child: const Text('Ya, lunas')),
                  ],
                )),
                child: const Text('Bayar'),
              ),
          ]),
        ]),
      ),
    );
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  Future<void> editMenu([MenuItemData? item]) async {
    final name = TextEditingController(text: item?.name ?? '');
    final category = TextEditingController(text: item?.category ?? 'Minuman');
    final price = TextEditingController(text: item == null ? '' : '${item.price}');
    final result = await showDialog<MenuItemData>(context: context, builder: (ctx) => AlertDialog(
      title: Text(item == null ? 'Tambah menu' : 'Edit menu'),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama menu')),
        const SizedBox(height: 10),
        TextField(controller: category, decoration: const InputDecoration(labelText: 'Kategori')),
        const SizedBox(height: 10),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga (angka)')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: () {
          final p = int.tryParse(price.text.trim());
          if (name.text.trim().isEmpty || category.text.trim().isEmpty || p == null || p < 0) return;
          Navigator.pop(ctx, MenuItemData(name: name.text.trim(), category: category.text.trim(), price: p, available: item?.available ?? true));
        }, child: const Text('Simpan')),
      ],
    ));
    name.dispose(); category.dispose(); price.dispose();
    if (result != null && mounted) {
      setState(() {
        if (item == null) {
          AppData.menus.add(result);
        } else {
          item.name = result.name; item.category = result.category; item.price = result.price;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Menu',
    subtitle: 'Kelola nama, kategori, harga, dan ketersediaan menu.',
    action: FilledButton.icon(onPressed: () => editMenu(), icon: const Icon(Icons.add), label: const Text('Tambah')),
    child: Column(children: AppData.menus.map((m) => Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: const Color(0xFFF0E6DC), child: Icon(m.category.toLowerCase().contains('kopi') ? Icons.coffee : Icons.restaurant, color: coffee)),
        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${m.category} • ${AppData.rupiah(m.price)} • ${m.available ? 'Tersedia' : 'Habis'}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') editMenu(m);
            if (v == 'toggle') setState(() => m.available = !m.available);
            if (v == 'delete') setState(() => AppData.menus.remove(m));
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'toggle', child: Text(m.available ? 'Tandai habis' : 'Tandai tersedia')),
            const PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ),
    )).toList()),
  );
}

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});
  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  Future<void> addExpense() async {
    final title = TextEditingController();
    final amount = TextEditingController();
    final result = await showDialog<ExpenseData>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Catat pengeluaran'),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Keperluan')),
        const SizedBox(height: 10),
        TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Nominal (angka)')),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: () {
          final n = int.tryParse(amount.text.trim());
          if (title.text.trim().isEmpty || n == null || n <= 0) return;
          Navigator.pop(ctx, ExpenseData(title.text.trim(), n, DateTime.now()));
        }, child: const Text('Simpan')),
      ],
    ));
    title.dispose(); amount.dispose();
    if (result != null && mounted) setState(() => AppData.expenses.add(result));
  }

  @override
  Widget build(BuildContext context) {
    final estimatedProfit = AppData.revenue - AppData.expenseTotal;
    return PageFrame(
      title: 'Keuangan',
      subtitle: 'Catat pengeluaran dan pantau ringkasan keuangan.',
      action: FilledButton.icon(onPressed: addExpense, icon: const Icon(Icons.add), label: const Text('Pengeluaran')),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutBuilder(builder: (context, c) => GridView.count(
          crossAxisCount: c.maxWidth > 650 ? 3 : 1,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: c.maxWidth > 650 ? 1.65 : 2.8,
          children: [
            StatCard(title: 'Penjualan lunas', value: AppData.rupiah(AppData.revenue), icon: Icons.payments, tint: const Color(0xFFE1F3E9)),
            StatCard(title: 'Pengeluaran tercatat', value: AppData.rupiah(AppData.expenseTotal), icon: Icons.trending_down, tint: const Color(0xFFFFE4E1)),
            StatCard(title: 'Sisa setelah pengeluaran', value: AppData.rupiah(estimatedProfit), icon: Icons.account_balance_wallet, tint: const Color(0xFFE3ECFF)),
          ],
        )),
        const SizedBox(height: 24),
        const Text('Daftar pengeluaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (AppData.expenses.isEmpty) const Text('Belum ada pengeluaran.')
        else ...AppData.expenses.reversed.map((e) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFFFE4E1), child: Icon(Icons.receipt_long, color: coffee)),
            title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}'),
            trailing: Text(AppData.rupiah(e.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        )),
        const SizedBox(height: 12),
        const Text('Catatan: angka “sisa setelah pengeluaran” belum merupakan laba akuntansi. Untuk laba yang lebih akurat, tambahkan pencatatan modal bahan yang benar-benar terpakai, stok, dan biaya operasional lengkap.', style: TextStyle(color: Colors.black54, fontSize: 12)),
      ]),
    );
  }
}
