import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'shopping_state.dart';

class ShoppingCubit extends Cubit<ShoppingState> {
  ShoppingCubit() : super(const ShoppingInitial()) {
    _loadCategories();
  }

  // Default categories
  final List<ShoppingCategory> _defaultCategories = const [
    ShoppingCategory(
      id: 'groceries',
      titleKey: 'shopping.groceries',
      descriptionKey: 'shopping.groceries_desc',
      buttonTextKey: 'shopping.shop_groceries',
      iconName: 'shopping_basket',
      colorValue: 0xFF7CB342, // Green - secondary
    ),
    ShoppingCategory(
      id: 'pharmacy',
      titleKey: 'shopping.pharmacy',
      descriptionKey: 'shopping.pharmacy_desc',
      buttonTextKey: 'shopping.shop_pharmacy',
      iconName: 'local_pharmacy',
      colorValue: 0xFFF5931E, // Orange
    ),
    ShoppingCategory(
      id: 'household',
      titleKey: 'shopping.household',
      descriptionKey: 'shopping.household_desc',
      buttonTextKey: 'shopping.shop_household',
      iconName: 'home_outlined',
      colorValue: 0xFF0095DA, // Blue - primary
    ),
    ShoppingCategory(
      id: 'personal_care',
      titleKey: 'shopping.personal_care',
      descriptionKey: 'shopping.personal_care_desc',
      buttonTextKey: 'shopping.shop_personal_care',
      iconName: 'spa_outlined',
      colorValue: 0xFF9C27B0, // Purple
    ),
  ];

  void _loadCategories() {
    emit(const ShoppingLoading());
    try {
      emit(ShoppingLoaded(categories: _defaultCategories));
    } catch (e) {
      emit(ShoppingError(message: e.toString()));
    }
  }

  void changeNavIndex(int index) {
    if (state is ShoppingLoaded) {
      emit(ShoppingLoaded(
        categories: (state as ShoppingLoaded).categories,
        currentNavIndex: index,
      ));
    } else {
      emit(ShoppingLoaded(
        categories: _defaultCategories,
        currentNavIndex: index,
      ));
    }
  }

  void refreshCategories() {
    _loadCategories();
  }

  // Get icon from string name
  static IconData getIconFromName(String iconName) {
    switch (iconName) {
      case 'shopping_basket':
        return Icons.shopping_basket;
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'home_outlined':
        return Icons.home_outlined;
      case 'spa_outlined':
        return Icons.spa_outlined;
      default:
        return Icons.category;
    }
  }
}
