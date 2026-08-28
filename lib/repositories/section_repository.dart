import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/section_model.dart';

/// Reads the catalog sections the admin console maintains.
abstract class SectionRepository {
  /// Sections to show shoppers, in the order the console arranged them.
  ///
  /// A stream rather than a fetch, so a section added or reordered in the
  /// console appears in an open app without a restart.
  Stream<List<StoreSection>> watchSections();
}

class FirebaseSectionRepository implements SectionRepository {
  final FirebaseFirestore _firestore;

  FirebaseSectionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<StoreSection>> watchSections() {
    return _firestore.collection('sections').snapshots().map((snapshot) {
      final sections = snapshot.docs
          .map((doc) => StoreSection.fromMap(doc.id, doc.data()))
          .where((section) => section.active && section.name.isNotEmpty)
          .toList();

      // Sorted here rather than with `orderBy` so that hiding a section never
      // needs a composite index, and so a document missing `sortOrder` still
      // lands somewhere sensible instead of being dropped by the query.
      sections.sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
      });
      return sections;
    });
  }
}

/// Fixed sections for tests and for previewing the UI without Firebase.
class StaticSectionRepository implements SectionRepository {
  const StaticSectionRepository(this.sections);

  final List<StoreSection> sections;

  @override
  Stream<List<StoreSection>> watchSections() => Stream.value(sections);
}
