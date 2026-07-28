import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../providers/data_provider.dart';
import '../widgets/common_widgets.dart';

class CafeteriaScreen extends ConsumerStatefulWidget {
  const CafeteriaScreen({super.key});

  @override
  ConsumerState<CafeteriaScreen> createState() => _CafeteriaScreenState();
}

class _CafeteriaScreenState extends ConsumerState<CafeteriaScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['All', 'Meals', 'Snacks', 'Drinks'];
  final Map<String, int> _cart = {}; // itemId -> quantity

  double _totalCartPrice(List<Map<String, dynamic>> items) {
    double total = 0;
    _cart.forEach((id, qty) {
      final item = items.firstWhere((i) => i['id'] == id, orElse: () => {});
      if (item.isNotEmpty) {
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        total += price * qty;
      }
    });
    return total;
  }

  void _orderAll(List<Map<String, dynamic>> items) async {
    if (_cart.isEmpty) return;
    try {
      for (final entry in _cart.entries) {
        final item = items.firstWhere((i) => i['id'] == entry.key, orElse: () => {});
        if (item.isNotEmpty) {
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;
          await placeCafeteriaOrder(
            ref,
            itemId: item['id'].toString(),
            itemName: item['name'].toString(),
            price: price * entry.value,
          );
        }
      }
      if (mounted) {
        setState(() => _cart.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully! Pickup at Cafeteria Counter.'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not place order: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(studentCafeteriaProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          const AppHeader(
            title: 'Student Cafeteria',
            subtitle: 'Browse daily meals, snacks, and place pre-orders',
            showBackButton: true,
          ),
          const SizedBox(height: 16),

          // Categories
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSel = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategoryIndex = index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.primaryExtraLight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: isSel ? Colors.white : AppColors.text2,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Menu List
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Could not load cafeteria menu.')),
              data: (items) {
                final category = _categories[_selectedCategoryIndex];
                final filtered = items.where((i) {
                  if (category == 'All') return true;
                  return (i['category'] ?? '').toString().toLowerCase() == category.toLowerCase();
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No items available in this category.', style: TextStyle(color: AppColors.text3)),
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final id = item['id'].toString();
                        final qty = _cart[id] ?? 0;
                        final price = (item['price'] as num?)?.toDouble() ?? 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryExtraLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.fastfood_rounded, color: AppColors.primary),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] ?? '',
                                      style: context.heading3.copyWith(fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item['category'] ?? ''} · ${item['calories'] ?? ''}',
                                      style: context.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      money(price),
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  if (qty > 0) ...[
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.red),
                                      onPressed: () {
                                        setState(() {
                                          if (qty > 1) {
                                            _cart[id] = qty - 1;
                                          } else {
                                            _cart.remove(id);
                                          }
                                        });
                                      },
                                    ),
                                    Text(
                                      '$qty',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                  IconButton(
                                    icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                    onPressed: () {
                                      setState(() {
                                        _cart[id] = qty + 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (_cart.isNotEmpty)
                      Positioned(
                        left: 16, right: 16, bottom: 16,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _orderAll(items),
                          child: Text(
                            'Pre-order (${_cart.values.fold(0, (a, b) => a + b)} items) · ${money(_totalCartPrice(items))}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
