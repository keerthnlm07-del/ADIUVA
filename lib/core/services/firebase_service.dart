import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/api_exception.dart';

/// Cloud Firestore service wrapper
/// 
/// Provides generic CRUD operations for any Firestore collection/document.
/// Handles Firestore exceptions and converts them to ApiException.
/// Supports both single-use operations and real-time listeners (streams).

class FirebaseService {
  /// Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new document
  /// 
  /// Creates a document at the specified path with the given data.
  /// If document already exists, it will be overwritten.
  /// 
  /// Parameters:
  /// - [path] - Document path (e.g., 'users/user-123')
  /// - [data] - Document data as Map
  /// 
  /// Returns:
  /// - [Future<void>] completes when document is created
  /// 
  /// Throws:
  /// - [ApiException.firestore] - If operation fails
  /// - [ApiException.network] - If network error occurs
  Future<void> createDocument(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.doc(path).set(data);
    } on FirebaseException catch (e) {
      _handleFirestoreException(e);
    } catch (e) {
      throw ApiException.unknown(
        'Unexpected error creating document',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Read a single document
  /// 
  /// Retrieves a document from the specified path.
  /// Returns DocumentSnapshot which contains document data and metadata.
  /// 
  /// Parameters:
  /// - [path] - Document path (e.g., 'users/user-123')
  /// 
  /// Returns:
  /// - [DocumentSnapshot] - Snapshot of the document
  Future<DocumentSnapshot> readDocument(String path) async {
    try {
      return await _firestore.doc(path).get();
    } on FirebaseException catch (e) {
      _handleFirestoreException(e);
      rethrow;
    } catch (e) {
      throw ApiException.unknown(
        'Unexpected error reading document',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Read multiple documents from a collection
  /// 
  /// Retrieves documents from a collection with optional query filtering.
  /// Returns list of DocumentSnapshots.
  /// 
  /// Parameters:
  /// - [path] - Collection path (e.g., 'tasks')
  /// - [queryBuilder] - Optional function to add filters/ordering
  /// 
  /// Returns:
  /// - [List<DocumentSnapshot>] - List of document snapshots
  /// 
  /// Throws:
  /// - [ApiException.firestore] - If operation fails
  /// - [ApiException.network] - If network error occurs
  Future<List<DocumentSnapshot>> readCollection(
    String path, {
    Query<Map<String, dynamic>> Function(CollectionReference)?
        queryBuilder,
  }) async {
    try {
      final collection = _firestore.collection(path);
      final query =
          queryBuilder != null ? queryBuilder(collection) : collection;
      final snapshot = await query.get();
      return snapshot.docs;
    } on FirebaseException catch (e) {
      _handleFirestoreException(e);
      rethrow;
    } catch (e) {
      throw ApiException.unknown(
        'Unexpected error reading collection',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Update an existing document
  /// 
  /// Updates specific fields in a document without overwriting entire document.
  /// Only fields in the data map are updated; other fields remain unchanged.
  /// 
  /// Parameters:
  /// - [path] - Document path (e.g., 'users/user-123')
  /// - [data] - Fields to update (partial document)
  /// 
  /// Returns:
  /// - [Future<void>] completes when document is updated
  /// 
  /// Throws:
  /// - [ApiException.firestore] - If operation fails
  /// - [ApiException.network] - If network error occurs
  Future<void> updateDocument(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.doc(path).update(data);
    } on FirebaseException catch (e) {
      _handleFirestoreException(e);
    } catch (e) {
      throw ApiException.unknown(
        'Unexpected error updating document',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Delete a document
  /// 
  /// Permanently deletes a document from Firestore.
  /// 
  /// Parameters:
  /// - [path] - Document path (e.g., 'users/user-123')
  /// 
  /// Returns:
  /// - [Future<void>] completes when document is deleted
  /// 
  /// Throws:
  /// - [ApiException.firestore] - If operation fails
  /// - [ApiException.network] - If network error occurs
  Future<void> deleteDocument(String path) async {
    try {
      await _firestore.doc(path).delete();
    } on FirebaseException catch (e) {
      _handleFirestoreException(e);
    } catch (e) {
      throw ApiException.unknown(
        'Unexpected error deleting document',
        originalException: e is Exception ? e : null,
      );
    }
  }

  /// Listen to real-time changes of a single document
  /// 
  /// Returns a stream that emits DocumentSnapshot whenever document changes.
  /// Stream never closes unless there's an error.
  /// 
  /// Parameters:
  /// - [path] - Document path (e.g., 'users/user-123')
  /// 
  /// Returns:
  /// - [Stream<DocumentSnapshot>] - Emits document snapshot on changes
  /// 
  /// Throws:
  /// - [ApiException.firestore] - On permission denied or other errors
  /// - [ApiException.network] - On network errors
  Stream<DocumentSnapshot> listenToDocument(String path) {
    return _firestore.doc(path).snapshots().handleError((error) {
      if (error is FirebaseException) {
        _handleFirestoreException(error);
      }
      throw error;
    });
  }

  /// Listen to real-time changes of a collection
  /// 
  /// Returns a stream that emits list of DocumentSnapshots whenever collection changes.
  /// Supports filtering and ordering via queryBuilder.
  /// 
  /// Parameters:
  /// - [path] - Collection path (e.g., 'tasks')
  /// - [queryBuilder] - Optional function to add filters/ordering
  /// 
  /// Returns:
  /// - [Stream<List<DocumentSnapshot>>] - Emits list of snapshots on changes
  /// 
  /// Throws:
  /// - [ApiException.firestore] - On permission denied or other errors
  /// - [ApiException.network] - On network errors
  Stream<List<DocumentSnapshot>> listenToCollection(
    String path, {
    Query<Map<String, dynamic>> Function(CollectionReference)?
        queryBuilder,
  }) {
    final collection = _firestore.collection(path);
    final query = queryBuilder != null ? queryBuilder(collection) : collection;
    return query.snapshots().map((snapshot) => snapshot.docs).handleError(
      (error) {
        if (error is FirebaseException) {
          _handleFirestoreException(error);
        }
        throw error;
      },
    );
  }

  /// Handle Firestore exceptions and convert to ApiException
  /// 
  /// Maps Firestore error codes to appropriate ApiException types.
  /// 
  /// Throws:
  /// - [ApiException.firestore] - For Firestore-specific errors
  /// - [ApiException.auth] - For authentication errors
  /// - [ApiException.network] - For network errors
  void _handleFirestoreException(FirebaseException e) {
    String message = 'Database operation failed';

    switch (e.code) {
      case 'permission-denied':
        throw ApiException.firestore(
          'Access denied. You do not have permission to perform this action.',
          code: e.code,
          originalException: e,
        );
      case 'not-found':
        throw ApiException.firestore(
          'Document not found',
          code: e.code,
          originalException: e,
        );
      case 'already-exists':
        throw ApiException.firestore(
          'Document already exists',
          code: e.code,
          originalException: e,
        );
      case 'invalid-argument':
        throw ApiException.firestore(
          'Invalid operation or data format',
          code: e.code,
          originalException: e,
        );
      case 'failed-precondition':
        throw ApiException.firestore(
          'Operation precondition failed',
          code: e.code,
          originalException: e,
        );
      case 'out-of-range':
        throw ApiException.firestore(
          'Value out of range',
          code: e.code,
          originalException: e,
        );
      case 'unauthenticated':
        throw ApiException.auth(
          'Authentication required',
          code: e.code,
          originalException: e,
        );
      case 'deadline-exceeded':
        throw ApiException.network(
          'Request timeout. Please try again.',
          code: e.code,
          originalException: e,
        );
      case 'unavailable':
        throw ApiException.network(
          'Service temporarily unavailable. Please try again.',
          code: e.code,
          originalException: e,
        );
      case 'internal':
        throw ApiException.firestore(
          'Internal server error',
          code: e.code,
          originalException: e,
        );
      case 'resource-exhausted':
        throw ApiException.firestore(
          'Database quota exceeded. Please try again later.',
          code: e.code,
          originalException: e,
        );
      default:
        throw ApiException.firestore(
          message,
          code: e.code,
          originalException: e,
        );
    }
  }
}