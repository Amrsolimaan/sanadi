import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Responsive {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
  }

  static bool isMobile() => screenWidth < 600;
  static bool isTablet() => screenWidth >= 600 && screenWidth < 1200;
  static bool isDesktop() => screenWidth >= 1200;
}

// Extensions for easy use
extension SizeExtension on num {
  double get w => ScreenUtil().setWidth(this);
  double get h => ScreenUtil().setHeight(this);
  double get sp => ScreenUtil().setSp(this);
  double get r => ScreenUtil().radius(this);
}
