class StockItemModel {
  final String stockId;
  final String itemDescription;
  final String category;
  final int quantity;
  final int reorderLevel;
  final String restockStatus;
  final double costPerUnit;

  StockItemModel({
    required this.stockId,
    required this.itemDescription,
    required this.category,
    required this.quantity,
    required this.reorderLevel,
    required this.restockStatus,
    required this.costPerUnit,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    return StockItemModel(
      stockId: json['Stock_ID']?.toString().trim() ?? '',
      itemDescription: json['Item_Description']?.toString().trim() ?? '',
      category: json['Category']?.toString().trim() ?? '',
      // Safely parse numbers from the sheet
      quantity: int.tryParse(json['Quantity']?.toString() ?? '0') ?? 0,
      reorderLevel: int.tryParse(json['Reorder_Level']?.toString() ?? '0') ?? 0,
      restockStatus: json['Restock_Status']?.toString().trim() ?? '',
      costPerUnit: double.tryParse(json['Cost_Per_Unit']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Stock_ID': stockId,
      'Item_Description': itemDescription,
      'Category': category,
      'Quantity': quantity,
      'Reorder_Level': reorderLevel,
      'Restock_Status': restockStatus,
      'Cost_Per_Unit': costPerUnit,
    };
  }
}