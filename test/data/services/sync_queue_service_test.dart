import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/data/local/daos/sync_queue_dao.dart';
import 'package:vocabflip/data/models/sync_queue_item.dart';
import 'package:vocabflip/data/services/sync_queue_service.dart';

void main() {
  test(
      'syncPendingItems does not read the SQLite queue when local queue is disabled',
      () async {
    final dao = _ThrowingSyncQueueDao();
    final service = SyncQueueService(
      syncQueueDao: dao,
      disableLocalQueue: true,
    );

    await service.syncPendingItems();

    expect(dao.wasTouched, isFalse);
  });
}

class _ThrowingSyncQueueDao extends SyncQueueDao {
  bool wasTouched = false;

  @override
  Future<List<SyncQueueItem>> getPendingItems({int limit = 100}) async {
    wasTouched = true;
    throw StateError('SQLite queue should not be read');
  }
}
