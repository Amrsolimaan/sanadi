import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String text;
  final String? highlightedText;
  final VoidCallback? onHighlightedTap;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.text,
    this.highlightedText,
    this.onHighlightedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24.w,
          height: 24.h,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.r),
            ),
            side: BorderSide(
              color: AppColors.grey,
              width: 1.5,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                children: [
                  TextSpan(text: text),
                  if (highlightedText != null) ...[
                    const TextSpan(text: ' '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: onHighlightedTap,
                        child: Text(
                          highlightedText!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
