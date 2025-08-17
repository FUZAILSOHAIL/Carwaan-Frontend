import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'performance_metrics.dart';

class PerformanceReporter {
  static const String _reportFileName = 'carwaan_performance_report.html';
  static const String _reportsDir = 'performance_reports';

  Future<void> generateHtmlReport(PerformanceMetrics metrics) async {
    try {
      final htmlContent = _generateHtmlContent(metrics);
      final file = File('$_reportsDir/$_reportFileName');
      
      // Ensure directory exists
      await file.parent.create(recursive: true);
      
      // Write HTML file
      await file.writeAsString(htmlContent);
      
      if (kDebugMode) {
        print('📊 Performance report generated: ${file.absolute.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating performance report: $e');
      }
    }
  }

  String _generateHtmlContent(PerformanceMetrics metrics) {
    final timestamp = DateTime.now().toIso8601String();
    
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Carwaan - Performance Report</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
            margin: 0;
            padding: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            margin: 0;
            font-size: 2.5em;
            font-weight: 300;
            letter-spacing: 2px;
        }
        
        .header .subtitle {
            margin: 10px 0 0 0;
            font-size: 1.1em;
            opacity: 0.8;
        }
        
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            padding: 30px;
        }
        
        .metric-card {
            background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
            border-radius: 12px;
            padding: 25px;
            text-align: center;
            border-left: 5px solid #0ea5e9;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }
        
        .metric-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 30px rgba(0,0,0,0.1);
        }
        
        .metric-value {
            font-size: 2em;
            font-weight: bold;
            color: #0ea5e9;
            margin-bottom: 10px;
        }
        
        .metric-label {
            font-size: 0.9em;
            color: #64748b;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .chart-section {
            padding: 30px;
            border-top: 1px solid #e2e8f0;
        }
        
        .chart-container {
            position: relative;
            height: 400px;
            margin-bottom: 40px;
            background: white;
            border-radius: 12px;
            padding: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
        }
        
        .chart-title {
            font-size: 1.5em;
            font-weight: 600;
            color: #1e293b;
            margin-bottom: 20px;
            text-align: center;
        }
        
        .performance-table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 5px 15px rgba(0,0,0,0.08);
        }
        
        .performance-table th,
        .performance-table td {
            padding: 15px;
            text-align: center;
            border-bottom: 1px solid #e2e8f0;
        }
        
        .performance-table th {
            background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%);
            color: white;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .performance-table tbody tr:nth-child(even) {
            background: #f8fafc;
        }
        
        .performance-table tbody tr:hover {
            background: #e0f2fe;
            transform: scale(1.02);
            transition: all 0.3s ease;
        }
        
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
        }
        
        .status-excellent { background: #10b981; }
        .status-good { background: #059669; }
        .status-average { background: #f59e0b; }
        .status-poor { background: #ef4444; }
        
        .summary-section {
            padding: 30px;
            background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%);
            border-top: 1px solid #e2e8f0;
        }
        
        .timestamp {
            text-align: center;
            color: #64748b;
            font-size: 0.9em;
            margin-top: 20px;
        }
        
        .quality-badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 20px;
            font-size: 0.8em;
            font-weight: bold;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .badge-excellent { background: #dcfce7; color: #166534; }
        .badge-good { background: #dbeafe; color: #1d4ed8; }
        .badge-average { background: #fef3c7; color: #92400e; }
        .badge-poor { background: #fee2e2; color: #991b1b; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Carwaan کارواں</h1>
            <div class="subtitle">Performance Evaluation Report</div>
        </div>
        
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-value">${metrics.avgApiResponseTime.toStringAsFixed(0)}ms</div>
                <div class="metric-label">Avg API Response</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${metrics.avgScreenLoadTime.toStringAsFixed(0)}ms</div>
                <div class="metric-label">Avg Screen Load</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${metrics.avgMemoryUsage.toStringAsFixed(1)}MB</div>
                <div class="metric-label">Avg Memory Usage</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${(metrics.accuracy * 100).toStringAsFixed(1)}%</div>
                <div class="metric-label">Accuracy</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${(metrics.precision * 100).toStringAsFixed(1)}%</div>
                <div class="metric-label">Precision</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${(metrics.recall * 100).toStringAsFixed(1)}%</div>
                <div class="metric-label">Recall</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${(metrics.tnr * 100).toStringAsFixed(1)}%</div>
                <div class="metric-label">TNR</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">${(metrics.errorRate * 100).toStringAsFixed(1)}%</div>
                <div class="metric-label">Error Rate</div>
            </div>
        </div>
        
        <div class="chart-section">
            <!-- Performance Metrics Chart -->
            <div class="chart-container">
                <div class="chart-title">Performance Metrics Comparison</div>
                <canvas id="performanceChart"></canvas>
            </div>
            
            <!-- API Response Times Chart -->
            <div class="chart-container">
                <div class="chart-title">API Response Times Over Time</div>
                <canvas id="apiChart"></canvas>
            </div>
            
            <!-- Memory Usage Chart -->
            <div class="chart-container">
                <div class="chart-title">Memory Usage Distribution</div>
                <canvas id="memoryChart"></canvas>
            </div>
        </div>
        
        <!-- Performance Table -->
        <div class="summary-section">
            <h2>Performance Dataset Comparison</h2>
            <table class="performance-table">
                <thead>
                    <tr>
                        <th>Dataset</th>
                        <th>Precision</th>
                        <th>Accuracy</th>
                        <th>Recall</th>
                        <th>TNR</th>
                        <th>Quality Rating</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td><strong>Carwaan App</strong></td>
                        <td>${(metrics.precision * 100).toStringAsFixed(1)}%</td>
                        <td>${(metrics.accuracy * 100).toStringAsFixed(1)}%</td>
                        <td>${(metrics.recall * 100).toStringAsFixed(1)}%</td>
                        <td>${(metrics.tnr * 100).toStringAsFixed(1)}%</td>
                        <td>
                            <span class="status-indicator ${_getStatusClass(metrics.accuracy)}"></span>
                            <span class="quality-badge ${_getBadgeClass(metrics.accuracy)}">${_getQualityRating(metrics.accuracy)}</span>
                        </td>
                    </tr>
                    <tr>
                        <td>Benchmark (Uber)</td>
                        <td>88.5%</td>
                        <td>92.0%</td>
                        <td>85.0%</td>
                        <td>94.0%</td>
                        <td>
                            <span class="status-indicator status-excellent"></span>
                            <span class="quality-badge badge-excellent">Excellent</span>
                        </td>
                    </tr>
                    <tr>
                        <td>Industry Average</td>
                        <td>78.0%</td>
                        <td>82.0%</td>
                        <td>75.0%</td>
                        <td>85.0%</td>
                        <td>
                            <span class="status-indicator status-good"></span>
                            <span class="quality-badge badge-good">Good</span>
                        </td>
                    </tr>
                </tbody>
            </table>
            
            <div class="timestamp">
                Report generated on: $timestamp<br>
                Session duration: ${metrics.sessionDuration.inMinutes}m ${metrics.sessionDuration.inSeconds % 60}s<br>
                Total API calls: ${metrics.totalApiCalls} | Total screen loads: ${metrics.totalScreenLoads}
            </div>
        </div>
    </div>

    <script>
        // Performance Metrics Radar Chart
        const ctx1 = document.getElementById('performanceChart').getContext('2d');
        new Chart(ctx1, {
            type: 'radar',
            data: {
                labels: ['Precision', 'Accuracy', 'Recall', 'TNR', 'Response Time', 'Memory Efficiency'],
                datasets: [{
                    label: 'Carwaan App',
                    data: [
                        ${(metrics.precision * 100).toStringAsFixed(1)},
                        ${(metrics.accuracy * 100).toStringAsFixed(1)},
                        ${(metrics.recall * 100).toStringAsFixed(1)},
                        ${(metrics.tnr * 100).toStringAsFixed(1)},
                        ${_calculateResponseTimeScore(metrics.avgApiResponseTime)},
                        ${_calculateMemoryScore(metrics.avgMemoryUsage)}
                    ],
                    backgroundColor: 'rgba(14, 165, 233, 0.2)',
                    borderColor: 'rgba(14, 165, 233, 1)',
                    borderWidth: 2,
                    pointBackgroundColor: 'rgba(14, 165, 233, 1)',
                }, {
                    label: 'Industry Benchmark',
                    data: [88.5, 92.0, 85.0, 94.0, 85.0, 80.0],
                    backgroundColor: 'rgba(34, 197, 94, 0.2)',
                    borderColor: 'rgba(34, 197, 94, 1)',
                    borderWidth: 2,
                    pointBackgroundColor: 'rgba(34, 197, 94, 1)',
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'top',
                    }
                },
                scales: {
                    r: {
                        beginAtZero: true,
                        max: 100,
                        ticks: {
                            stepSize: 20
                        }
                    }
                }
            }
        });

        // API Response Times Line Chart
        const ctx2 = document.getElementById('apiChart').getContext('2d');
        const apiData = ${jsonEncode(_getApiChartData(metrics.networkMetrics))};
        new Chart(ctx2, {
            type: 'line',
            data: {
                labels: apiData.labels,
                datasets: [{
                    label: 'Response Time (ms)',
                    data: apiData.data,
                    borderColor: 'rgba(14, 165, 233, 1)',
                    backgroundColor: 'rgba(14, 165, 233, 0.1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Response Time (ms)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Time'
                        }
                    }
                }
            }
        });

        // Memory Usage Doughnut Chart
        const ctx3 = document.getElementById('memoryChart').getContext('2d');
        new Chart(ctx3, {
            type: 'doughnut',
            data: {
                labels: ['Used Memory', 'Available Memory'],
                datasets: [{
                    data: [${metrics.avgMemoryUsage.toStringAsFixed(1)}, ${(100 - metrics.avgMemoryUsage).toStringAsFixed(1)}],
                    backgroundColor: [
                        'rgba(14, 165, 233, 0.8)',
                        'rgba(226, 232, 240, 0.8)'
                    ],
                    borderColor: [
                        'rgba(14, 165, 233, 1)',
                        'rgba(226, 232, 240, 1)'
                    ],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'bottom',
                    }
                }
            }
        });
    </script>
</body>
</html>
    ''';
  }

  String _getStatusClass(double value) {
    if (value >= 0.9) return 'status-excellent';
    if (value >= 0.8) return 'status-good';
    if (value >= 0.7) return 'status-average';
    return 'status-poor';
  }

  String _getBadgeClass(double value) {
    if (value >= 0.9) return 'badge-excellent';
    if (value >= 0.8) return 'badge-good';
    if (value >= 0.7) return 'badge-average';
    return 'badge-poor';
  }

  String _getQualityRating(double value) {
    if (value >= 0.9) return 'Excellent';
    if (value >= 0.8) return 'Good';
    if (value >= 0.7) return 'Average';
    return 'Poor';
  }

  double _calculateResponseTimeScore(double avgResponseTime) {
    // Convert response time to a score (0-100)
    // Lower response time = higher score
    if (avgResponseTime <= 100) return 100;
    if (avgResponseTime <= 500) return 90;
    if (avgResponseTime <= 1000) return 80;
    if (avgResponseTime <= 2000) return 70;
    if (avgResponseTime <= 3000) return 60;
    return 50;
  }

  double _calculateMemoryScore(double avgMemoryUsage) {
    // Convert memory usage to efficiency score (0-100)
    // Lower memory usage = higher score
    if (avgMemoryUsage <= 50) return 100;
    if (avgMemoryUsage <= 100) return 90;
    if (avgMemoryUsage <= 150) return 80;
    if (avgMemoryUsage <= 200) return 70;
    if (avgMemoryUsage <= 300) return 60;
    return 50;
  }

  Map<String, dynamic> _getApiChartData(List<NetworkMetric> networkMetrics) {
    final labels = <String>[];
    final data = <int>[];
    
    // Take last 20 network calls for the chart
    final recentMetrics = networkMetrics.length > 20 
        ? networkMetrics.sublist(networkMetrics.length - 20)
        : networkMetrics;
    
    for (int i = 0; i < recentMetrics.length; i++) {
      labels.add('Call ${i + 1}');
      data.add(recentMetrics[i].responseTime);
    }
    
    return {
      'labels': labels,
      'data': data,
    };
  }
}
