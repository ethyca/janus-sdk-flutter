import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String content;
  final bool isLoading;
  final bool isError;
  final String? errorMessage;
  final bool isMultiline;

  const StatusCard({
    super.key,
    required this.title,
    required this.content,
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (isError)
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            isMultiline
                ? Text(
                    content,
                    style: TextStyle(
                      color: isError ? Colors.red : null,
                    ),
                  )
                : Text(
                    content,
                    style: TextStyle(
                      color: isError ? Colors.red : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            if (errorMessage != null && isError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
