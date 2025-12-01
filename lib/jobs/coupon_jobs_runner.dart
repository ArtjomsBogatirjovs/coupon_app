import 'dart:async';

typedef Job = Future<bool> Function();

class CouponJobsRunner {
  Timer? _timer;
  bool _processing = false;

  void call(Job job) {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _tick(job));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick(Job job) {
    if (_processing) return;
    _processing = true;

    job()
        .then((keepRunning) {
          if (!keepRunning) {
            stop();
          }
        })
        .catchError((e, s) {
          print('CouponJobsRunner error: $e\n$s');
        })
        .whenComplete(() {
          _processing = false;
        });
  }
}
