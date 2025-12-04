import 'dart:math';

import 'package:flutter/material.dart';

typedef StickyTableCellBuilder =
    Widget Function(BuildContext context, int rowIndex, int columnIndex);
typedef StickyTableHeaderBuilder =
    Widget Function(BuildContext context, double tableWidth);
typedef StickyTableRowHeaderBuilder =
    Widget Function(BuildContext context, int rowIndex);
typedef StickyTableCornerBuilder =
    Widget Function(BuildContext context, double width, double height);

class StickyHeaderTable extends StatefulWidget {
  const StickyHeaderTable({
    super.key,
    required this.rowCount,
    required this.columnCount,
    required this.rowHeaderWidth,
    required this.columnWidth,
    required this.rowHeight,
    required this.headerHeight,
    required this.buildColumnHeader,
    required this.buildRowHeader,
    required this.buildCell,
    this.buildCorner,
    this.minTableBodyWidth,
    this.gap = 4,
    this.headerBodySpacing = 4,
    this.showScrollbars = true,
    this.enablePanScrolling = true,
    this.onHorizontalScrollOffsetChanged,
  });

  final int rowCount;
  final int columnCount;
  final double rowHeaderWidth;
  final double columnWidth;
  final double rowHeight;
  final double headerHeight;
  final StickyTableHeaderBuilder buildColumnHeader;
  final StickyTableRowHeaderBuilder buildRowHeader;
  final StickyTableCellBuilder buildCell;
  final StickyTableCornerBuilder? buildCorner;
  final double? minTableBodyWidth;
  final double gap;
  final double headerBodySpacing;
  final bool showScrollbars;
  final bool enablePanScrolling;
  final ValueChanged<double>? onHorizontalScrollOffsetChanged;

  @override
  State<StickyHeaderTable> createState() => _StickyHeaderTableState();
}

class _StickyHeaderTableState extends State<StickyHeaderTable> {
  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _verticalHeaderController = ScrollController();
  final ScrollController _verticalBodyController = ScrollController();

  bool _isSyncingHorizontal = false;
  bool _isSyncingVertical = false;

  @override
  void initState() {
    super.initState();
    _horizontalHeaderController.addListener(_handleHorizontalScrollFromHeader);
    _horizontalBodyController.addListener(_handleHorizontalScrollFromBody);
    _verticalBodyController
        .addListener(() => _syncVerticalScroll(_verticalBodyController, _verticalHeaderController));
    _verticalHeaderController
        .addListener(() => _syncVerticalScroll(_verticalHeaderController, _verticalBodyController));
  }

  @override
  void dispose() {
    _horizontalHeaderController.dispose();
    _horizontalBodyController.dispose();
    _verticalHeaderController.dispose();
    _verticalBodyController.dispose();
    super.dispose();
  }

  void _handleHorizontalScrollFromHeader() {
    _syncHorizontalScroll(_horizontalHeaderController, _horizontalBodyController);
    _notifyHorizontalOffset(_horizontalHeaderController);
  }

  void _handleHorizontalScrollFromBody() {
    _syncHorizontalScroll(_horizontalBodyController, _horizontalHeaderController);
    _notifyHorizontalOffset(_horizontalBodyController);
  }

  void _notifyHorizontalOffset(ScrollController controller) {
    if (widget.onHorizontalScrollOffsetChanged != null) {
      widget.onHorizontalScrollOffsetChanged!(controller.offset);
    }
  }

  void _syncHorizontalScroll(
    ScrollController primary,
    ScrollController secondary,
  ) {
    if (_isSyncingHorizontal) {
      return;
    }
    _isSyncingHorizontal = true;
    if (secondary.hasClients && (secondary.offset - primary.offset).abs() > 1) {
      secondary.jumpTo(primary.offset);
    }
    _isSyncingHorizontal = false;
  }

  void _syncVerticalScroll(ScrollController primary, ScrollController secondary) {
    if (_isSyncingVertical) {
      return;
    }
    _isSyncingVertical = true;
    if (secondary.hasClients && (secondary.offset - primary.offset).abs() > 1) {
      secondary.jumpTo(primary.offset);
    }
    _isSyncingVertical = false;
  }

  void _handlePan(DragUpdateDetails details) {
    if (!widget.enablePanScrolling) {
      return;
    }
    _scrollBy(_horizontalBodyController, -details.delta.dx);
    _scrollBy(_horizontalHeaderController, -details.delta.dx);
    _scrollBy(_verticalBodyController, -details.delta.dy);
    _scrollBy(_verticalHeaderController, -details.delta.dy);
  }

  void _scrollBy(ScrollController controller, double delta) {
    if (!controller.hasClients || controller.positions.isEmpty) {
      return;
    }

    final position = controller.position;
    final targetOffset = (controller.offset + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (targetOffset != controller.offset) {
      controller.jumpTo(targetOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tableWidth =
        max(widget.columnWidth * widget.columnCount, widget.minTableBodyWidth ?? 0);

    return GestureDetector(
      onPanUpdate: widget.enablePanScrolling ? _handlePan : null,
      behavior: HitTestBehavior.deferToChild,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: widget.rowHeaderWidth,
            child: Column(
              children: [
                SizedBox(
                  height: widget.headerHeight,
                  child: widget.buildCorner?.call(
                        context,
                        widget.rowHeaderWidth,
                        widget.headerHeight,
                      ) ??
                      const SizedBox(),
                ),
                if (widget.headerBodySpacing > 0) SizedBox(height: widget.headerBodySpacing),
                Expanded(
                  child: _wrapScrollbar(
                    controller: _verticalHeaderController,
                    child: SingleChildScrollView(
                      controller: _verticalHeaderController,
                      child: Column(
                        children: [
                          for (int rowIndex = 0; rowIndex < widget.rowCount; rowIndex++)
                            SizedBox(
                              height: widget.rowHeight,
                              width: widget.rowHeaderWidth,
                              child: widget.buildRowHeader(context, rowIndex),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: widget.gap),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: widget.headerHeight,
                  child: _wrapScrollbar(
                    controller: _horizontalHeaderController,
                    child: SingleChildScrollView(
                      controller: _horizontalHeaderController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        height: widget.headerHeight,
                        child: widget.buildColumnHeader(context, tableWidth),
                      ),
                    ),
                  ),
                ),
                if (widget.headerBodySpacing > 0) SizedBox(height: widget.headerBodySpacing),
                Expanded(
                  child: _wrapScrollbar(
                    controller: _horizontalBodyController,
                    child: SingleChildScrollView(
                      controller: _horizontalBodyController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: _wrapScrollbar(
                          controller: _verticalBodyController,
                          child: SingleChildScrollView(
                            controller: _verticalBodyController,
                            child: Column(
                              children: [
                                for (int rowIndex = 0;
                                    rowIndex < widget.rowCount;
                                    rowIndex++)
                                  SizedBox(
                                    height: widget.rowHeight,
                                    child: Row(
                                      children: [
                                        for (int columnIndex = 0;
                                            columnIndex < widget.columnCount;
                                            columnIndex++)
                                          SizedBox(
                                            width: widget.columnWidth,
                                            height: widget.rowHeight,
                                            child: widget.buildCell(
                                              context,
                                              rowIndex,
                                              columnIndex,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapScrollbar({required ScrollController controller, required Widget child}) {
    if (!widget.showScrollbars) {
      return child;
    }

    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      child: child,
    );
  }
}
