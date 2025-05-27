import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/data/teachable_item_tag.dart';

abstract class InventoryContext {
  List<TeachableItemCategory> getCategories();
  List<TeachableItem> getItems();
  List<TeachableItem> getItemsForCategory(String categoryId);
  List<TeachableItemTag> getTags(); // 👈 new method for tag access
}
