import 'package:flutter/material.dart';
import 'package:sweat_lock/core/enums.dart';
import 'package:sweat_lock/core/theme.dart';

/// Shows a bottom sheet where user can select multiple genres
/// Returns the final selected list when "Done" is tapped
Future<List<String>?> showMultiGenrePickerBottomSheet({
  required BuildContext context,
  required List<String> items,
  required List<String> initiallySelected, // currently selected genres
  String title = "Select Items",
}) async {
  return await showModalBottomSheet<List<String>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _MultiGenrePickerSheet(
      items: items,
      initiallySelected: initiallySelected,
      title: title,
    ),
  );
}

// Private StatefulWidget for the sheet content
class _MultiGenrePickerSheet extends StatefulWidget {
  final List<String> items;
  final List<String> initiallySelected;
  final String title;

  const _MultiGenrePickerSheet({
    required this.items,
    required this.initiallySelected,
    required this.title,
  });

  @override
  State<_MultiGenrePickerSheet> createState() => _MultiGenrePickerSheetState();
}

class _MultiGenrePickerSheetState extends State<_MultiGenrePickerSheet> {
  late List<String> _selectedGenres;

  @override
  void initState() {
    super.initState();
    _selectedGenres = List.from(widget.initiallySelected);
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else {
        _selectedGenres.add(genre);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Title + Done button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () => Navigator.pop(context, _selectedGenres),
                child: Text(
                  "Done",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Genre List
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: List.generate(widget.items.length, (index) {
                final genre = widget.items[index];
                final isSelected = _selectedGenres.contains(genre);

                return GestureDetector(
                  onTap: () => _toggleGenre(genre),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.only(
                      right: 10,
                      left: 20,
                      top: 12,
                      bottom: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Theme.of(context).cardColor,
                      border: isSelected
                          ? Border.all(color: AppColors.primaryGreen)
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: Text(
                            genre.cap,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Checkbox(
                          shape: const OvalBorder(),
                          value: isSelected,
                          activeColor: AppColors.primaryGreen,
                          onChanged: (value) => _toggleGenre(genre),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          10.height(),
        ],
      ),
    );
  }
}
