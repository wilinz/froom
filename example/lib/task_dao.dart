import 'package:example/task.dart';
import 'package:froom/froom.dart';

@dao
abstract class TaskDao {
  @Query('SELECT * FROM task WHERE id = :id')
  Future<Task?> findTaskById(int id);

  @Query('SELECT * FROM task')
  Future<List<Task>> findAllTasks();

  @Query('SELECT * FROM task')
  Stream<List<Task>> findAllTasksAsStream();

  @Query('SELECT DISTINCT COUNT(message) FROM task')
  Stream<int?> findUniqueMessagesCountAsStream();

  @Query('SELECT * FROM task WHERE status = :status')
  Stream<List<Task>> findAllTasksByStatusAsStream(TaskStatus status);

  @Query('UPDATE OR ABORT Task SET type = :type WHERE id = :id')
  Future<int?> updateTypeById(TaskType type, int id);

  @insert
  Future<void> insertTask(Task task);

  @insert
  Future<void> insertTasks(List<Task> tasks);

  @update
  Future<void> updateTask(Task task);

  @update
  Future<void> updateTasks(List<Task> task);

  @delete
  Future<void> deleteTask(Task task);

  @delete
  Future<void> deleteTasks(List<Task> tasks);
}
