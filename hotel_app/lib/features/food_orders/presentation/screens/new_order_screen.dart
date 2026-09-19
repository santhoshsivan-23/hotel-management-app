import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/db/app_database.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/food_order_model.dart';
import '../../data/repositories/food_order_repository.dart';

class _CartLine {
  _CartLine({required this.name, required this.price, this.quantity = 1});
  final String name;
  final double price;
  int quantity;
}

/// "First select Room/Guest/Active Booking, then display food menu, add
/// products with quantity" - the booking/room/guest are already known
/// (passed in from the reservation the order is being placed against), so
/// this screen focuses purely on building the order.
class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key, required this.bookingUuid, required this.roomId, required this.guestUuid});
  final String bookingUuid;
  final int roomId;
  final String guestUuid;

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  // A simple built-in menu, grouped like the spec's example
  // (Burgers/Pizza/Main Course/Desserts/Beverages). In a real deployment
  // this would come from a POS integration; kept local here since the
  // master spec explicitly treats the food menu as the hotel's own catalog
  // rather than server-managed reference data.
  static const _menu = {
    'Burgers': [('Classic Burger', 300.0), ('Cheese Burger', 350.0)],
    'Pizza': [('Margherita', 450.0), ('Pepperoni', 550.0)],
    'Main Course': [('Butter Chicken', 400.0), ('Veg Biryani', 320.0)],
    'Desserts': [('Chocolate Cake', 180.0), ('Ice Cream', 120.0)],
    'Beverages': [('Coffee', 150.0), ('Fresh Juice', 180.0)],
  };

  final Map<String, _CartLine> _cart = {};
  bool _saving = false;

  double get _total => _cart.values.fold(0, (sum, l) => sum + l.price * l.quantity);

  void _addOrIncrement(String name, double price) {
    setState(() {
      _cart.putIfAbsent(name, () => _CartLine(name: name, price: price));
      _cart[name]!.quantity++;
    });
  }

  void _decrement(String name) {
    setState(() {
      final line = _cart[name];
      if (line == null) return;
      line.quantity--;
      if (line.quantity <= 0) _cart.remove(name);
    });
  }

  Future<void> _placeOrder() async {
    if (_cart.isEmpty) return;
    setState(() => _saving = true);

    final repository = FoodOrderRepository(context.read<AppDatabase>());
    final items = _cart.values
        .map((l) => FoodOrderItemModel(
              uuid: '', // assigned inside the repository when saved
              productName: l.name,
              quantity: l.quantity,
              price: l.price,
            ))
        .toList();

    await repository.create(
      bookingUuid: widget.bookingUuid,
      roomId: widget.roomId,
      guestUuid: widget.guestUuid,
      items: items,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order added to the room bill')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Food Order')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: _menu.entries.map((category) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(category.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              ...category.value.map((item) {
                final (name, price) = item;
                final qty = _cart[name]?.quantity ?? 0;
                return ListTile(
                  title: Text(name),
                  subtitle: Text(CurrencyFormatter.format(price)),
                  trailing: qty == 0
                      ? OutlinedButton(onPressed: () => _addOrIncrement(name, price), child: const Text('Add'))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _decrement(name)),
                            Text('$qty'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _addOrIncrement(name, price),
                            ),
                          ],
                        ),
                );
              }),
            ],
          );
        }).toList(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: (_cart.isNotEmpty && !_saving) ? _placeOrder : null,
            child: _saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Place Order - ${CurrencyFormatter.format(_total)}'),
          ),
        ),
      ),
    );
  }
}
