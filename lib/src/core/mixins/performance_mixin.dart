import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../performance/performance_service.dart';

mixin PerformanceMixin {
  final PerformanceService _performanceService = Get.find<PerformanceService>();
  final Stopwatch _screenStopwatch = Stopwatch();
  
  void startScreenTracking() {
    _screenStopwatch.start();
  }
  
  void endScreenTracking(String screenName) {
    _screenStopwatch.stop();
    _performanceService.trackScreenLoad(screenName, _screenStopwatch.elapsedMilliseconds);
    _screenStopwatch.reset();
  }
  
  void trackUserAction(String action, String screen, {Map<String, dynamic>? metadata}) {
    _performanceService.trackUserInteraction(action, screen, metadata: metadata);
  }
  
  void trackMemory(String context, double memoryMB) {
    _performanceService.trackMemoryUsage(context, memoryMB);
  }
}

class PerformanceWrapper extends StatefulWidget {
  final Widget child;
  final String screenName;
  
  const PerformanceWrapper({
    super.key,
    required this.child,
    required this.screenName,
  });

  @override
  State<PerformanceWrapper> createState() => _PerformanceWrapperState();
}

class _PerformanceWrapperState extends State<PerformanceWrapper> with PerformanceMixin {
  @override
  void initState() {
    super.initState();
    startScreenTracking();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      endScreenTracking(widget.screenName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
