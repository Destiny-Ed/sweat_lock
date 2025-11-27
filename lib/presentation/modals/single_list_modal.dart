import 'package:flutter/material.dart';
import 'package:sweat_lock/core/enums.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/core/theme.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

Future<String?> showGenrePickerBottomSheet({
  required BuildContext context,
  required List<String> items,
  String title = "select title",
  required String? currentSelected,
  required Function(String) onGenreSelected,
}) async {
  String? localSelected = currentSelected;

  return await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
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
                const SizedBox(height: 20),
                Text(title.cap, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: List.generate(items.length, (index) {
                      final genre = items[index];
                      final isSelected =
                          localSelected?.toLowerCase() == genre.toLowerCase();

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            localSelected = genre;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.only(right: 10, left: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Theme.of(context).cardColor,
                            border: isSelected
                                ? Border.all(
                                    color: AppColors.primaryGreen,
                                  ) // AppColors.primaryGreen
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: Text(
                                  genre.cap, // assuming you have an extension
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              Checkbox(
                                shape: const OvalBorder(),
                                value: isSelected,
                                onChanged: (value) {
                                  setState(() {
                                    localSelected = genre;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                CustomButton(
                  text: "done",
                  onTap: () {
                    onGenreSelected(localSelected ?? "");
                    Navigator.of(context).pop(localSelected);
                  },
                ),
                40.height(),
              ],
            ),
          );
        },
      );
    },
  );
}
