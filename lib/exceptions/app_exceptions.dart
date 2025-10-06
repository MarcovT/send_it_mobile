// Custom exceptions for the SEND-IT Replays app
// These provide better error handling and more specific error messages

// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final dynamic originalError;

  const AppException(this.message, {this.originalError});

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(
    super.message, {
    this.statusCode,
    super.originalError,
  });

  /// Factory constructors for common network errors
  factory NetworkException.noInternet() {
    return const NetworkException(
      'No internet connection. Please check your network settings.',
    );
  }

  factory NetworkException.timeout() {
    return const NetworkException(
      'Request timed out. Please try again.',
    );
  }

  factory NetworkException.serverError([int? statusCode]) {
    return NetworkException(
      'Server error occurred. Please try again later.',
      statusCode: statusCode,
    );
  }

  factory NetworkException.unauthorized() {
    return const NetworkException(
      'Unauthorized access. Please check your credentials.',
      statusCode: 401,
    );
  }

  factory NetworkException.notFound([String? resource]) {
    return NetworkException(
      resource != null
          ? '$resource not found'
          : 'The requested resource was not found',
      statusCode: 404,
    );
  }
}

/// Data-related exceptions
class DataException extends AppException {
  const DataException(super.message, {super.originalError});

  factory DataException.parsing([String? details]) {
    return DataException(
      details != null
          ? 'Failed to parse data: $details'
          : 'Failed to parse data from server',
    );
  }

  factory DataException.validation(String fieldName) {
    return DataException('Invalid $fieldName');
  }
}

/// Video-related exceptions
class VideoException extends AppException {
  final String? videoId;

  const VideoException(
    super.message, {
    this.videoId,
    super.originalError,
  });

  factory VideoException.notFound(String videoId) {
    return VideoException(
      'Video not found',
      videoId: videoId,
    );
  }

  factory VideoException.loadFailed([String? videoId]) {
    return VideoException(
      'Failed to load video. Please try again.',
      videoId: videoId,
    );
  }

  factory VideoException.downloadFailed([String? videoId]) {
    return VideoException(
      'Failed to download video. Please check your internet connection.',
      videoId: videoId,
    );
  }
}

/// Club/Court related exceptions
class ClubException extends AppException {
  const ClubException(super.message, {super.originalError});

  factory ClubException.notFound() {
    return const ClubException('No clubs found in your area');
  }

  factory ClubException.loadFailed() {
    return const ClubException(
      'Failed to load clubs. Please check your internet connection.',
    );
  }
}

/// Location-related exceptions
class LocationException extends AppException {
  const LocationException(super.message, {super.originalError});

  factory LocationException.permissionDenied() {
    return const LocationException(
      'Location permission denied. Please enable location access in settings.',
    );
  }

  factory LocationException.serviceDisabled() {
    return const LocationException(
      'Location services are disabled. Please enable them in settings.',
    );
  }

  factory LocationException.unavailable() {
    return const LocationException(
      'Unable to determine your location. Please try again.',
    );
  }
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException(super.message, {super.originalError});

  factory StorageException.permissionDenied() {
    return const StorageException(
      'Storage permission denied. Please enable storage access in settings.',
    );
  }

  factory StorageException.insufficientSpace() {
    return const StorageException(
      'Insufficient storage space. Please free up some space and try again.',
    );
  }

  factory StorageException.saveFailed() {
    return const StorageException(
      'Failed to save file. Please try again.',
    );
  }
}
