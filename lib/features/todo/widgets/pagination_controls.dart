import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  const PaginationControls({
    required this.currentPage,
    required this.pageCount,
    required this.onPageChanged,
    super.key,
  });

  final int currentPage;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Previous page',
            onPressed: currentPage > 1
                ? () => onPageChanged(currentPage - 1)
                : null,
            icon: const Icon(CupertinoIcons.chevron_left),
          ),
          Text('Page $currentPage of $pageCount'),
          IconButton(
            tooltip: 'Next page',
            onPressed: currentPage < pageCount
                ? () => onPageChanged(currentPage + 1)
                : null,
            icon: const Icon(CupertinoIcons.chevron_right),
          ),
        ],
      ),
    );
  }
}
