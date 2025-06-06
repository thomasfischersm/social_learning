import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_entry.dart';

abstract class InventoryContext {
  /// All categories in the course (ordered by sortOrder)
  List<TeachableItemCategory> getCategories();

  /// All items in the course (unordered or globally sorted)
  List<TeachableItem> getItems();

  /// All tags for the course
  List<TeachableItemTag> getTags();

  /// Items for a specific category
  List<TeachableItem> getItemsForCategory(String categoryId);

  /// The flattened list of inventory UI entries (categories, items, add-new rows, etc.)
  List<InventoryEntry> getInventoryEntries();
}
