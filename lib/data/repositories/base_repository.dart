import '../../core/network/dio_client.dart';

/// Base Repository
/// Abstract base class for all repositories
abstract class BaseRepository {
  final DioClient dioClient;

  BaseRepository({DioClient? client}) : dioClient = client ?? DioClient();
}
