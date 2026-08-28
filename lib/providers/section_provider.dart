import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/section_model.dart';
import '../repositories/section_repository.dart';

/// The section repository. Overridden in tests with a
/// [StaticSectionRepository] so the UI can be exercised without Firebase.
final sectionRepositoryProvider = Provider<SectionRepository>(
  (ref) => FirebaseSectionRepository(),
);

/// Live catalog sections, straight from the admin console.
///
/// Every screen that shows category chips watches this one provider, so a
/// section added, renamed, reordered or hidden in the console updates the
/// whole app at once — and the sections can never disagree between the home
/// screen and the categories screen the way three hardcoded lists did.
final sectionsProvider = StreamProvider<List<StoreSection>>(
  (ref) => ref.watch(sectionRepositoryProvider).watchSections(),
);
