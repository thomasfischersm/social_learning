class GeneratedCategory {
  final String category;
  final List<String> items;

  GeneratedCategory({required this.category, required this.items});

  factory GeneratedCategory.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>?;
    return GeneratedCategory(
      category: json['category'] as String? ?? '',
      items: itemsJson?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class InventoryGenerationResponse {
  final List<GeneratedCategory> categories;

  InventoryGenerationResponse({required this.categories});

  factory InventoryGenerationResponse.fromJson(Map<String, dynamic> json) {
    final categoriesJson = json['categories'] as List<dynamic>? ?? [];
    final categories = categoriesJson
        .map((e) => GeneratedCategory.fromJson(e as Map<String, dynamic>))
        .toList();
    return InventoryGenerationResponse(categories: categories);
  }
}
