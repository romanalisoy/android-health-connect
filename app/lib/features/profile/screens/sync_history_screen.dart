import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import 'package:vitalgate/core/services/sync_history_service.dart';
import 'package:vitalgate/core/services/sync_service.dart';

class SyncHistoryScreen extends StatefulWidget {
  const SyncHistoryScreen({super.key});

  @override
  State<SyncHistoryScreen> createState() => _SyncHistoryScreenState();
}

class _SyncHistoryScreenState extends State<SyncHistoryScreen> {
  final SyncHistoryService _historyService = SyncHistoryService();
  final SyncService _syncService = SyncService();

  List<SyncHistoryEntry> _entries = [];
  SyncStats? _stats;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    final entries = await _historyService.getHistory();
    final stats = await _historyService.getStats(days: 7);

    if (mounted) {
      setState(() {
        _entries = entries;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() => _isSyncing = true);

    try {
      await _syncService.performSync(showNotifications: true);
      await _loadHistory(); // Refresh the list
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textLight;
    final mutedColor = isDark ? Colors.grey[400]! : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF2C2F35) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor.withOpacity(0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sync History',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.progressiveDots(
                color: AppColors.primary,
                size: 48,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHistory,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  // Stats Summary
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              label: 'Last 7 Days',
                              value: '${_stats?.totalRecords ?? 0}',
                              unit: 'records',
                              valueColor: AppColors.primary,
                              isDark: isDark,
                              surfaceColor: surfaceColor,
                              mutedColor: mutedColor,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              label: 'Health Score',
                              value: '${(_stats?.successRate ?? 100).toStringAsFixed(0)}%',
                              unit: 'uptime',
                              valueColor: Colors.green,
                              isDark: isDark,
                              surfaceColor: surfaceColor,
                              mutedColor: mutedColor,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Activity Log Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ACTIVITY LOG',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: mutedColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          // Filter button (placeholder for future)
                          // TextButton(
                          //   onPressed: () {},
                          //   child: Text('Filter', style: TextStyle(color: AppColors.primary)),
                          // ),
                        ],
                      ),
                    ),
                  ),

                  // History List or Empty State
                  _entries.isEmpty
                      ? SliverFillRemaining(
                          child: _buildEmptyState(isDark, mutedColor),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final entry = _entries[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildHistoryCard(
                                    entry: entry,
                                    isDark: isDark,
                                    surfaceColor: surfaceColor,
                                    textColor: textColor,
                                    mutedColor: mutedColor,
                                    borderColor: borderColor,
                                  ),
                                );
                              },
                              childCount: _entries.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
      // Floating Sync Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              backgroundColor,
              backgroundColor,
              backgroundColor.withOpacity(0),
            ],
          ),
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF6085D3)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isSyncing ? null : _handleSync,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isSyncing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_sync, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _isSyncing ? 'Syncing...' : 'Sync Now',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String unit,
    required Color valueColor,
    required bool isDark,
    required Color surfaceColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
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
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: mutedColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required SyncHistoryEntry entry,
    required bool isDark,
    required Color surfaceColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    final isSuccess = entry.isSuccess;
    final hasWarnings = entry.hasWarnings;

    final Color statusColor;
    final IconData statusIcon;

    if (isSuccess) {
      statusColor = AppColors.primary;
      statusIcon = Icons.check_circle;
    } else if (hasWarnings) {
      statusColor = Colors.amber;
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }

    return Container(
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
      child: Stack(
        children: [
          // Status Strip
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _formatDate(entry.timestamp),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (entry.isBackgroundSync) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: mutedColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'BG',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Success count
                          Row(
                            children: [
                              Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${entry.successCount} Success',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // Failed count
                          if (entry.failedCount > 0)
                            Row(
                              children: [
                                Icon(
                                  Icons.priority_high,
                                  size: 14,
                                  color: Colors.red[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${entry.failedCount} Failed',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red[400],
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              '0 Failed',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: mutedColor,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Chevron
                Icon(
                  Icons.chevron_right,
                  color: mutedColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color mutedColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              Icons.history,
              size: 48,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No sync history found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Sync Now" to start syncing',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: mutedColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
