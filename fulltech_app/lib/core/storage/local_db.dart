import 'local_db_interface.dart';
import 'local_db_io.dart' if (dart.library.html) 'local_db_web.dart' as impl;

export 'local_db_interface.dart';
export 'auth_session.dart';
export 'sync_queue_item.dart';

LocalDb getLocalDb() => impl.createLocalDb();
