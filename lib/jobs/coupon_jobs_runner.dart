import 'dart:async';
import '../core/log/app_error.dart';
import '../core/log/log_record.dart';
import '../core/log/logger.dart';

typedef Job = Future<bool> Function(String chainId);

class CouponJobsRunner {
  static final _log = AppLogger.instance.getLogger(
    category: LogCategory.job,
    source: 'CouponJobsRunner',
  );
  Timer? _timer;
  bool _processing = false;

  final Map<Job, String> _jobs = {};

  void addJob(Job job, String? chainId, {bool runJob = false}) {
    final effectiveChainId =
        chainId ?? 'coupon:${DateTime.now().microsecondsSinceEpoch}';
    _jobs[job] = effectiveChainId;
    _startIfNeeded();
    if (runJob) {
      _tick();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _jobs.clear();
  }

  void _startIfNeeded() {
    if (_timer != null) return;

    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _tick());
  }

  void _tick() {
    if (_processing) return;
    if (_jobs.isEmpty) {
      stop();
      return;
    }

    _processing = true;
    final entries = List<MapEntry<Job, String>>.from(_jobs.entries);

    Future.wait(
      entries.map((entry) async {
        final job = entry.key;
        final chainId = entry.value;
        try {
          final success = await job(chainId);
          if (success) {
            _jobs.remove(job);
          }
        } catch (e, s) {
          await _log.errorFrom(
            UnknownError(
              message: 'Job execution failed',
              detail: 'CouponJobsRunner._tick',
              cause: e,
              stackTrace: s,
            ),
            chainId: chainId,
          );
        }
      }),
    ).whenComplete(() {
      _processing = false;
      if (_jobs.isEmpty) {
        stop();
      }
    });
  }
}
