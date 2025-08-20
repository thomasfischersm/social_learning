import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_context.dart';

abstract class ScopeEntry {
  Widget buildWidget(
      BuildContext context, VoidCallback refresh, ScopeContext dataContext);
}
