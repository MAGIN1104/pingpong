import 'package:flutter/material.dart';

class DeviceHelper {
  // Detectar si el dispositivo tiene navegación por gestos
  static bool hasGestureNavigation(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.bottom > 0;
  }

  // Obtener el padding inferior del dispositivo
  static double bottomPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  // Obtener el padding superior del dispositivo
  static double topPadding(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  // Verificar si es un dispositivo con notch o Dynamic Island
  static bool hasNotch(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return padding.top > 24; // Más de 24px indica notch/Dynamic Island
  }

  // Obtener información completa del dispositivo
  static DeviceInfo getDeviceInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;
    final viewInsets = mediaQuery.viewInsets;

    return DeviceInfo(
      hasGestureNavigation: padding.bottom > 0,
      hasNotch: padding.top > 24,
      bottomPadding: padding.bottom,
      topPadding: padding.top,
      leftPadding: padding.left,
      rightPadding: padding.right,
      screenHeight: mediaQuery.size.height,
      screenWidth: mediaQuery.size.width,
      keyboardHeight: viewInsets.bottom,
    );
  }

  // Crear SafeArea personalizado según el tipo de dispositivo
  static Widget createAdaptiveSafeArea({
    required Widget child,
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
    double? minimum,
    EdgeInsets? minimumPadding,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceInfo = getDeviceInfo(context);

        // Ajustar el SafeArea según el tipo de dispositivo
        return SafeArea(
          top: top,
          bottom: bottom,
          left: left,
          right: right,
          minimum: minimumPadding ?? EdgeInsets.zero,
          child: Container(
            // Agregar padding adicional si es necesario
            padding: _getAdditionalPadding(deviceInfo),
            child: child,
          ),
        );
      },
    );
  }

  // Obtener padding adicional según el tipo de dispositivo
  static EdgeInsets _getAdditionalPadding(DeviceInfo deviceInfo) {
    EdgeInsets additionalPadding = EdgeInsets.zero;

    // Para dispositivos con navegación por gestos, agregar un poco más de padding
    if (deviceInfo.hasGestureNavigation) {
      additionalPadding = const EdgeInsets.only(bottom: 8.0);
    }

    // Para dispositivos con notch, asegurar que el contenido no se superponga
    if (deviceInfo.hasNotch) {
      additionalPadding = additionalPadding.copyWith(
        top: additionalPadding.top + 4.0,
      );
    }

    return additionalPadding;
  }

  // Verificar si el contenido se ajusta bien en la pantalla
  static bool isContentFitting(BuildContext context, double contentHeight) {
    final deviceInfo = getDeviceInfo(context);
    final availableHeight =
        deviceInfo.screenHeight -
        deviceInfo.topPadding -
        deviceInfo.bottomPadding;

    return contentHeight <= availableHeight;
  }
}

class DeviceInfo {
  final bool hasGestureNavigation;
  final bool hasNotch;
  final double bottomPadding;
  final double topPadding;
  final double leftPadding;
  final double rightPadding;
  final double screenHeight;
  final double screenWidth;
  final double keyboardHeight;

  const DeviceInfo({
    required this.hasGestureNavigation,
    required this.hasNotch,
    required this.bottomPadding,
    required this.topPadding,
    required this.leftPadding,
    required this.rightPadding,
    required this.screenHeight,
    required this.screenWidth,
    required this.keyboardHeight,
  });

  // Obtener el área segura disponible
  double get safeAreaHeight => screenHeight - topPadding - bottomPadding;
  double get safeAreaWidth => screenWidth - leftPadding - rightPadding;

  // Verificar si es un dispositivo pequeño
  bool get isSmallDevice => screenHeight < 700;

  // Verificar si es un dispositivo con pantalla grande
  bool get isLargeDevice => screenHeight > 900;
}
