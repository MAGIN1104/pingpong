import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/utils/device_helper.dart';

class AdaptiveGameLayout extends StatelessWidget {
  final Widget child;
  final bool showFloatingButtons;
  final List<Widget>? floatingButtons;

  const AdaptiveGameLayout({
    super.key,
    required this.child,
    this.showFloatingButtons = true,
    this.floatingButtons,
  });

  @override
  Widget build(BuildContext context) {
    final deviceInfo = DeviceHelper.getDeviceInfo(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular el espacio disponible
        final availableHeight = constraints.maxHeight;

        // Determinar si necesitamos ajustar el layout
        final needsCompactLayout =
            availableHeight < 600 || deviceInfo.isSmallDevice;

        return Stack(
          children: [
            // Contenido principal
            Positioned.fill(
              child: _buildMainContent(context, deviceInfo, needsCompactLayout),
            ),

            // Botones flotantes adaptativos
            if (showFloatingButtons)
              _buildAdaptiveFloatingButtons(
                context,
                deviceInfo,
                needsCompactLayout,
              ),
          ],
        );
      },
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    DeviceInfo deviceInfo,
    bool needsCompactLayout,
  ) {
    return Container(
      padding: EdgeInsets.only(
        bottom: _getBottomPadding(deviceInfo, needsCompactLayout),
        top: _getTopPadding(deviceInfo),
        left: _getSidePadding(deviceInfo),
        right: _getSidePadding(deviceInfo),
      ),
      child: child,
    );
  }

  Widget _buildAdaptiveFloatingButtons(
    BuildContext context,
    DeviceInfo deviceInfo,
    bool needsCompactLayout,
  ) {
    if (floatingButtons == null || floatingButtons!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: _getFloatingButtonBottomPosition(deviceInfo, needsCompactLayout),
      right: _getFloatingButtonRightPosition(deviceInfo),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            floatingButtons!
                .map(
                  (button) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: button,
                  ),
                )
                .toList(),
      ),
    );
  }

  double _getBottomPadding(DeviceInfo deviceInfo, bool needsCompactLayout) {
    double padding = deviceInfo.bottomPadding;

    // Agregar padding adicional para dispositivos con navegación por gestos
    if (deviceInfo.hasGestureNavigation) {
      padding += 16.0;
    }

    // Reducir padding en dispositivos pequeños
    if (needsCompactLayout) {
      padding = padding * 0.7;
    }

    return padding;
  }

  double _getTopPadding(DeviceInfo deviceInfo) {
    double padding = deviceInfo.topPadding;

    // Agregar padding adicional para dispositivos con notch
    if (deviceInfo.hasNotch) {
      padding += 8.0;
    }

    return padding;
  }

  double _getSidePadding(DeviceInfo deviceInfo) {
    // Padding lateral mínimo para evitar que el contenido toque los bordes
    return math.max(deviceInfo.leftPadding, deviceInfo.rightPadding) + 8.0;
  }

  double _getFloatingButtonBottomPosition(
    DeviceInfo deviceInfo,
    bool needsCompactLayout,
  ) {
    double position = deviceInfo.bottomPadding;

    // Ajustar posición según el tipo de navegación
    if (deviceInfo.hasGestureNavigation) {
      position += 16.0;
    } else {
      position += 8.0;
    }

    // Ajustar para dispositivos pequeños
    if (needsCompactLayout) {
      position = position * 0.8;
    }

    return position;
  }

  double _getFloatingButtonRightPosition(DeviceInfo deviceInfo) {
    return deviceInfo.rightPadding + 16.0;
  }
}

// Widget para detectar y mostrar información del dispositivo (solo para debug)
class DeviceInfoDebugWidget extends StatelessWidget {
  const DeviceInfoDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceInfo = DeviceHelper.getDeviceInfo(context);

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device Info',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          Text(
            'Gesture Nav: ${deviceInfo.hasGestureNavigation}',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'Has Notch: ${deviceInfo.hasNotch}',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'Bottom Padding: ${deviceInfo.bottomPadding.toStringAsFixed(1)}',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'Screen: ${deviceInfo.screenWidth.toInt()}x${deviceInfo.screenHeight.toInt()}',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
