import 'package:coupon_app/core/log/logger.dart';
import 'package:coupon_app/core/logs_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/log/log_record.dart';
import '../core/log/log_level.dart';
import '../core/settings_controller.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  late bool _loggingEnabled;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>();
    _loggingEnabled = settings.logsEnabled;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LogsController>();
    final settings = context.read<SettingsController>();
    final dateFormat = DateFormat('dd.MM HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.notifyChanged(),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Logs enabled'),
            value: _loggingEnabled,
            onChanged: (value) {
              setState(() => _loggingEnabled = value);
              settings.setEnabledLogs(value);
              AppLogger.instance.setEnabled(value);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: Builder(
              builder: (context) {
                final logs = controller.logs;

                if (controller.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (logs.isEmpty) {
                  return const Center(child: Text('Logs empty'));
                }

                final grouped = _groupByChain(logs);

                return ListView.separated(
                  itemCount: grouped.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final group = grouped[index];
                    final chainId = group.chainId ?? 'Без chainId';
                    final maxLevel = group.maxLevel;
                    final lastTime = dateFormat.format(group.lastTimestamp);

                    return ExpansionTile(
                      leading: _buildLevelIcon(maxLevel),
                      title: Text(
                        chainId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${group.events.length} log. • $lastTime'),
                      children: group.events.map((log) {
                        final time = dateFormat.format(log.timestamp);
                        return ListTile(
                          dense: true,
                          leading: _buildLevelIcon(log.level, small: true),
                          title: Text(
                            log.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '$time • ${log.category.name}'
                            '${log.details != null ? ' • ${log.details}' : ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _showLogDetails(context, log),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelIcon(LogLevel level, {bool small = false}) {
    IconData icon;
    switch (level) {
      case LogLevel.debug:
        icon = Icons.bug_report;
        break;
      case LogLevel.info:
        icon = Icons.info_outline;
        break;
      case LogLevel.warning:
        icon = Icons.warning_amber_rounded;
        break;
      case LogLevel.error:
        icon = Icons.error_outline;
        break;
      case LogLevel.critical:
        icon = Icons.report;
        break;
    }

    return Icon(icon, size: small ? 18 : 24);
  }

  void _showLogDetails(BuildContext context, LogRecord log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final dateFormatFull = DateFormat('dd.MM.yyyy HH:mm:ss.SSS');
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Event detail',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _detailRow('Time', dateFormatFull.format(log.timestamp)),
                _detailRow('Level', log.level.name),
                _detailRow('Category', log.category.name),
                if (log.chainId != null) _detailRow('Chain ID', log.chainId!),
                const SizedBox(height: 8),
                Text(log.message, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                if (log.details != null) ...[
                  const Text(
                    'Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(log.details!),
                  const SizedBox(height: 8),
                ],
                if (log.errorType != null) ...[
                  _detailRow('Error type', log.errorType!),
                  const SizedBox(height: 4),
                ],
                if (log.errorStack != null) ...[
                  const Text(
                    'Stacktrace:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      log.errorStack!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                if (log.extraJson != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Extra:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      log.extraJson!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<_LogChainGroup> _groupByChain(List<LogRecord> logs) {
    final Map<String?, List<LogRecord>> map = {};

    for (final log in logs) {
      final key = log.chainId;
      map.putIfAbsent(key, () => []).add(log);
    }

    return map.entries.map((entry) {
      final events = entry.value
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      LogLevel maxLevel = events.first.level;
      DateTime lastTime = events.last.timestamp;

      for (final e in events) {
        if (_severity(e.level) > _severity(maxLevel)) {
          maxLevel = e.level;
        }
        if (e.timestamp.isAfter(lastTime)) {
          lastTime = e.timestamp;
        }
      }

      return _LogChainGroup(
        chainId: entry.key,
        events: events,
        maxLevel: maxLevel,
        lastTimestamp: lastTime,
      );
    }).toList()..sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
  }

  int _severity(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 0;
      case LogLevel.info:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.error:
        return 3;
      case LogLevel.critical:
        return 4;
    }
  }
}

class _LogChainGroup {
  final String? chainId;
  final List<LogRecord> events;
  final LogLevel maxLevel;
  final DateTime lastTimestamp;

  _LogChainGroup({
    required this.chainId,
    required this.events,
    required this.maxLevel,
    required this.lastTimestamp,
  });
}
