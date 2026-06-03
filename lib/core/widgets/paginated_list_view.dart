import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'loading_indicator.dart';

/// A ListView with infinite scroll that calls [onLoadMore] when reaching the bottom.
///
/// Shows a loading indicator at the bottom while more items are being loaded.
/// Supports both separated and non-separated list styles.
class PaginatedListView extends StatefulWidget {
  /// Creates a [PaginatedListView].
  const PaginatedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onLoadMore,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.scrollThreshold = 200.0,
    this.padding,
    this.separatorBuilder,
    this.emptyWidget,
    this.physics,
    this.controller,
    this.shrinkWrap = false,
  });

  /// Total number of items currently loaded.
  final int itemCount;

  /// Builder for each item in the list.
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Callback triggered when the user scrolls near the bottom.
  final VoidCallback onLoadMore;

  /// Whether there are more items to load.
  final bool hasMore;

  /// Whether more items are currently being loaded.
  final bool isLoadingMore;

  /// Distance from the bottom (in pixels) at which [onLoadMore] is triggered.
  final double scrollThreshold;

  /// Padding around the list.
  final EdgeInsetsGeometry? padding;

  /// Optional separator builder between items.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Widget to display when the list is empty.
  final Widget? emptyWidget;

  /// Scroll physics for the list.
  final ScrollPhysics? physics;

  /// Optional scroll controller.
  final ScrollController? controller;

  /// Whether the list should shrink-wrap its content.
  final bool shrinkWrap;

  @override
  State<PaginatedListView> createState() => _PaginatedListViewState();
}

class _PaginatedListViewState extends State<PaginatedListView> {
  late ScrollController _scrollController;
  bool _isOwnController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _scrollController = widget.controller!;
    } else {
      _scrollController = ScrollController();
      _isOwnController = true;
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(PaginatedListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_isOwnController) {
        _scrollController.removeListener(_onScroll);
        _scrollController.dispose();
      } else {
        _scrollController.removeListener(_onScroll);
      }

      if (widget.controller != null) {
        _scrollController = widget.controller!;
        _isOwnController = false;
      } else {
        _scrollController = ScrollController();
        _isOwnController = true;
      }
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (_isOwnController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoadingMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    if (maxScroll - currentScroll <= widget.scrollThreshold) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.itemCount == 0 && !widget.isLoadingMore) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    // Total item count includes the loading indicator at the bottom
    final totalCount =
        widget.itemCount + (widget.isLoadingMore || widget.hasMore ? 1 : 0);

    if (widget.separatorBuilder != null) {
      return ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics,
        shrinkWrap: widget.shrinkWrap,
        itemCount: totalCount,
        separatorBuilder: (context, index) {
          if (index >= widget.itemCount) {
            return const SizedBox.shrink();
          }
          return widget.separatorBuilder!(context, index);
        },
        itemBuilder: _buildItem,
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      itemCount: totalCount,
      itemBuilder: _buildItem,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    if (index >= widget.itemCount) {
      // Loading indicator at the bottom
      if (widget.isLoadingMore) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: LoadingIndicator(size: 24),
        );
      }
      return const SizedBox.shrink();
    }
    return widget.itemBuilder(context, index);
  }
}
