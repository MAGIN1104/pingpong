import 'package:flutter/material.dart';
import '../../../../core/utils/device_helper.dart';

class AdaptiveSetupLayout extends StatelessWidget {
  final Widget child;
  final bool showDebugInfo;

  const AdaptiveSetupLayout({
    super.key,
    required this.child,
    this.showDebugInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final deviceInfo = DeviceHelper.getDeviceInfo(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final needsCompactLayout =
            availableHeight < 700 || deviceInfo.isSmallDevice;

        return Stack(
          children: [
            // Contenido principal con padding adaptativo
            Positioned.fill(
              child: Container(
                padding: _getAdaptivePadding(deviceInfo, needsCompactLayout),
                child: child,
              ),
            ),

            // Información de debug (opcional)
            if (showDebugInfo)
              Positioned(top: 8, right: 8, child: _buildDebugInfo(deviceInfo)),
          ],
        );
      },
    );
  }

  EdgeInsets _getAdaptivePadding(
    DeviceInfo deviceInfo,
    bool needsCompactLayout,
  ) {
    double horizontalPadding = 16.0;
    double verticalPadding = 16.0;

    // Ajustar padding horizontal según el ancho de pantalla
    if (deviceInfo.screenWidth < 400) {
      horizontalPadding = 12.0;
    } else if (deviceInfo.screenWidth > 600) {
      horizontalPadding = 24.0;
    }

    // Ajustar padding vertical según la altura disponible
    if (needsCompactLayout) {
      verticalPadding = 8.0;
    } else if (deviceInfo.screenHeight > 900) {
      verticalPadding = 24.0;
    }

    // Agregar padding adicional para dispositivos con navegación por gestos
    if (deviceInfo.hasGestureNavigation) {
      verticalPadding += 8.0;
    }

    return EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    );
  }

  Widget _buildDebugInfo(DeviceInfo deviceInfo) {
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
            'Setup Layout',
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
            'Bottom Padding: ${deviceInfo.bottomPadding.toStringAsFixed(1)}',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          Text(
            'Available: ${deviceInfo.safeAreaHeight.toStringAsFixed(1)}',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// Widget para manejar listas con desbordamiento
class AdaptiveScrollableList extends StatelessWidget {
  final List<Widget> children;
  final ScrollController? controller;
  final EdgeInsets? padding;

  const AdaptiveScrollableList({
    super.key,
    required this.children,
    this.controller,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final needsScrollable = children.length > 5 || availableHeight < 400;

        if (needsScrollable) {
          return SingleChildScrollView(
            controller: controller,
            padding: padding ?? EdgeInsets.zero,
            child: Column(children: children),
          );
        } else {
          return Column(children: children);
        }
      },
    );
  }
}
