import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/skill_rubric.dart';


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
        final dims = (doc.data()['dimensions'] as List<dynamic>? ?? [])
            .map((e) => SkillDimension.fromMap(e as Map<String, dynamic>))
            .toList();
        dims.add(newDimension);
        await doc.reference.update({
          'dimensions': dims.map((e) => e.toMap()).toList(),
          'modifiedAt': FieldValue.serverTimestamp(),
        });
        final updated = await doc.reference.get();
        return SkillRubric.fromSnapshot(updated);
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
      final degrees = List<SkillDegree>.from(dimension.degrees);
      final newDegree = SkillDegree(
        id: _firestore.collection(_collectionPath).doc().id,
        degree: degrees.length + 1,
        name: name,
        description: description,
        lessonRefs: [],
      );
      degrees.add(newDegree);
      dims[index] = SkillDimension(
        id: dimension.id,
        name: dimension.name,
        description: dimension.description,
        degrees: degrees,
      );

      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final updated = await docRef.get();
      return SkillRubric.fromSnapshot(updated);
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
      final degrees = List<SkillDegree>.from(dims[dimIndex].degrees);
      degrees.removeWhere((d) => d.id == degreeId);
      for (var i = 0; i < degrees.length; i++) {
        degrees[i] = SkillDegree(
          id: degrees[i].id,
          degree: i + 1,
          name: degrees[i].name,
          description: degrees[i].description,
          lessonRefs: degrees[i].lessonRefs,
        );
      }
      dims[dimIndex] = SkillDimension(
        id: dims[dimIndex].id,
        name: dims[dimIndex].name,
        description: dims[dimIndex].description,
        degrees: degrees,
      );
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final updated = await docRef.get();
      return SkillRubric.fromSnapshot(updated);
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
      final dims = List<SkillDimension>.from(rubric.dimensions);
      dims.removeWhere((d) => d.id == dimensionId);
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final updated = await docRef.get();
      return SkillRubric.fromSnapshot(updated);
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
      final dims = List<SkillDimension>.from(rubric.dimensions);
      final index = dims.indexWhere((d) => d.id == dimensionId);
      if (index < 0) return rubric;
      final updatedDim = SkillDimension(
        id: dims[index].id,
        name: name,
        description: description,
        degrees: dims[index].degrees,
      );
      dims[index] = updatedDim;
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final updated = await docRef.get();
      return SkillRubric.fromSnapshot(updated);
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
      final dims = List<SkillDimension>.from(rubric.dimensions);
      final dimIndex = dims.indexWhere((d) => d.id == dimensionId);
      if (dimIndex < 0) return rubric;
      final degrees = List<SkillDegree>.from(dims[dimIndex].degrees);
      final degIndex = degrees.indexWhere((d) => d.id == degreeId);
      if (degIndex < 0) return rubric;
      degrees[degIndex] = SkillDegree(
        id: degrees[degIndex].id,
        degree: degrees[degIndex].degree,
        name: name,
        description: description,
        lessonRefs: degrees[degIndex].lessonRefs,
      );
      dims[dimIndex] = SkillDimension(
        id: dims[dimIndex].id,
        name: dims[dimIndex].name,
        description: dims[dimIndex].description,
        degrees: degrees,
      );
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final updated = await docRef.get();
      return SkillRubric.fromSnapshot(updated);
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
      final dims = List<SkillDimension>.from(rubric.dimensions);
      final currentIndex = dims.indexWhere((d) => d.id == dimensionId);
      if (currentIndex < 0) return rubric;
      if (newIndex < 0 || newIndex >= dims.length) return rubric;
      final dim = dims.removeAt(currentIndex);
      dims.insert(newIndex, dim);
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final updated = await docRef.get();
      return SkillRubric.fromSnapshot(updated);
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
      final dims = List<SkillDimension>.from(rubric.dimensions);
      final dimIndex = dims.indexWhere((d) => d.id == dimensionId);
      if (dimIndex < 0) return rubric;
      final degrees = List<SkillDegree>.from(dims[dimIndex].degrees);
      final index = degrees.indexWhere((d) => d.id == degreeId);
      if (index < 0) return rubric;
      if (newIndex < 0 || newIndex >= degrees.length) return rubric;
      final degree = degrees.removeAt(index);
      degrees.insert(newIndex, degree);
      for (var i = 0; i < degrees.length; i++) {
        degrees[i] = SkillDegree(
          id: degrees[i].id,
          degree: i + 1,
          name: degrees[i].name,
          description: degrees[i].description,
          lessonRefs: degrees[i].lessonRefs,
        );
      }
      dims[dimIndex] = SkillDimension(
        id: dims[dimIndex].id,
        name: dims[dimIndex].name,
        description: dims[dimIndex].description,
        degrees: degrees,
      );
      await docRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final updated = await docRef.get();
      return SkillRubric.fromSnapshot(updated);
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
      final degrees = List<SkillDegree>.from(dims[dimIndex].degrees);
      final degIndex = degrees.indexWhere((d) => d.id == degreeId);
      if (degIndex < 0) return rubric;
      final lessonRef = docRef('lessons', lessonId);
      final lessons = List<DocumentReference>.from(degrees[degIndex].lessonRefs);
      lessons.add(lessonRef);
      degrees[degIndex] = SkillDegree(
        id: degrees[degIndex].id,
        degree: degrees[degIndex].degree,
        name: degrees[degIndex].name,
        description: degrees[degIndex].description,
        lessonRefs: lessons,
      );
      dims[dimIndex] = SkillDimension(
        id: dims[dimIndex].id,
        name: dims[dimIndex].name,
        description: dims[dimIndex].description,
        degrees: degrees,
      );
      await rubricRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final updated = await rubricRef.get();
      return SkillRubric.fromSnapshot(updated);
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
      final degrees = List<SkillDegree>.from(dims[dimIndex].degrees);
      final lessons = List<DocumentReference>.from(degrees[degIndex].lessonRefs);
      lessons.add(lessonRef);
      degrees[degIndex] = SkillDegree(
        id: degrees[degIndex].id,
        degree: degrees[degIndex].degree,
        name: degrees[degIndex].name,
        description: degrees[degIndex].description,
        lessonRefs: lessons,
      );
      dims[dimIndex] = SkillDimension(
        id: dims[dimIndex].id,
        name: dims[dimIndex].name,
        description: dims[dimIndex].description,
        degrees: degrees,
      );
      await rubricRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final updated = await rubricRef.get();
      return SkillRubric.fromSnapshot(updated);
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
      final degrees = List<SkillDegree>.from(dims[dimIndex].degrees);
      final degIndex = degrees.indexWhere((d) => d.id == degreeId);
      if (degIndex < 0) return rubric;
      final lessonRef = docRef('lessons', lessonId);
      final lessons = List<DocumentReference>.from(degrees[degIndex].lessonRefs);
      lessons.removeWhere((ref) => ref.path == lessonRef.path);
      degrees[degIndex] = SkillDegree(
        id: degrees[degIndex].id,
        degree: degrees[degIndex].degree,
        name: degrees[degIndex].name,
        description: degrees[degIndex].description,
        lessonRefs: lessons,
      );
      dims[dimIndex] = SkillDimension(
        id: dims[dimIndex].id,
        name: dims[dimIndex].name,
        description: dims[dimIndex].description,
        degrees: degrees,
      );
      await rubricRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final updated = await rubricRef.get();
      return SkillRubric.fromSnapshot(updated);
    } catch (e) {
      print('Error removing lesson: $e');
      return null;
    }
  }

  static Future<SkillRubric?> moveLesson({
    required String courseId,
    required String dimensionId,
    required String degreeId,
    required String lessonId,
    required bool moveUp,
  }) async {
    try {
      final rubric = await loadForCourse(courseId);
      if (rubric == null || rubric.id == null) return null;
      final rubricRef = _firestore.collection(_collectionPath).doc(rubric.id);
      final dims = rubric.dimensions;
      final dimIndex = dims.indexWhere((d) => d.id == dimensionId);
      if (dimIndex < 0) return rubric;
      final degrees = List<SkillDegree>.from(dims[dimIndex].degrees);
      final degIndex = degrees.indexWhere((d) => d.id == degreeId);
      if (degIndex < 0) return rubric;
      final lessons = List<DocumentReference>.from(degrees[degIndex].lessonRefs);
      final lessonRef = docRef('lessons', lessonId);
      final index = lessons.indexWhere((ref) => ref.path == lessonRef.path);
      if (index < 0) return rubric;
      final newIndex = moveUp ? index - 1 : index + 1;
      if (newIndex < 0 || newIndex >= lessons.length) return rubric;
      final lesson = lessons.removeAt(index);
      lessons.insert(newIndex, lesson);
      degrees[degIndex] = SkillDegree(
        id: degrees[degIndex].id,
        degree: degrees[degIndex].degree,
        name: degrees[degIndex].name,
        description: degrees[degIndex].description,
        lessonRefs: lessons,
      );
      dims[dimIndex] = SkillDimension(
        id: dims[dimIndex].id,
        name: dims[dimIndex].name,
        description: dims[dimIndex].description,
        degrees: degrees,
      );
      await rubricRef.update({
        'dimensions': dims.map((e) => e.toMap()).toList(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      final updated = await rubricRef.get();
      return SkillRubric.fromSnapshot(updated);
    } catch (e) {
      print('Error moving lesson: $e');
      return null;
    }
  }
}

