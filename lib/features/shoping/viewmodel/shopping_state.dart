import 'package:equatable/equatable.dart';

abstract class ShoppingState extends Equatable {
  final int currentNavIndex;

  const ShoppingState({this.currentNavIndex = 1});

  @override
  List<Object?> get props => [currentNavIndex];
}

class ShoppingInitial extends ShoppingState {
  const ShoppingInitial() : super(currentNavIndex: 1);
}

class ShoppingLoading extends ShoppingState {
  const ShoppingLoading({super.currentNavIndex});
}

class ShoppingLoaded extends ShoppingState {
  final List<ShoppingCategory> categories;

  const ShoppingLoaded({
    required this.categories,
    super.currentNavIndex,
  });

  @override
  List<Object?> get props => [categories, currentNavIndex];
}

class ShoppingError extends ShoppingState {
  final String message;

  const ShoppingError({
    required this.message,
    super.currentNavIndex,
  });

  @override
  List<Object?> get props => [message, currentNavIndex];
}

// Model for Shopping Category
class ShoppingCategory {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String buttonTextKey;
  final String iconName;
  final int colorValue;

  const ShoppingCategory({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.buttonTextKey,
    required this.iconName,
    required this.colorValue,
  });
}
