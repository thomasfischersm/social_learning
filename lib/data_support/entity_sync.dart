import 'package:cloud_firestore/cloud_firestore.dart';

abstract class EntitySync<T> {
  final String collectionName;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final Transaction transaction;
  final bool enableDebug = true;

  int sortOrderCounter = 0;
  Map<String, T> rawIdToDbEntity = {};
  Set<String> syncedRawIds = {};
  bool hasLoadedFromDb = false;

  EntitySync(this.collectionName, this.transaction);

  Future<void> loadFromDb();

  T loadFromJson(Map<String, dynamic> jsonEntity, String fullParentId);

  bool compareEntity(T dbType, T jsonType, int newSortOrder);

  DocumentReference<Map<String, dynamic>> createNewRef() {
    return db.collection('_collectionName').doc();
  }

  DocumentReference<Map<String, dynamic>> createRef(String rawId) {
    return db.collection(collectionName).doc(rawId);
  }

  String createNewEntity(T jsonType, String fullParentId, int newSortOrder);

  void updateEntity(T dbType, T jsonType, String fullParentId, int sortOrder);

  void deleteEntity(String rawId) {
    var docRef = db.collection(collectionName).doc(rawId);
    transaction.delete(docRef);
  }

  Future<void> handleChildren(Map<String, dynamic> currentJson, T? dbType,
      String? newRawId, bool isLastInvocation);

  Future<void> sync(
      List<dynamic> jsonList, String fullParentId, bool deleteLeftOver) async {
    // Get and parse the data.
    if (!hasLoadedFromDb) {
      hasLoadedFromDb = true;
      await loadFromDb();
      print('after await loadFromDb();');

      if (enableDebug) {
        print(
            'Loaded ${rawIdToDbEntity.length} from the $collectionName collection.');
      }
    }

    for (int i = 0; i < jsonList.length; i++) {
      Map<String, dynamic> jsonEntity = jsonList[i];
      T jsonType = loadFromJson(jsonEntity, fullParentId);
      T? dbType = rawIdToDbEntity[jsonEntity['id']];
      String? newRawId;

      if (dbType == null) {
        newRawId = createNewEntity(jsonType, fullParentId, sortOrderCounter);

        if (enableDebug) {
          print('Created $collectionName ${jsonEntity['title']}. $newRawId');
        }
      } else if (!compareEntity(dbType, jsonType, sortOrderCounter)) {
        updateEntity(dbType, jsonType, fullParentId, sortOrderCounter);

        if (enableDebug) {
          print('Updated $collectionName ${jsonEntity['title']}.');
        }
      }

      // Always increment the sortOrder counter!
      sortOrderCounter++;
      if (dbType != null) {
        syncedRawIds.add(jsonEntity['id']);
      } else {
        syncedRawIds.add(newRawId!);
      }

      await handleChildren(jsonEntity, dbType, newRawId,
          deleteLeftOver && (i == jsonList.length - 1));
    }

    if (deleteLeftOver) {
      print('Deleting leftover $collectionName.');
      print('raw DB ids: ${rawIdToDbEntity.keys.toList()
        ..sort((a, b) => a.compareTo(b))
        ..join(', ')}');
      print('raw synced ids: ${syncedRawIds.toList()
        ..sort((a, b) => a.compareTo(b))
        ..join(', ')}');

      var obsoleteIds = rawIdToDbEntity.keys
          .where((element) => !syncedRawIds.contains(element));
      for (String obsoleteId in obsoleteIds) {
        deleteEntity(obsoleteId);

        if (enableDebug) {
          print('Deleted $obsoleteId from the $collectionName collection.');
        }
      }
    }
  }
}
