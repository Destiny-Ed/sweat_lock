import 'package:flutter/material.dart';
import 'package:sweat_lock/core/extensions.dart';
import 'package:sweat_lock/presentation/widgets/social_button.dart';

class ErrorReloadStateWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;
  const ErrorReloadStateWidget({
    super.key,
    required this.onRetry,
    this.message = "failed to load",
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 20,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.white70),
          Text(
            (message ?? "failed to load").cap,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white70),
          ),
          Semantics(
            label: "Retry Image Button",
            child: SizedBox(
              width: context.screenSize().width / 3,
              child: CustomButton(text: "Retry", onTap: onRetry),
            ),
          ),
        ],
      ),
    );
  }
}
