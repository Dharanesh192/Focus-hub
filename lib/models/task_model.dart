class TaskModel // This is a custom database for this project
 {
  String taskId;           // Unique identifier (UUID) used for local storage and Supabase synchronization.
  String? userId;          // Logged in user ID. Get from the Supabase authentication module. It is optional because when the user is not logged in, it can be null. 
  String taskName;         // Compulsory
  String priority;         // (High, Medium, Low) but it has a default value as (Medium)
  String? category;        // category is Optional 
  DateTime? deadline;      // Optional deadline for the task
  bool isComplete;         // It is a binary value as (True/False)
  bool isSynced;           // It is a binary value as (True/False)
  DateTime createdAt;      // It inputs are date and time
  DateTime updatedAt;      // It inputs are date and time
  DateTime? complete_date; // It inputs are date and time
  
 
  TaskModel({ // This is constructor used to creat the object of the task model class
    required this.taskId,  // if they is required — (It is compelsory to give value)
    this.userId,           // if not - (It is a optional input value)
    required this.taskName,
    required this.priority,
    this.category,
    this.deadline,
    this.isComplete = false,   // Initially it has a (False) value 
    this.isSynced = false,     // Initially it has a (False) value 
    required this.createdAt,
    required this.updatedAt,
    this.complete_date
  });

  // Map -> (is a collection of [key : value] pair) used to convert the (dart object) into (JSON format) for storing in sembast
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId, // All this variables get the value from this variables and it in the sembast
      'userId': userId,
      'taskName': taskName,
      'priority': priority,
      'category': category,
      'deadline': deadline?.toIso8601String(), // It change the datatype from Datetime -> String. Why (Sembast) store the data in JSON fromat and the JSON doresn't support the Datetime format
      'isComplete': isComplete,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'complete_date': complete_date?.toIso8601String()
    };
  }

  // Map -> (is a collection of [key : value] pair) used to convert the (dart object) into (JSON format) for storing in Supabase rows
  Map<String, dynamic> toSupabaseMap() {
    return {
      // The columns should match with the Supabase table
      'Task_id': taskId,
      'User_id': userId,
      'Task_name': taskName,
      'Deadline': deadline?.toIso8601String(),
      'Category': category,
      'Priority': priority,
      'is_complete': isComplete,
      'Created_date': createdAt.toIso8601String(),
      'Updated_at': updatedAt.toIso8601String(),
      'Completed_date': complete_date?.toIso8601String()
    }; // The variable name must match the column of the supabase table 
}

  // // Creates a TaskModel object from retrieved data from Sembast. Changing the (JSON format from sembast) into (TaskModel object)
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      taskId: map['taskId'],
      userId: map['userId'],
      taskName: map['taskName'],
      priority: map['priority'],
      category: map['category'],
      deadline: map['deadline'] != null // If the date is not null
          ? DateTime.parse(map['deadline']) // Then converts the stored ISO 8601 string back into a DateTime object.
          : null, // else store it as null as well
      isComplete: map['isComplete'] ?? false, // If the value is null, use false as the default value.
      isSynced: map['isSynced'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      complete_date: map['deadline'] != null 
          ? .parse(map['deadline']) 
          : null
    );
  }

  // Changing the (JSON format from Supabase) into (Dart object) for the dart to use it in the app
  factory TaskModel.fromSupabaseMap(Map<String, dynamic> row) {
  return TaskModel(
    taskId: row['Task_id'],
    userId: row['User_id'],
    taskName: row['Task_name'],
    priority: row['Priority'],
    category: row['Category'],
    deadline: row['Deadline'] != null ? DateTime.parse(row['Deadline']) : null, // Converts the stored ISO 8601 string back into a DateTime object.
    isComplete: row['is_complete'] ?? false,
    isSynced: true, // always true — just came from Supabase
    createdAt: DateTime.parse(row['Created_date']),
    updatedAt: DateTime.parse(row['Updated_at']),
    complete_date: row['Completed_date'] != null ? DateTime.parse(row['Completed_date']) : null
  );
}

}
