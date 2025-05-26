import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';

abstract class InventoryContext {
  List<TeachableItemCategory> getCategories();
  List<TeachableItem> getItems();
  List<TeachableItem> getItemsForCategory(String categoryId);
}