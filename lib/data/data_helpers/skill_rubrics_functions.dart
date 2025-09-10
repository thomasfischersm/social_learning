import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/cloud_functions/skill_rubric_generation_response.dart';

class SkillRubricsFunctions {
  static FirebaseFirestore get _firestore => FirestoreService.instance;
  static const String _collectionPath = 'skillRubrics';

  static Future<SkillRubric?> loadForCourse(String courseId) async {
    try {
      final courseRef = docRef('courses', courseId);
      final query = await _firestore
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return SkillRubric.fromSnapshot(query.docs.first);
    } catch (e) {
      print('Error loading skill dimensions: $e');
      return null;
    }
  }

  static Future<SkillRubric?> ensureRubricForCourse(String courseId) async {
    try {
      final existing = await loadForCourse(courseId);
      if (existing != null) return existing;

      final courseRef = docRef('courses', courseId);
      final docRefRubric = await _firestore.collection(_collectionPath).add({
        'courseId': courseRef,
        'dimensions': [],
        'createdAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final snapshot = await docRefRubric.get();
      return SkillRubric.fromSnapshot(snapshot);
    } catch (e) {
      print('Error ensuring skill rubric: $e');
      return null;
    }
  }

  static Future<SkillRubric?> replaceRubricForCourse({
    required String courseId,
    required List<GeneratedSkillDimension> generated,
  }) async {
    try {
      final existing = await ensureRubricForCourse(courseId);
      if (existing == null || existing.id == null) return null;

      final dims = <SkillDimension>[];
      for (final dim in generated) {
        final dimId = _firestore.collection(_collectionPath).doc().id;
        final degrees = <SkillDegree>[];
        for (int i = 0; i < dim.degrees.length; i++) {
          final deg = dim.degrees[i];
          final exerciseText = deg.lessons.map((e) => "- $e").join("\n");
          final fullDescription =
              [deg.criteria, exerciseText].where((s) => s.trim().isNotEmpty).join("\n\n");
          degrees.add(SkillDegree(
            id: _firestore.collection(_collectionPath).doc().id,
            degree: i + 1,
            name: deg.name,
            description: fullDescription,
            lessonRefs: [],
          ));
        }
        dims.add(SkillDimension(
          id: dimId,
          name: dim.name,
          description: dim.description.isEmpty ? null : dim.description,
          degrees: degrees,
        ));
      }

      existing.dimensions
        ..clear()
        ..addAll(dims);
      existing.modifiedAt = Timestamp.now();

      final docRef = _firestore.collection(_collectionPath).doc(existing.id);
      await docRef.update({
        'dimensions': existing.dimensions.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      return existing;
    } catch (e) {
      print('Error replacing skill rubric: $e');
      return null;
    }
  }

  static Future<SkillRubric?> createDimension({
    required String courseId,
    required String name,
    String? description,
  }) async {
    try {
      final courseRef = docRef('courses', courseId);
      final query = await _firestore
          .collection(_collectionPath)
          .where('courseId', isEqualTo: courseRef)
          .limit(1)
          .get();

      final newDimension = SkillDimension(
        id: _firestore.collection(_collectionPath).doc().id,
        name: name,
        description: description,
        degrees: [],
      );

      if (query.docs.isEmpty) {
        final docRefRubric = await _firestore.collection(_collectionPath).add({
          'courseId': courseRef,
          'dimensions': [newDimension.toMap()],
          'createdAt': FieldValue.serverTimestamp(),
          'modifiedAt': FieldValue.serverTimestamp(),
        });
        final snapshot = await docRefRubric.get();
        return SkillRubric.fromSnapshot(snapshot);
      } else {
        final doc = query.docs.first;
        final rubric = SkillRubric.fromSnapshot(doc);
        rubric.dimensions.add(newDimension);
        await doc.reference.update({
          'dimensions': rubric.dimensions.map((e) => e.toMap()).toList(),
          'modifiedAt': FieldValue.serverTimestamp(),
        });
        rubric.modifiedAt = Timestamp.now();
        return rubric;
      }
    } catch (e) {
      print('Error creating skill dimension: $e');
      return null;
    }
  }

  static Future<SkillRubric?> addDegree({
    required String courseId,
    required String dimensionId,
    required String name,
    String? description,
  }) async {
    try {
      final rubric = await loadForCourse(courseId);
      if (rubric == null || rubric.id == null) return null;
      final docRef = _firestore.collection(_collectionPath).doc(rubric.id);
      final dims = rubric.dimensions;
      final index = dims.indexWhere((d) => d.id == dimensionId);
      if (index < 0) return rubric;

      final dimension = dims[index];
      final newDegree = SkillDegree(
        id: _firestore.collection(_collectionPath).doc().id,
        degree: dimension.degrees.length + 1,
        name: name,
        description: description,
        lessonRefs: [],
      );
      dimension.degrees.add(newDegree);

      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      rubric.modifiedAt = Timestamp.now();
      return rubric;
    } catch (e) {
      print('Error adding degree: $e');
      return null;
    }
  }

  static Future<SkillRubric?> removeDegree({
    required String courseId,
    required String dimensionId,
    required String degreeId,
  }) async {
    try {
      final rubric = await loadForCourse(courseId);
      if (rubric == null || rubric.id == null) return null;
      final docRef = _firestore.collection(_collectionPath).doc(rubric.id);
      final dims = rubric.dimensions;
      final dimIndex = dims.indexWhere((d) => d.id == dimensionId);
      if (dimIndex < 0) return rubric;
      final dimension = dims[dimIndex];
      dimension.degrees.removeWhere((d) => d.id == degreeId);
      for (var i = 0; i < dimension.degrees.length; i++) {
        dimension.degrees[i].degree = i + 1;
      }
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      rubric.modifiedAt = Timestamp.now();
      return rubric;
    } catch (e) {
      print('Error removing degree: $e');
      return null;
    }
  }

  static Future<SkillRubric?> removeDimension({
    required String courseId,
    required String dimensionId,
  }) async {
    try {
      final rubric = await loadForCourse(courseId);
      if (rubric == null || rubric.id == null) return null;
      final docRef = _firestore.collection(_collectionPath).doc(rubric.id);
      final dims = rubric.dimensions;
      dims.removeWhere((d) => d.id == dimensionId);
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      rubric.modifiedAt = Timestamp.now();
      return rubric;
    } catch (e) {
      print('Error removing dimension: $e');
      return null;
    }
  }

  static Future<SkillRubric?> updateDimension({
    required String courseId,
    required String dimensionId,
    required String name,
    String? description,
  }) async {
    try {
      final rubric = await loadForCourse(courseId);
      if (rubric == null || rubric.id == null) return null;
      final docRef = _firestore.collection(_collectionPath).doc(rubric.id);
      final dims = rubric.dimensions;
      final index = dims.indexWhere((d) => d.id == dimensionId);
      if (index < 0) return rubric;
      final updatedDim = dims[index];
      updatedDim.name = name;
      updatedDim.description = description;
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      rubric.modifiedAt = Timestamp.now();
      return rubric;
    } catch (e) {
      print('Error updating dimension: $e');
      return null;
    }
  }

  static Future<SkillRubric?> updateDegree({
    required String courseId,
    required String dimensionId,
    required String degreeId,
    required String name,
    String? description,
  }) async {
    try {
      final rubric = await loadForCourse(courseId);
      if (rubric == null || rubric.id == null) return null;
      final docRef = _firestore.collection(_collectionPath).doc(rubric.id);
      final dims = rubric.dimensions;
      final dimIndex = dims.indexWhere((d) => d.id == dimensionId);
      if (dimIndex < 0) return rubric;
      final degrees = dims[dimIndex].degrees;
      final degIndex = degrees.indexWhere((d) => d.id == degreeId);
      if (degIndex < 0) return rubric;
      final degree = degrees[degIndex];
      degree.name = name;
      degree.description = description;
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      rubric.modifiedAt = Timestamp.now();
      return rubric;
    } catch (e) {
      print('Error updating degree: $e');
      return null;
    }
  }

  static Future<SkillRubric?> moveDimension({
    required String courseId,
    required String dimensionId,
    required int newIndex,
  }) async {
    try {
      final rubric = await loadForCourse(courseId);
      if (rubric == null || rubric.id == null) return null;
      final docRef = _firestore.collection(_collectionPath).doc(rubric.id);
      final dims = rubric.dimensions;
      final currentIndex = dims.indexWhere((d) => d.id == dimensionId);
      if (currentIndex < 0) return rubric;
      if (newIndex < 0 || newIndex >= dims.length) return rubric;
      final dim = dims.removeAt(currentIndex);
      dims.insert(newIndex, dim);
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      rubric.modifiedAt = Timestamp.now();
      return rubric;
    } catch (e) {
      print('Error moving dimension: $e');
      return null;
    }
  }

  static Future<SkillRubric?> moveDegree({
    required String courseId,
    required String dimensionId,
    required String degreeId,
    required int newIndex,
  }) async {
    try {
      final rubric = await loadForCourse(courseId);
      if (rubric == null || rubric.id == null) return null;
      final docRef = _firestore.collection(_collectionPath).doc(rubric.id);
      final dims = rubric.dimensions;
      final dimIndex = dims.indexWhere((d) => d.id == dimensionId);
      if (dimIndex < 0) return rubric;
      final degrees = dims[dimIndex].degrees;
      final index = degrees.indexWhere((d) => d.id == degreeId);
      if (index < 0) return rubric;
      if (newIndex < 0 || newIndex >= degrees.length) return rubric;
      final degree = degrees.removeAt(index);
      degrees.insert(newIndex, degree);
      for (var i = 0; i < degrees.length; i++) {
        degrees[i].degree = i + 1;
      }
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      rubric.modifiedAt = Timestamp.now();
      return rubric;
    } catch (e) {
      print('Error moving degree: $e');
      return null;
    }
  }

  static Future<SkillRubric?> addLesson({
    required String courseId,
    required String dimensionId,
    required String degreeId,
    required String lessonId,
  }) async {
    try {
      final rubric = await loadForCourse(courseId);
      if (rubric == null || rubric.id == null) return null;
      final rubricRef = _firestore.collection(_collectionPath).doc(rubric.id);
      final dims = rubric.dimensions;
      final dimIndex = dims.indexWhere((d) => d.id == dimensionId);
      if (dimIndex < 0) return rubric;
      final degrees = dims[dimIndex].degrees;
      final degIndex = degrees.indexWhere((d) => d.id == degreeId);
      if (degIndex < 0) return rubric;
      final lessonRef = docRef('lessons', lessonId);
      degrees[degIndex].lessonRefs.add(lessonRef);
      await rubricRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      rubric.modifiedAt = Timestamp.now();
      return rubric;
    } catch (e) {
      print('Error adding lesson: $e');
      return null;
    }
  }

  static Future<SkillRubric?> addLessonByDegreeId({
    required String courseId,
    required String degreeId,
    required String lessonId,
  }) async {
    try {
      final rubric = await loadForCourse(courseId);
      if (rubric == null || rubric.id == null) return null;
      final rubricRef = _firestore.collection(_collectionPath).doc(rubric.id);
      final dims = rubric.dimensions;
      int dimIndex = -1;
      int degIndex = -1;
      for (var i = 0; i < dims.length; i++) {
        final d = dims[i];
        final idx = d.degrees.indexWhere((deg) => deg.id == degreeId);
        if (idx >= 0) {
          dimIndex = i;
          degIndex = idx;
          break;
        }
      }
      if (dimIndex < 0 || degIndex < 0) return rubric;
      final lessonRef = docRef('lessons', lessonId);
      dims[dimIndex].degrees[degIndex].lessonRefs.add(lessonRef);
      await rubricRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      rubric.modifiedAt = Timestamp.now();
      return rubric;
    } catch (e) {
      print('Error adding lesson: $e');
      return null;
    }
  }

  static Future<SkillRubric?> removeLesson({
    required String courseId,
    required String dimensionId,
    required String degreeId,
    required String lessonId,
  }) async {
    try {
      final rubric = await loadForCourse(courseId);
      if (rubric == null || rubric.id == null) return null;
      final rubricRef = _firestore.collection(_collectionPath).doc(rubric.id);
      final dims = rubric.dimensions;
      final dimIndex = dims.indexWhere((d) => d.id == dimensionId);
      if (dimIndex < 0) return rubric;
      final degrees = dims[dimIndex].degrees;
      final degIndex = degrees.indexWhere((d) => d.id == degreeId);
      if (degIndex < 0) return rubric;
      final lessonRef = docRef('lessons', lessonId);
      degrees[degIndex].lessonRefs
          .removeWhere((ref) => ref.path == lessonRef.path);
      await rubricRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      rubric.modifiedAt = Timestamp.now();
      return rubric;
    } catch (e) {
      print('Error removing lesson: $e');
      return null;
    }
  }

  static Future<SkillRubric?> moveLesson({
    required SkillRubric rubric,
    required String fromDimensionId,
    required String toDimensionId,
    required String fromDegreeId,
    required String toDegreeId,
    required int lessonFromIndex,
    required int lessonToIndex,
  }) async {
    try {
      if (rubric.id == null) return null;
      final dims = rubric.dimensions;
      final fromDimIndex = dims.indexWhere((d) => d.id == fromDimensionId);
      final toDimIndex = dims.indexWhere((d) => d.id == toDimensionId);
      if (fromDimIndex < 0 || toDimIndex < 0) return rubric;
      if (fromDimIndex == toDimIndex && fromDegreeId == toDegreeId) {
        _reorderWithinDegree(
          dims[fromDimIndex],
          fromDegreeId,
          lessonFromIndex,
          lessonToIndex,
        );
      } else {
        _moveAcrossDegrees(
          dims,
          fromDimIndex,
          fromDegreeId,
          lessonFromIndex,
          toDimIndex,
          toDegreeId,
          lessonToIndex,
        );
      }
      final rubricRef = _firestore.collection(_collectionPath).doc(rubric.id);
      await rubricRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      rubric.modifiedAt = Timestamp.now();
      return rubric;
    } catch (e) {
      print('Error moving lesson: $e');
      return null;
    }
  }

  static Future<SkillRubric?> moveLessonByDegree({
    required SkillRubric rubric,
    required String fromDegreeId,
    required int fromLessonIndex,
    required String toDegreeId,
    required int toLessonIndex,
  }) async {
    final fromDimensionId = _dimensionIdForDegree(rubric, fromDegreeId);
    final toDimensionId = _dimensionIdForDegree(rubric, toDegreeId);
    if (fromDimensionId == null || toDimensionId == null) return rubric;
    return moveLesson(
      rubric: rubric,
      fromDimensionId: fromDimensionId,
      toDimensionId: toDimensionId,
      fromDegreeId: fromDegreeId,
      toDegreeId: toDegreeId,
      lessonFromIndex: fromLessonIndex,
      lessonToIndex: toLessonIndex,
    );
  }

  static String? _dimensionIdForDegree(SkillRubric rubric, String degreeId) {
    for (final dim in rubric.dimensions) {
      if (dim.degrees.any((d) => d.id == degreeId)) {
        return dim.id;
      }
    }
    return null;
  }

  static void _reorderWithinDegree(
    SkillDimension dim,
    String degreeId,
    int fromIndex,
    int toIndex,
  ) {
    final degrees = dim.degrees;
    final degIndex = degrees.indexWhere((d) => d.id == degreeId);
    if (degIndex < 0) return;
    final lessons = degrees[degIndex].lessonRefs;
    if (fromIndex < 0 || fromIndex >= lessons.length) return;
    final lesson = lessons.removeAt(fromIndex);
    final insertIndex = fromIndex < toIndex ? toIndex - 1 : toIndex;
    final boundedIndex = insertIndex.clamp(0, lessons.length) as int;
    lessons.insert(boundedIndex, lesson);
  }

  static void _moveAcrossDegrees(
    List<SkillDimension> dims,
    int fromDimIndex,
    String fromDegreeId,
    int fromIndex,
    int toDimIndex,
    String toDegreeId,
    int toIndex,
  ) {
    final fromDegrees = dims[fromDimIndex].degrees;
    final fromDegIndex = fromDegrees.indexWhere((d) => d.id == fromDegreeId);
    if (fromDegIndex < 0) return;
    final fromLessons = fromDegrees[fromDegIndex].lessonRefs;
    if (fromIndex < 0 || fromIndex >= fromLessons.length) return;
    final lesson = fromLessons.removeAt(fromIndex);

    final toDegrees = dims[toDimIndex].degrees;
    final toDegIndex = toDegrees.indexWhere((d) => d.id == toDegreeId);
    if (toDegIndex < 0) return;
    final toLessons = toDegrees[toDegIndex].lessonRefs;
    final boundedIndex = toIndex.clamp(0, toLessons.length) as int;
    toLessons.insert(boundedIndex, lesson);
  }
}
