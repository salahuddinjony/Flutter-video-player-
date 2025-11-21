import 'dart:convert';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/instruction_model.dart';

class FirebaseService {
  FirebaseFirestore? _firestore;
  StreamSubscription<DocumentSnapshot>? _subscription;
  Function(InstructionsResponse)? onInstructionsUpdate;
  bool _isListening = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  
  /// Get Firestore instance, initializing it if needed
  FirebaseFirestore? get firestore => _firestore;

  /// Start listening to Firestore document for real-time updates
  /// 
  /// [collectionPath] - The collection path (e.g., 'instractions')
  /// [documentId] - The document ID to listen to. If null, listens to the first document in the collection
  void startListening({
    String collectionPath = 'instractions', // Note: Firebase collection is 'instractions' (typo in Firebase)
    String? documentId,
  }) {
    if (_isListening) {
      debugPrint('Firebase listener already active');
      return;
    }

    try {
      // Check if we've exceeded max retries
      if (_retryCount >= _maxRetries) {
        debugPrint('Firebase initialization failed after $_maxRetries attempts. App will work in offline mode.');
        return;
      }

      // Ensure Firebase is initialized before accessing Firestore
      if (_firestore == null) {
        try {
          // Check if Firebase is initialized
          final app = Firebase.app();
          _firestore = FirebaseFirestore.instanceFor(app: app);
          _retryCount = 0; // Reset retry count on success
          debugPrint('Firebase Firestore initialized successfully');
        } catch (e) {
          _retryCount++;
          debugPrint('Firebase not initialized yet (attempt $_retryCount/$_maxRetries): $e');
          
          if (_retryCount < _maxRetries) {
            debugPrint('Will retry Firebase connection in 3 seconds...');
            // Try again after a delay
            Future.delayed(const Duration(seconds: 3), () {
              startListening(collectionPath: collectionPath, documentId: documentId);
            });
          } else {
            debugPrint('Firebase initialization failed. App will work in offline mode with local instructions.');
          }
          return;
        }
      }
      
      if (_firestore == null) {
        debugPrint('Firestore instance is null');
        return;
      }
      
      CollectionReference collection = _firestore!.collection(collectionPath);
      
      if (documentId != null) {
        // Listen to a specific document
        debugPrint('Setting up listener for document: $documentId in collection: $collectionPath');
        
        // First, list all documents in the collection to help debug
        collection.get().then((querySnapshot) {
          debugPrint('Total documents in collection "$collectionPath": ${querySnapshot.docs.length}');
          if (querySnapshot.docs.isNotEmpty) {
            debugPrint('Available document IDs:');
            for (var doc in querySnapshot.docs) {
              debugPrint('  - ${doc.id} ${doc.id == documentId ? "(MATCHING)" : ""}');
            }
          } else {
            debugPrint('Collection "$collectionPath" is empty');
          }
          
          // Now try to fetch the specific document
          return collection.doc(documentId).get();
        }).then((docSnapshot) {
          debugPrint('Document fetch result - ID: ${docSnapshot.id}, Exists: ${docSnapshot.exists}');
          if (docSnapshot.exists) {
            debugPrint('✓ Document exists and is accessible. Setting up real-time listener...');
            // Process initial document
            _handleDocumentChange(docSnapshot);
          } else {
            debugPrint('✗ Document $documentId does not exist in collection $collectionPath');
            debugPrint('Please verify:');
            debugPrint('  1. The document ID is correct');
            debugPrint('  2. The collection name is correct');
            debugPrint('  3. The document is in the default database (not a named database)');
            debugPrint('The listener is still active and will receive updates if the document is created.');
          }
        }).catchError((error) {
          debugPrint('Error accessing document: $error');
          debugPrint('This might be due to Firestore security rules. Please check your Firestore rules.');
        });
        
        // Set up real-time listener
        _subscription = collection.doc(documentId).snapshots().listen(
          _handleDocumentChange,
          onError: (error) {
            debugPrint('Firebase listener error: $error');
            debugPrint('This might be due to Firestore security rules. Please check your Firestore rules allow read access.');
            _isListening = false;
          },
        );
      } else {
        // Listen to the first document in the collection
        // Get the first document ID and then listen to it
        collection.limit(1).get().then((querySnapshot) {
          if (querySnapshot.docs.isNotEmpty) {
            final docId = querySnapshot.docs.first.id;
            debugPrint('Listening to document: $docId in collection: $collectionPath');
            _subscription = collection.doc(docId).snapshots().listen(
              _handleDocumentChange,
              onError: (error) {
                debugPrint('Firebase listener error: $error');
                _isListening = false;
              },
            );
            _isListening = true;
          } else {
            debugPrint('No documents found in collection: $collectionPath');
          }
        }).catchError((error) {
          debugPrint('Error getting document ID: $error');
        });
        return;
      }

      _isListening = true;
      debugPrint('Firebase listener started for collection: $collectionPath, document: $documentId');
    } catch (e) {
      debugPrint('Error starting Firebase listener: $e');
      _isListening = false;
    }
  }

  /// Handle document changes from Firestore
  void _handleDocumentChange(DocumentSnapshot snapshot) {
    debugPrint('Firestore snapshot event received. Document exists: ${snapshot.exists}, Document ID: ${snapshot.id}');
    
    if (!snapshot.exists) {
      debugPrint('Document does not exist. This might be the initial snapshot. Listener will receive updates when document is available.');
      return;
    }

    try {
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) {
        debugPrint('Document data is null');
        return;
      }

      // Check if document has a 'data' field with JSON string
      if (data.containsKey('data')) {
        final dataField = data['data'];
        
        String jsonString;
        if (dataField is String) {
          // 'data' field is already a JSON string
          jsonString = dataField;
        } else if (dataField is Map) {
          // 'data' field is a Map, convert to JSON string
          jsonString = jsonEncode(dataField);
        } else {
          debugPrint('Invalid data field type: ${dataField.runtimeType}');
          return;
        }

        // Parse the JSON string
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        
        // Convert to InstructionsResponse
        final instructions = InstructionsResponse.fromJson(jsonData);
        
        // Notify listener
        onInstructionsUpdate?.call(instructions);
        debugPrint('Instructions updated from Firebase');
      } else {
        // If there's no 'data' field, try to use the document data directly
        try {
          final instructions = InstructionsResponse.fromJson(data);
          onInstructionsUpdate?.call(instructions);
          debugPrint('Instructions updated from Firebase (using document data directly)');
        } catch (e) {
          debugPrint('Error parsing document as instructions: $e');
        }
      }
    } catch (e) {
      debugPrint('Error handling document change: $e');
    }
  }

  /// Stop listening to Firestore updates
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    debugPrint('Firebase listener stopped');
  }

  /// Check if currently listening
  bool get isListening => _isListening;
}

