import 'package:flutter/cupertino.dart';

import 'log/log_record.dart';
import 'log/logs_repository.dart';

class LogsController extends ChangeNotifier {
  final LogsRepository _logsRepository;

  LogsController(this._logsRepository);

  List<LogRecord> logs = [];
  bool loading = false;

  Future<void> notifyChanged() async {
    loading = true;
    notifyListeners();

    logs = await _logsRepository.getRecent();

    loading = false;
    notifyListeners();
  }
}
