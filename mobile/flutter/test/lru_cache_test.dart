import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/pdf/lru_cache.dart';

void main() {
  group('LruCache Tests', () {
    test('Stores and retrieves values', () {
      final cache = LruCache<String, int>(capacity: 3);
      cache.put('a', 1);
      cache.put('b', 2);
      cache.put('c', 3);

      expect(cache.length, 3);
      expect(cache.get('a'), 1);
      expect(cache.get('b'), 2);
      expect(cache.get('c'), 3);
      expect(cache.get('non_existent'), isNull);
    });

    test('Evicts least recently used item when capacity is reached', () {
      final cache = LruCache<String, int>(capacity: 2);
      cache.put('page_1', 100);
      cache.put('page_2', 200);

      // Access page_1 to make it most recently used
      cache.get('page_1');

      // Insert page_3 -> page_2 should be evicted (least recently used)
      cache.put('page_3', 300);

      expect(cache.containsKey('page_2'), isFalse);
      expect(cache.get('page_2'), isNull);
      expect(cache.get('page_1'), 100);
      expect(cache.get('page_3'), 300);
      expect(cache.length, 2);
    });

    test('Clear and remove operations', () {
      final cache = LruCache<String, String>(capacity: 5);
      cache.put('k1', 'v1');
      cache.put('k2', 'v2');

      expect(cache.remove('k1'), 'v1');
      expect(cache.containsKey('k1'), isFalse);
      expect(cache.length, 1);

      cache.clear();
      expect(cache.isEmpty, isTrue);
      expect(cache.length, 0);
    });
  });
}
