import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_colors.dart';
import '../localization/language_cubit.dart';

class LanguageButton extends StatelessWidget {
  final bool isLight;

  const LanguageButton({
    super.key,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, state) {
        final isArabic = state.locale.languageCode == 'ar';

        return GestureDetector(
          onTap: () {
            context.read<LanguageCubit>().toggleLanguage(context);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isLight
                  ? AppColors.white.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  size: 18,
                  color: isLight ? AppColors.white : AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  isArabic ? 'EN' : 'عربي',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isLight ? AppColors.white : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
