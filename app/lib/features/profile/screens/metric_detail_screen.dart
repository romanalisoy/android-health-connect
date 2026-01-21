import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import 'package:vitalgate/core/services/auth_service.dart';

/// Field configuration for display
class FieldConfig {
  final String displayName;
  final String unit;
  final IconData icon;

  const FieldConfig({
    required this.displayName,
    required this.unit,
    required this.icon,
  });
}

/// Field configurations map
const Map<String, FieldConfig> fieldConfigs = {
  'weight': FieldConfig(displayName: 'Weight', unit: 'kg', icon: Icons.monitor_weight_outlined),
  'height': FieldConfig(displayName: 'Height', unit: 'cm', icon: Icons.height),
  'bmi': FieldConfig(displayName: 'BMI', unit: '', icon: Icons.speed),
  'neck': FieldConfig(displayName: 'Neck', unit: 'cm', icon: Icons.person_outline),
  'chest': FieldConfig(displayName: 'Chest', unit: 'cm', icon: Icons.checkroom_outlined),
  'waist': FieldConfig(displayName: 'Waist', unit: 'cm', icon: Icons.straighten),
  'hips': FieldConfig(displayName: 'Hips', unit: 'cm', icon: Icons.accessibility_new),
  'shoulders': FieldConfig(displayName: 'Shoulders', unit: 'cm', icon: Icons.accessibility),
  'right_arm': FieldConfig(displayName: 'Right Bicep', unit: 'cm', icon: Icons.fitness_center),
  'left_arm': FieldConfig(displayName: 'Left Bicep', unit: 'cm', icon: Icons.fitness_center),
  'right_forearm': FieldConfig(displayName: 'Right Forearm', unit: 'cm', icon: Icons.pan_tool),
  'left_forearm': FieldConfig(displayName: 'Left Forearm', unit: 'cm', icon: Icons.pan_tool),
  'right_thigh': FieldConfig(displayName: 'Right Thigh', unit: 'cm', icon: Icons.directions_run),
  'left_thigh': FieldConfig(displayName: 'Left Thigh', unit: 'cm', icon: Icons.directions_run),
  'right_calve': FieldConfig(displayName: 'Right Calve', unit: 'cm', icon: Icons.directions_walk),
  'left_calve': FieldConfig(displayName: 'Left Calve', unit: 'cm', icon: Icons.directions_walk),
};

/// Fields where increase is bad (red) and decrease is good (green)
const Set<String> inverseColorFields = {'weight', 'waist', 'bmi'};

class MetricDetailScreen extends StatefulWidget {
  final String field;

  const MetricDetailScreen({
    super.key,
    required this.field,
  });

  @override
  State<MetricDetailScreen> createState() => _MetricDetailScreenState();
}

class _MetricDetailScreenState extends State<MetricDetailScreen> {
  final AuthService _authService = AuthService();
  BodyStatsHistory? _history;
  bool _isLoading = true;
  String? _error;
  String _selectedPeriod = 'month';

  FieldConfig get _fieldConfig =>
      fieldConfigs[widget.field] ??
      FieldConfig(displayName: widget.field, unit: 'cm', icon: Icons.straighten);

  /// Check if this field uses inverse color logic (increase = bad, decrease = good)
  bool get _useInverseColors => inverseColorFields.contains(widget.field);

  /// Get color for change value based on field type
  Color _getChangeColor(double? changeValue, Color defaultColor) {
    if (changeValue == null || changeValue == 0) return defaultColor;

    if (_useInverseColors) {
      // For weight, waist, BMI: increase is bad (red), decrease is good (green)
      return changeValue > 0 ? Colors.red : Colors.green;
    } else {
      // For other metrics: increase is good (green), decrease is bad (red)
      return changeValue > 0 ? Colors.green : Colors.red;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _authService.getBodyStatsHistory(
        widget.field,
        period: _selectedPeriod,
      );
      if (mounted) {
        setState(() {
          _history = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onPeriodChanged(String period) {
    if (_selectedPeriod != period) {
      setState(() {
        _selectedPeriod = period;
      });
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textLight;
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF2C2F35) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor.withOpacity(0.95),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _fieldConfig.displayName,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: borderColor,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.progressiveDots(
                color: AppColors.primary,
                size: 48,
              ),
            )
          : _error != null
              ? _buildErrorState(textColor, mutedColor)
              : _buildContent(isDark, surfaceColor, textColor, mutedColor, borderColor),
    );
  }

  Widget _buildErrorState(Color textColor, Color mutedColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: mutedColor),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: mutedColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor) {
    final hasData = _history != null && _history!.history.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            _buildPeriodSelector(isDark, surfaceColor),

            // Main Chart Section
            _buildChartSection(isDark, surfaceColor, textColor, mutedColor, borderColor, hasData),

            // Stats Row
            _buildStatsRow(isDark, surfaceColor, textColor, mutedColor, borderColor, hasData),

            // History Log
            _buildHistorySection(isDark, surfaceColor, textColor, mutedColor, borderColor, hasData),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark, Color surfaceColor) {
    final periods = ['month', 'year', 'all'];
    final periodLabels = {'month': 'Month', 'year': 'Year', 'all': 'All'};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: periods.map((period) {
            final isSelected = _selectedPeriod == period;
            return Expanded(
              child: GestureDetector(
                onTap: () => _onPeriodChanged(period),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF6E99F5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      periodLabels[period] ?? period,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textMuted : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChartSection(bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor, bool hasData) {
    final changePercent = _history?.changePercentage;
    final isPositive = changePercent != null && changePercent > 0;
    final isNegative = changePercent != null && changePercent < 0;
    final changeColor = _getChangeColor(changePercent, mutedColor);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_fieldConfig.displayName} Trend',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          hasData ? _history!.latestValue!.toStringAsFixed(1) : '-',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        if (_fieldConfig.unit.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, left: 4),
                            child: Text(
                              _fieldConfig.unit,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: mutedColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (changePercent != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.trending_up
                              : isNegative
                                  ? Icons.trending_down
                                  : Icons.trending_flat,
                          size: 16,
                          color: changeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: changeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            // Chart
            SizedBox(
              height: 200,
              child: hasData ? _buildChart(isDark) : _buildEmptyChart(mutedColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(bool isDark) {
    if (_history == null || _history!.history.isEmpty) {
      return const SizedBox();
    }

    // Sort history by date (oldest first for chart)
    final sortedHistory = List<BodyStatsHistoryEntry>.from(_history!.history)
      ..sort((a, b) => a.recordDate.compareTo(b.recordDate));

    if (sortedHistory.isEmpty) {
      return const SizedBox();
    }

    // Calculate min/max for Y axis
    final values = sortedHistory.map((e) => e.value).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    // Create spots for the chart
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedHistory.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedHistory[i].value));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: range > 0 ? range / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? const Color(0xFF2C2F35) : const Color(0xFFE2E8F0),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: sortedHistory.length > 5 ? (sortedHistory.length / 3).ceil().toDouble() : 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= sortedHistory.length) {
                  return const SizedBox();
                }
                final date = sortedHistory[index].recordDate;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    DateFormat('MMM d').format(date),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMuted : const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (sortedHistory.length - 1).toDouble(),
        minY: minY - padding,
        maxY: maxY + padding,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: AppColors.primary,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index < 0 || index >= sortedHistory.length) {
                  return null;
                }
                final entry = sortedHistory[index];
                return LineTooltipItem(
                  '${DateFormat('MMM d').format(entry.recordDate)}: ${entry.value.toStringAsFixed(1)}${_fieldConfig.unit}',
                  GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: sortedHistory.length < 15,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: isDark ? AppColors.surfaceDark : Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.3),
                  AppColors.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(Color mutedColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 48, color: mutedColor.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'No data available',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
          ),
          Text(
            'Start tracking to see trends',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: mutedColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor, bool hasData) {
    final average = _history?.average;
    final change = _history?.totalChange;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'AVERAGE',
              hasData && average != null ? average.toStringAsFixed(1) : '-',
              _fieldConfig.unit,
              null,
              isDark,
              surfaceColor,
              textColor,
              mutedColor,
              borderColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              'CHANGE',
              hasData && change != null
                  ? '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}'
                  : '-',
              _fieldConfig.unit,
              change,
              isDark,
              surfaceColor,
              textColor,
              mutedColor,
              borderColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    String unit,
    double? changeValue,
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    Color valueColor = textColor;
    if (changeValue != null && changeValue != 0) {
      valueColor = _getChangeColor(changeValue, textColor);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: mutedColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 4),
                child: Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: mutedColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor, bool hasData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'History Log',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!hasData)
          _buildEmptyHistory(mutedColor, borderColor)
        else
          ..._buildHistoryList(isDark, surfaceColor, textColor, mutedColor, borderColor),
      ],
    );
  }

  Widget _buildEmptyHistory(Color mutedColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.history, size: 40, color: mutedColor.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                'No history yet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHistoryList(bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor) {
    if (_history == null || _history!.history.isEmpty) {
      return [];
    }

    // Show up to 10 most recent entries
    final entries = _history!.history.take(10).toList();

    return entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2F35) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_fieldConfig.icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.value.toStringAsFixed(1)} ${_fieldConfig.unit}',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(entry.recordDate),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'SYNCED',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary.withOpacity(0.6),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today, ${DateFormat('hh:mm a').format(date)}';
    } else if (dateDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat('hh:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, hh:mm a').format(date);
    }
  }
}
