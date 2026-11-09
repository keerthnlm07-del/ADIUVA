import 'package:flutter_test/flutter_test.dart';
import 'package:adiuva/features/cognitive_assistance/presentation/provider/todo_provider.dart';
import 'package:adiuva/core/services/local_storage_service.dart';

class MockLocalStorageService extends LocalStorageService {
  final Map<String, String> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<bool> saveString(String key, String value) async {
    _data[key] = value;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cognitive Task Voice Matching Test Suite', () {
    late TodoProvider todoProvider;

    setUp(() async {
      todoProvider = TodoProvider(storageService: MockLocalStorageService());
      await todoProvider.loadTasks();
    });

    test('Add task via title', () async {
      final task = await todoProvider.addTask('Drink a glass of water');
      expect(task.title, equals('Drink a glass of water'));
      expect(task.isCompleted, isFalse);
      expect(todoProvider.tasks.any((t) => t.title == 'Drink a glass of water'), isTrue);
    });

    test('Complete task with exact title', () async {
      await todoProvider.addTask('Drink a glass of water');
      final completed = await todoProvider.completeTaskByTitle('drink a glass of water');
      expect(completed, isNotNull);
      expect(completed!.isCompleted, isTrue);
    });

    test('Complete task with partial keyword "water task"', () async {
      await todoProvider.addTask('Drink a glass of water');
      final completed = await todoProvider.completeTaskByTitle('water task');
      expect(completed, isNotNull);
      expect(completed!.title, equals('Drink a glass of water'));
      expect(completed.isCompleted, isTrue);
    });

    test('Delete task with title match', () async {
      await todoProvider.addTask('Drink a glass of water');
      final deleted = await todoProvider.deleteTaskByTitle('drink a glass of water');
      expect(deleted, isNotNull);
      expect(todoProvider.tasks.any((t) => t.id == deleted!.id), isFalse);
    });

    test('Complete non existent task returns null', () async {
      final completed = await todoProvider.completeTaskByTitle('non existent random task');
      expect(completed, isNull);
    });
  });
}
