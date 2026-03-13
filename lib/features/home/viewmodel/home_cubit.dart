import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState(currentIndex: 0));

  void changeTab(int index) {
    emit(HomeState(currentIndex: index));
  }

  void resetToHome() {
    emit(const HomeState(currentIndex: 0));
  }
}
