import 'dart:collection';

/// A generic, bounded Least-Recently-Used (LRU) Cache.
/// Ensures memory usage remains strictly bounded during PDF page rendering.
class LruCache<K, V> {
  final int capacity;
  final LinkedHashMap<K, V> _map = LinkedHashMap<K, V>();

  LruCache({this.capacity = 20}) {
    assert(capacity > 0, 'Capacity must be greater than zero');
  }

  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool get isNotEmpty => _map.isNotEmpty;

  /// Retrieves an item from the cache and marks it as most recently used.
  V? get(K key) {
    if (!_map.containsKey(key)) return null;
    final value = _map.remove(key) as V;
    _map[key] = value;
    return value;
  }

  /// Inserts or updates an item in the cache. Evicts the oldest item if capacity is reached.
  void put(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key);
    } else if (_map.length >= capacity) {
      final oldestKey = _map.keys.first;
      _map.remove(oldestKey);
    }
    _map[key] = value;
  }

  /// Checks if a key exists in cache without updating its access order.
  bool containsKey(K key) => _map.containsKey(key);

  /// Removes a specific key from cache.
  V? remove(K key) => _map.remove(key);

  /// Clears all entries from the cache.
  void clear() => _map.clear();
}
