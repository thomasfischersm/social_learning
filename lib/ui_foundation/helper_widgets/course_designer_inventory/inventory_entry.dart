import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_context.dart';

abstract class InventoryEntry {
  Widget buildWidget(
      BuildContext context, VoidCallback refresh, InventoryContext dataContext);
}
