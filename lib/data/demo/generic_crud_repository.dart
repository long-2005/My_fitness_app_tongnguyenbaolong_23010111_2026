abstract class CrudEntity {
  const CrudEntity({required this.id});

  final String id;
}

class GenericCrudRepository<T extends CrudEntity> {
  final Map<String, T> _items = {};

  List<T> readAll() => _items.values.toList(growable: false);

  T? readById(String id) => _items[id];

  void create(T item) {
    if (_items.containsKey(item.id)) {
      throw StateError('ID ${item.id} already exists');
    }
    _items[item.id] = item;
  }

  void update(T item) {
    if (!_items.containsKey(item.id)) {
      throw StateError('ID ${item.id} does not exist'); 
    }
    _items[item.id] = item;
  }

  T? delete(String id) => _items.remove(id);
}
