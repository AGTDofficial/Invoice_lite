import 'package:flutter/material.dart';

class StateDropdown extends StatefulWidget {
  final String? selectedState;
  final ValueChanged<String?> onChanged;
  final List<String> states;
  final String label;

  const StateDropdown({
    super.key,
    required this.selectedState,
    required this.onChanged,
    required this.states,
    this.label = "Select State",
  });

  @override
  State<StateDropdown> createState() => _StateDropdownState();
}

class _StateDropdownState extends State<StateDropdown> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.selectedState ?? '');
  }

  @override
  void didUpdateWidget(covariant StateDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedState != oldWidget.selectedState) {
      _controller.text = widget.selectedState ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.selectedState ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return widget.states;
        }
        return widget.states.where((String state) =>
            state.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (String selection) {
        _controller.text = selection;
        widget.onChanged(selection);
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _controller = controller;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            // If the user types something not in the list, don't call onChanged
            if (!widget.states.contains(value)) {
              widget.onChanged(null);
            }
          },
          onFieldSubmitted: (value) {
            if (!widget.states.contains(value)) {
              controller.clear();
              widget.onChanged(null);
            }
          },
          onEditingComplete: () {
            if (!widget.states.contains(controller.text)) {
              controller.clear();
              widget.onChanged(null);
            }
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
} 