import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../performance/performance_service.dart';

class PerformanceDashboard extends StatelessWidget {
  const PerformanceDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final performanceService = Get.find<PerformanceService>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Metrics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Get.back();
              Get.to(() => const PerformanceDashboard());
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              await performanceService.generateHtmlReport();
              Get.snackbar(
                'Report Generated',
                'Performance report saved to performance_reports folder',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsOverview(performanceService),
            const SizedBox(height: 24),
            _buildPerformanceTable(performanceService),
            const SizedBox(height: 24),
            _buildDetailedMetrics(performanceService),
            const SizedBox(height: 24),
            _buildActionButtons(performanceService),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsOverview(PerformanceService service) {
    final metrics = service.getPerformanceMetrics();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: Get.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildMetricCard(
                  'API Response',
                  '${metrics.avgApiResponseTime.toStringAsFixed(0)}ms',
                  _getPerformanceColor(metrics.avgApiResponseTime, 1000, true),
                  Icons.api,
                ),
                _buildMetricCard(
                  'Screen Load',
                  '${metrics.avgScreenLoadTime.toStringAsFixed(0)}ms',
                  _getPerformanceColor(metrics.avgScreenLoadTime, 2000, true),
                  Icons.phone_android,
                ),
                _buildMetricCard(
                  'Memory Usage',
                  '${metrics.avgMemoryUsage.toStringAsFixed(1)}MB',
                  _getPerformanceColor(metrics.avgMemoryUsage, 200, true),
                  Icons.memory,
                ),
                _buildMetricCard(
                  'Error Rate',
                  '${(metrics.errorRate * 100).toStringAsFixed(1)}%',
                  _getPerformanceColor(metrics.errorRate, 0.05, true),
                  Icons.error_outline,
                ),
                _buildMetricCard(
                  'Accuracy',
                  '${(metrics.accuracy * 100).toStringAsFixed(1)}%',
                  _getPerformanceColor(metrics.accuracy, 0.8, false),
                  Icons.check_circle_outline,
                ),
                _buildMetricCard(
                  'Precision',
                  '${(metrics.precision * 100).toStringAsFixed(1)}%',
                  _getPerformanceColor(metrics.precision, 0.8, false),
                  Icons.center_focus_strong,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTable(PerformanceService service) {
    final metrics = service.getPerformanceMetrics();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Comparison',
              style: Get.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Color(0xFF0EA5E9)),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Dataset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Precision', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Accuracy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Recall', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('TNR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Carwaan App', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('${(metrics.precision * 100).toStringAsFixed(1)}%'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('${(metrics.accuracy * 100).toStringAsFixed(1)}%'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('${(metrics.recall * 100).toStringAsFixed(1)}%'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text('${(metrics.tnr * 100).toStringAsFixed(1)}%'),
                    ),
                  ],
                ),
                const TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Industry Benchmark'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('88.5%'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('92.0%'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('85.0%'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('94.0%'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics(PerformanceService service) {
    final metrics = service.getPerformanceMetrics();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Statistics',
              style: Get.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Total API Calls', '${metrics.totalApiCalls}'),
            _buildDetailRow('Total Screen Loads', '${metrics.totalScreenLoads}'),
            _buildDetailRow('Session Duration', '${metrics.sessionDuration.inMinutes}m ${metrics.sessionDuration.inSeconds % 60}s'),
            _buildDetailRow('Slowest API', metrics.slowestApi ?? 'N/A'),
            _buildDetailRow('Slowest Screen', metrics.slowestScreen ?? 'N/A'),
            _buildDetailRow('Highest Memory Context', metrics.highestMemoryUsage ?? 'N/A'),
            _buildDetailRow('Recent Network Calls', '${metrics.networkMetrics.length}'),
            _buildDetailRow('User Interactions', '${metrics.userInteractions.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActionButtons(PerformanceService service) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await service.generateHtmlReport();
              Get.snackbar(
                'Success',
                'HTML report generated successfully!',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.file_download),
            label: const Text('Generate HTML Report'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              service.clearMetrics();
              Get.snackbar(
                'Cleared',
                'All metrics have been cleared',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Metrics'),
          ),
        ),
      ],
    );
  }

  Color _getPerformanceColor(double value, double threshold, bool lowerIsBetter) {
    if (lowerIsBetter) {
      if (value <= threshold * 0.5) return Colors.green;
      if (value <= threshold) return Colors.orange;
      return Colors.red;
    } else {
      if (value >= threshold) return Colors.green;
      if (value >= threshold * 0.8) return Colors.orange;
      return Colors.red;
    }
  }
}
