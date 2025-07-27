import 'package:flutter/material.dart';

/// Общие отступы для всего приложения
class AppSpacing {
  // Вертикальные отступы
  static const SizedBox height4 = SizedBox(height: 4);
  static const SizedBox height6 = SizedBox(height: 6);
  static const SizedBox height8 = SizedBox(height: 8);
  static const SizedBox height12 = SizedBox(height: 12);
  static const SizedBox height16 = SizedBox(height: 16);
  static const SizedBox height20 = SizedBox(height: 20);
  static const SizedBox height24 = SizedBox(height: 24);

  // Горизонтальные отступы
  static const SizedBox width6 = SizedBox(width: 6);
  static const SizedBox width8 = SizedBox(width: 8);
  static const SizedBox width10 = SizedBox(width: 10);
  static const SizedBox width12 = SizedBox(width: 12);
  static const SizedBox width16 = SizedBox(width: 16);

  // Отступы для padding
  static const EdgeInsets paddingAll8 = EdgeInsets.all(8.0);
  static const EdgeInsets paddingAll12 = EdgeInsets.all(12.0);
  static const EdgeInsets paddingAll16 = EdgeInsets.all(16.0);
  static const EdgeInsets paddingAll20 = EdgeInsets.all(20.0);

  static const EdgeInsets paddingHorizontal16 =
      EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets paddingVertical8 =
      EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets paddingVertical12 =
      EdgeInsets.symmetric(vertical: 12.0);
  static const EdgeInsets paddingVertical16 =
      EdgeInsets.symmetric(vertical: 16.0);

  static const EdgeInsets paddingHorizontal8Vertical4 =
      EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  static const EdgeInsets paddingHorizontal12Vertical6 =
      EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0);
  static const EdgeInsets paddingHorizontal16Vertical8 =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
  static const EdgeInsets paddingHorizontal16Vertical12 =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  // Отступы для margin
  static const EdgeInsets marginBottom16 = EdgeInsets.only(bottom: 16);
  static const EdgeInsets marginLeft16 = EdgeInsets.only(left: 16);
  static const EdgeInsets marginHorizontal16 =
      EdgeInsets.symmetric(horizontal: 16.0);

  // Отступы для разделителей
  static const EdgeInsets dividerPadding =
      EdgeInsets.symmetric(horizontal: 16.0);
}
