import 'package:fsm_app/export.dart';

class StockInventoryScreen extends StatefulWidget {
  const StockInventoryScreen({super.key});

  @override
  State<StockInventoryScreen> createState() => _StockInventoryScreenState();
}

class _StockInventoryScreenState extends State<StockInventoryScreen> {
  late Future<List<StockItemModel>> _stockFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStock();
  }

  void _fetchStock() {
    setState(() {
      _stockFuture = ApiClient.getTableData(ApiConstants.tableStock).then(
        (data) => data.map((json) => StockItemModel.fromJson(json)).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar for quick filtering
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Stock (ID, Item, Category)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<StockItemModel>>(
              future: _stockFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No Stock Items found.'));
                }

                // Filter logic based on the search bar
                final stockItems = snapshot.data!.where((item) {
                  return item.itemDescription.toLowerCase().contains(
                        _searchQuery,
                      ) ||
                      item.stockId.toLowerCase().contains(_searchQuery) ||
                      item.category.toLowerCase().contains(_searchQuery);
                }).toList();

                return RefreshIndicator(
                  onRefresh: () async {
                    _fetchStock();
                    await _stockFuture;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    itemCount: stockItems.length,
                    itemBuilder: (context, index) {
                      final item = stockItems[index];
                      // Visual logic: Is it running out?
                      final bool isLowStock =
                          item.quantity <= item.reorderLevel;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        elevation: isLowStock
                            ? 4
                            : 1, // Make low stock pop out more
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isLowStock
                                ? Colors.redAccent.withOpacity(0.5)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.stockId} - ${item.itemDescription}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLowStock
                                          ? Colors.red
                                          : Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Qty: ${item.quantity}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Category: ${item.category}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  Text(
                                    'Reorder Lvl: ${item.reorderLevel}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Status: ${item.restockStatus}',
                                    style: TextStyle(
                                      color: isLowStock
                                          ? Colors.redAccent
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Cost: R ${item.costPerUnit.toStringAsFixed(2)}',
                                  ), // Assuming ZAR based on South Africa
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
