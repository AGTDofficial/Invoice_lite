import 'package:flutter/material.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) displayString;
  final String? Function(T)? displaySubtitle;
  final String? Function(T)? displayTrailing;
  final String hintText;
  final String? labelText;
  final Function(T?) onChanged;
  final T? value;
  final bool showSearchIcon;
  final bool isExpanded;
  final double itemHeight;
  final int maxDisplayedItems;
  final InputDecoration? decoration;

  const SearchableDropdown({
    Key? key,
    required this.items,
    required this.displayString,
    this.displaySubtitle,
    this.displayTrailing,
    required this.onChanged,
    this.hintText = 'Search...',
    this.labelText,
    this.value,
    this.showSearchIcon = true,
    this.isExpanded = true,
    this.itemHeight = 60.0,
    this.maxDisplayedItems = 5,
    this.decoration,
  }) : super(key: key);

  @override
  _SearchableDropdownState<T> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  late List<T> _filteredItems;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  bool _isDropdownOpen = false;
  final _menuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _filteredItems = List<T>.from(widget.items);
    _focusNode.addListener(_onFocusChange);
    if (widget.value != null) {
      _searchController.text = widget.displayString(widget.value!);
    }
  }

  @override
  void didUpdateWidget(SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _filterItems(_searchController.text);
    }
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List<T>.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          return widget.displayString(item).toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    _isDropdownOpen = true;
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _focusNode.unfocus();
        },
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                width: size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  offset: Offset(0, size.height + 5),
                  child: Container(
                    key: _menuKey,
                    constraints: BoxConstraints(
                      maxHeight: widget.itemHeight * 
                          (_filteredItems.length > widget.maxDisplayedItems 
                              ? widget.maxDisplayedItems 
                              : _filteredItems.length) + 2,
                      maxWidth: size.width,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5.0,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _filteredItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No items found',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = _filteredItems[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    widget.onChanged(item);
                                    _searchController.text = widget.displayString(item);
                                    _focusNode.unfocus();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                widget.displayString(item),
                                                style: Theme.of(context).textTheme.bodyLarge,
                                              ),
                                              if (widget.displaySubtitle != null && 
                                                  widget.displaySubtitle!(item) != null)
                                                Text(
                                                  widget.displaySubtitle!(item)!,
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (widget.displayTrailing != null && 
                                            widget.displayTrailing!(item) != null)
                                          Text(
                                            widget.displayTrailing!(item)!,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isDropdownOpen = false;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        onChanged: (value) {
          _filterItems(value);
          if (value.isEmpty) {
            widget.onChanged(null);
          }
        },
        onTap: () {
          if (!_isDropdownOpen) {
            _showOverlay();
          }
        },
        decoration: widget.decoration ?? InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
          suffixIcon: widget.showSearchIcon 
              ? const Icon(Icons.search)
              : null,
        ),
      ),
    );
  }
}
