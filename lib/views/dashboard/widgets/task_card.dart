import 'package:flutter/material.dart';
import 'package:sptm/core/constants.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final VoidCallback? onToggleDone;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.done = false,
    this.onToggleDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggleDone,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(AppColors.primary),
                  width: 3,
                ),
                color: done
                    ? const Color(AppColors.primary)
                    : Colors.transparent,
              ),
              child: done
                  ? const Icon(
                      Icons.check,
                      color: Color(AppColors.textMain),
                      size: 20,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: done
                        ? const Color(AppColors.textMuted)
                        : const Color(AppColors.textMain),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
