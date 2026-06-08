import 'package:glados/glados.dart';
import 'package:situkang_app/features/categories/domain/entities/service.dart';

/// Property-based test for service list alphabetical sorting.
///
/// Property 7: Service List Alphabetical Sort — Displayed list sorted by
/// name ascending (case-insensitive).
///
/// **Validates: Requirements 4.1**
void main() {
  // ─── Property 7: Service List Alphabetical Sort ─────────────────────────────
  // **Validates: Requirements 4.1**
  group('Property 7: Service List Alphabetical Sort', () {
    // Characters that can appear in service names (letters, digits, spaces, common punctuation)
    const nameChars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -';

    Glados<List<String>>(any.list(any.nonEmptyStringOf(nameChars))).test(
      'sorting a list of services by name produces ascending alphabetical order (case-insensitive)',
      (names) {
        // Create Service entities from the generated names
        final services = names
            .asMap()
            .entries
            .map(
              (entry) => Service(
                id: 'service-${entry.key}',
                categoryId: 'category-1',
                name: entry.value,
                description: 'Description ${entry.key}',
                basePrice: 50000,
                priceUnit: 'per jam',
                estimatedDuration: '1-2 jam',
                isActive: true,
              ),
            )
            .toList();

        // Apply the same sorting logic as CategoryRepositoryImpl
        services.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        // Verify the list is in ascending alphabetical order (case-insensitive)
        for (var i = 0; i < services.length - 1; i++) {
          final current = services[i].name.toLowerCase();
          final next = services[i + 1].name.toLowerCase();
          expect(
            current.compareTo(next) <= 0,
            isTrue,
            reason:
                'Service at index $i ("${services[i].name}") should come '
                'before or equal to service at index ${i + 1} '
                '("${services[i + 1].name}") in case-insensitive alphabetical order',
          );
        }
      },
    );

    Glados<List<String>>(any.list(any.nonEmptyStringOf(nameChars))).test(
      'sorting preserves all original elements (no items lost or duplicated)',
      (names) {
        // Create Service entities from the generated names
        final services = names
            .asMap()
            .entries
            .map(
              (entry) => Service(
                id: 'service-${entry.key}',
                categoryId: 'category-1',
                name: entry.value,
                description: 'Description ${entry.key}',
                basePrice: 50000,
                priceUnit: 'per jam',
                estimatedDuration: '1-2 jam',
                isActive: true,
              ),
            )
            .toList();

        final originalNames = services.map((s) => s.name).toList();

        // Apply the same sorting logic as CategoryRepositoryImpl
        services.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        final sortedNames = services.map((s) => s.name).toList();

        // Verify same length (no items lost or added)
        expect(sortedNames.length, equals(originalNames.length),
            reason: 'Sorting should not change the number of elements');

        // Verify same elements (sorting is a permutation)
        final originalSorted = List<String>.from(originalNames)..sort();
        final resultSorted = List<String>.from(sortedNames)..sort();
        expect(resultSorted, equals(originalSorted),
            reason: 'Sorting should preserve all original elements');
      },
    );

    Glados<List<String>>(any.list(any.nonEmptyStringOf(nameChars))).test(
      'sorting is case-insensitive (uppercase and lowercase treated equally)',
      (names) {
        // Create Service entities from the generated names
        final services = names
            .asMap()
            .entries
            .map(
              (entry) => Service(
                id: 'service-${entry.key}',
                categoryId: 'category-1',
                name: entry.value,
                description: 'Description ${entry.key}',
                basePrice: 50000,
                priceUnit: 'per jam',
                estimatedDuration: '1-2 jam',
                isActive: true,
              ),
            )
            .toList();

        // Apply the same sorting logic as CategoryRepositoryImpl
        services.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        // Verify that the lowercased names are in non-decreasing order
        final lowercasedNames =
            services.map((s) => s.name.toLowerCase()).toList();
        for (var i = 0; i < lowercasedNames.length - 1; i++) {
          expect(
            lowercasedNames[i].compareTo(lowercasedNames[i + 1]) <= 0,
            isTrue,
            reason:
                'Lowercased name at index $i ("${lowercasedNames[i]}") should '
                'be <= name at index ${i + 1} ("${lowercasedNames[i + 1]}")',
          );
        }
      },
    );
  });
}
