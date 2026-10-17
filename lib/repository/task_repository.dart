import 'package:connectivity_plus/connectivity_plus.dart'; // To check the internet connection
import 'package:path/path.dart'; // This package is used to write the file path as per the OS (Andiroid, iOS, web) and it is used in the line 31 to join the path of the internal storage and the name of the database file
import 'package:path_provider/path_provider.dart'; // To get the path of the internal storage in mobile and it is used in the line 30 to get the path of the internal storage
import 'package:sembast/sembast_io.dart'; // Sembast Database for mobile
import 'package:sembast_web/sembast_web.dart'; // Database for web
import 'package:flutter/foundation.dart'; // Used to check the platform (web or mobile) and it is used in the line 22 to check the platform and initialize the database accordingly
import 'package:supabase_flutter/supabase_flutter.dart'; // To use the features of Supabase
import 'package:uuid/uuid.dart'; // To generate unique ID
import 'package:to_do_list/models/task_model.dart'; // File path to the task model to convert the list data into the map data
import 'package:collection/collection.dart';

/* Here all the function are declear with the (Future) Keyword why? 
The answer is that here all the function need to run in backend and take time to complete. So we use (Future) to tell the flutter that this function take time so dont wait for this to complete and move to the next step.
So that the application will not hang and it will run smoothly. And when this function complete it will return the value to the main function.
*/
class TaskRepository 
{
  // Variable declaration
  static Database? _db; //initialize the variable for database with the database type and it is a static variable it means one database can be used across multi object and can be null
  final _table = stringMapStoreFactory.store('tasks'); // To create a table in the database with the name (tasks)
  final _supabase = Supabase.instance.client; // Declare variable to use the supabase function
  final _uuid = const Uuid(); // Declare a variable to use the UUID function to generate unique ID for each task

  // Database initialization
  Future<Database> get dbcreation async {
    if (_db != null) {// check the database is created or not
    return _db!; // If created retruns it otherwise move to the next if statement and that (_) means it is private variable and (!) means it can't a null value
    } 

    if (kIsWeb) // Check if the application is running in web browser or not
    {
      _db = await databaseFactoryWeb.openDatabase('tasks.db'); // declare the database in the bulid-in browser database (IndexedDB)
    } 
    else 
    { // If the application runs in moblie
      final appDir = await getApplicationDocumentsDirectory(); //Get the internal storage path as (/data/data/com.Task_Managment/app_flutter/tasks_data.db) which is not directly visible in file manager
      final dbPath = join(appDir.path, 'tasks_data.db'); //Append the appdir path with tasks (Internal storage/Android/Data/tasks_data)
      _db = await databaseFactoryIo.openDatabase(dbPath); // Declare the database in the provided path
    }
    return _db!;
  }

  // Add Task
  Future<void> addTask(TaskModel task) async { //This function is called from the add_task.dart file to add tasks in the local database
    final db = await dbcreation; // Initialize the database

    task.taskId = _uuid.v4(); // create a Unique ID for each task
    task.createdAt = DateTime.now(); // Assign the current time of the task creatation
    task.userId = _supabase.auth.currentUser?.id; // To get the User ID
    task.isSynced = false; // Initial value is because it is not synced with supabase
    task.updatedAt = DateTime.now(); // Assign the current time of the task creatation or edited

    // Here the consider the [database] -> (Storage cabin) and the [task ID] -> (Folder name) and the [task data] -> (File inside the folder) and the [put] function is used to store the data.
    await _table.record(task.taskId).put(db, task.toMap());// It first ckeck that is they is any record with the given (task ID) if exist then edits it else create a new record with the given (task ID) and store the data in the database.

    // Check internet connection and sync it the supabase
    final connectivity = await Connectivity().checkConnectivity(); //  Create a variable for Connectivity function
    if (connectivity != ConnectivityResult.none) { // If the internet connected
      await _syncTask(task); // It call the Synctask function
    }
 
  }

  // Edit Task
  Future<void> editTask(TaskModel task) async {// The parameter is in the TaskModel object format/type
    final db = await dbcreation;
    
    task.isSynced = false; // sync become false to move it to the pending list of the task to be synced with the supabase

    await _table.record(task.taskId).put(db, task.toMap()); // The task is already exist in the database so it will edit the data in the database by accessing it by the task ID (Like a folder name)

    final connectivity = await Connectivity().checkConnectivity(); // When the function closed it will delete this variable from the memory so we need to create variable it again to check the internet connection
    if (connectivity != ConnectivityResult.none) {
      await _syncTask(task); // Sync to the supabase if internet available
    }
 
  }

  // Sync single task to Supabase
  Future<void> _syncTask(TaskModel task) async {

    if(_supabase.auth.currentUser == null) return;

    try { //Try we try-catch block to avoid crashing the application

      task.userId = _supabase.auth.currentUser!.id; // To get the User ID
      await _supabase.from('focus_hub').upsert(task.toSupabaseMap());
      task.isSynced = true; // If sync Success → update isSynced = true in local database (sembast)

      final db = await dbcreation; // db (local variable) is killed at end of function but _db (static variable) stays alive entire app lifetime (both db and _db are different)
      await _table.record(task.taskId).put(db, task.toMap()); // Updating the value

    } catch (e) {
      debugPrint('Sync failed: $e'); // isSynced stays false — will retry later and tells what goes wrong
    }
 
  }

  // ✅ Sync all pending tasks (called when internet returns)
  Future<void> syncPendingTasks() async {
    final db = await dbcreation; // Call the database db store the object of the database not the actual database

    if(_supabase.auth.currentUser == null) return;

    final findcase = Finder( filter: Filter.equals('isSynced', false),); // The finder is a in-build function in the sembast and filter is the in-built function in finder to find all tasks where isSynced = false
    final records = await _table.find(db, finder: findcase); //This statement takes all records from the table (tasks) table in the Sembast database that match the condition defined in the finder (i.e., isSynced = false), and stores them in the records variable
    final pendingTasks = records.map((r) => TaskModel.fromMap(r.value)).toList(); /* This statement convert the list of map data in the records into the list of task model data and store it in the pendingTasks variable 
    where records.map() is used to iterate through each record and r.value is the actual value of the record that is converted into the task model data using the fromMap function and then convert it into the list using toList() function*/

    for (var task in pendingTasks) // call the syncTask function until all task are synced
    {
      await _syncTask(task);
    }
 
  }

  // Delete task
  Future<void> deleteTask(String taskId) async { // In this function it comes with a task ID 
    final db = await dbcreation;
    await _table.record(taskId).delete(db); // Delete that task from sembast
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) // Delete from Supabase if internet available
     {
      await _supabase.from('focus_hub').delete().eq('Task_id', taskId); // It means from the table focus_hub delete a task which task ID is equal to the given task_ID
    }
 
  }

  // Complete task
  Future<void> completeTask(TaskModel task) async {

    final db = await dbcreation;
    task.updatedAt = DateTime.now();
    task.isSynced = false; // And sync as false to move it to the pending list
    if(task.complete_date == null){
      task.complete_date = DateTime.now();
    }
    else{
      task.complete_date = null;
    }

    await _table.record(task.taskId).put(db, task.toMap()); // Update sembast 

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      await _syncTask(task); // Sync to the supabase if internet available
    }
 
  }

  // Get all tasks
  Future<List<TaskModel>> getAllTasks() async {
  final db = await dbcreation;

  final condition = Finder(sortOrders: 
    [
      SortOrder('isComplete',true), // -> sort by isComplete in ascending order (false first then true).
      SortOrder('createdAt',false),
    ],); 
    /* Finder is like a query/condition used in find to get the data as per given query/condition.
    It like a variable used to store the query/condition */
    /* SortOrder is the condition used for sorting.
    SortOrder(field_name, ascending)
    Field_name -> can be any field in the TaskModel 
    Ascending -> It is a binary value:[true for ascending], [false for descending] */
    final records = await _table.find(db, finder: condition); // -> FInd the record as per the given finder condition in database and store it in the [records variable]
    return records.map((r) => TaskModel.fromMap(r.value)).toList(); // The [records] contain key value pair and (all the values we want are stored in the value not in the key only store the task ID so we need to convert the value)into the taskModel object
    /*      |      |    |           |             |         |
           \|/    \|/  \|/         \|/           \|/       \|/
        Contain   It's  This       The function to call    Convert the result 
        Key-value like  represent                          into the list of 
        pair      a     the variable [records].                      taskModel object
                  for-loop 
                  it create a iterable 
                  that repectly call 
                  like for loop.  
    */
  }

  Future<void> pullTasksFromSupabase() async {
    if (_supabase.auth.currentUser == null) return;
    try { // ← wrap everything
      final db = await dbcreation; // Checking the database connection

      final findcondition = Finder(filter: Filter.notNull('userId')); // condition to get every task with used ID
      final localtask = await _table.find(db, finder : findcondition); // store all the local task
      final local = localtask.map((r) => TaskModel.fromMap(r.value)).toList(); // Convert it into dart object then list

      final response = await _supabase.from('focus_hub').select().eq('User_id', _supabase.auth.currentUser!.id); // geting all the records from the supabase
      final supabase = response.map((r) => TaskModel.fromSupabaseMap(r)).toList(); // Convert it into dart object then list

      
      for (var row in local) { // Iterate with every task in local
        try {
          final onetask = supabase.firstWhereOrNull((task) => task.taskId == row.taskId); // Find the task in the supabase which is currently in loop
          if (onetask != null){ // if find the task
            if (onetask.updatedAt.isAfter(row.updatedAt)){ // Then check the task in both are updated in same date or the task in supabase updated after the local task
              await _table.record(onetask.taskId).put(db, onetask.toMap()); // Then update the local task
            }
          }
          else{ // If not in the supabase delete it
            deleteTask(row.taskId);
          }
        } catch (e) {
          debugPrint('row parse failed: $e → row: $row'); // ← see which row fails
        }
      }

      for (var row in supabase){ // Iterate with every task in supabase
        try{
          final onetask = local.firstWhereOrNull((task) => task.taskId == row.taskId); // Find the task in the supabase which is currently in loop
          if(onetask == null){ // if the task is not the local database then add it
            await _table.record(row.taskId).put(db, row.toMap());
          }
        } catch(e) {
          debugPrint('row parse failed: $e → row: $row'); // ← see which row fails
        }
      }

    } catch (e) {
      debugPrint('pull failed: $e');
    }
  }

  // Get the guset task
  Future<bool> guesttask()async {
    final db = await dbcreation;
    final task = Finder(filter: Filter.isNull('userId')); // Filter condition by task with userId value is null that means the task created by guest user
    final record = await _table.find(db,finder: task); // Find the record as per the given finder condition in database and store it in the [record variable]
    return record.isNotEmpty; // If the record is not empty that means there is a task created by guest user so return [true] otherwise return [false]
    // [isNotEmpty] check the length of record is empty or not and return [boolean value]
  }

  // Get the guset task count
  Future<int> guesttaskcount()async {
    final db = await dbcreation;
    final task = Finder(filter: Filter.isNull('userId'));
    final record = await _table.find(db,finder: task);
    return record.length; // Return the length of the filtered records same as the guesttask() 
  }

  // Delete the user task when the [user logout]
  Future<void> deleteusertask()async {
    final db = await dbcreation;
    final task = Finder(filter: Filter.notNull('userId')); // Filter the task with usedID which is create by a user
    await _table.delete(db,finder: task);
  // Then delete the user task from the local database (sembast) and the guest task will remain in the local database
  }

  // Live data update functions

  Future<void>addlivedata(TaskModel task)async{
    final db = await dbcreation; // Check the database
    final existingRecord = await _table.record(task.taskId).get(db); // Check if the task is already exist or not
    if (existingRecord == null) { // if not add it
      await _table.record(task.taskId).put(db, task.toMap());
    }
 
  }
  Future<void> livedataupdate(TaskModel task) async{
    final db = await dbcreation;
    await _table.record(task.taskId).put(db, task.toMap()); // Rewrite the existing data
  }

  Future<void> livedelete(String task) async{
    final db = await dbcreation;
    await _table.record(task).delete(db); // Delete the task from the local database which is not in the supabase
  }   
  
}