import 'package:flutter/material.dart';
import 'package:to_do_list/Screen/widget.dart';
import 'package:to_do_list/models/task_model.dart';
import 'package:to_do_list/repository/task_repository.dart';

class Addtask extends StatefulWidget {
  const Addtask({super.key});

  @override
  State<Addtask> createState() => _AddtaskState();
}

class _AddtaskState extends State<Addtask> {

  TextEditingController task = TextEditingController();
  String priority = "Low"; 
  TextEditingController category = TextEditingController();
  TextEditingController date = TextEditingController();
  FocusNode dateFocus = FocusNode();
  final _repository = TaskRepository(); 
  DateTime? selectedDate;                
  bool _isLoading = false;             

  Future<void> _addTask() async {
  if (task.text.isEmpty) {
    showLocalSnackbar(
      context,
      message: 'Task name cannot be empty 😅',
      type: SnackbarType.warning,
    );
    return;
  }
  setState(() => _isLoading = true);
  final newTask = TaskModel(
    taskId: '',
    taskName: task.text,
    priority: priority,
    category: category.text.isEmpty ? null : category.text,
    deadline: selectedDate,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now()
  );
  try {
    await _repository.addTask(newTask);
    if (mounted) Navigator.pop(context, true);
  } catch (e) {
    showLocalSnackbar(
      context,
      message: 'Error 🤔: $e',
      type: SnackbarType.error,
    );
  }
  finally {
  if (mounted) setState(() => _isLoading = false); // ← always runs ✅
}
}

  @override
  void dispose() {
    task.dispose();
    category.dispose();
    date.dispose();
    dateFocus.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 22, 27, 34),
      body: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 22, 27, 34),
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics() ,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Add Task",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Color(0xFF00FF00),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_circle_right_outlined,size: 40, color: Color(0xFF00FF00)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                
                    const SizedBox(height: 5),
                
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        "Task name",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                
                    const SizedBox(height: 5),
                
                    Textstyler(controller: task, hint: "Enter your task"),
                
                    const SizedBox(height: 20),
                
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Expanded(
                              child : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Priority",style: TextStyle(color: Colors.white54),),
                                      Theme(
                                        data: Theme.of(context).copyWith(
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                        ),
                                        child: DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          initialValue: priority,
                                          dropdownColor: const Color.fromARGB(255, 22, 27, 34),
                                          borderRadius: BorderRadius.circular(10),
                                          style: const TextStyle(color: Colors.white54),
                                        
                                          decoration: InputDecoration(
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(color: Colors.white54),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(color: Color(0xFF00FF00)),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        
                                          items: ["High", "Medium", "Low"].map((value) {
                                            return DropdownMenuItem(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                        
                                          onChanged: (value) {
                                            setState(() {
                                              priority = value!;
                                            });
                                          },
                                        ),
                                      ),
                                          ],),),
                
                            const SizedBox(width: 10),
                            
                            Expanded(
                              child: Column(
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: const Text("Category", style: TextStyle(color: Colors.white54)),
                                  ),
                                  Textstyler(controller: category, hint: "Enter your category"),
                                ],
                              ),
                            ),
                        ],
                      ),
                
                    const SizedBox(height: 20),
                
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            "Deadline",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white54,
                            ),
                          ),),
                        TextField(
                          controller: date,
                          readOnly: true,
                          focusNode: dateFocus,
                          showCursor: false,
                          style: const TextStyle(color: Colors.white54),
                          decoration: InputDecoration(
                            hintText: "Select date",
                            hintStyle: const TextStyle(color: Colors.white54),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white54),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFF00FF00)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: date.text.isNotEmpty ? 
                            IconButton(icon: Icon(Icons.cancel_outlined,size: 20),
                            color: Colors.white54,
                            tooltip: "Clear date",
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            padding: const EdgeInsets.only(right: 10),
                            onPressed: () {
                              setState(() {
                                date.clear();
                                selectedDate = null;
                              });}) : null,
                          ),
                          onTap: () async {
                            dateFocus.unfocus();
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2200),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF00FF00),
                                      onPrimary: Colors.black,
                                      surface: Color.fromARGB(255, 22, 27, 34),
                                      onSurface: Colors.white,
                                    ),
                                  ),
                                  child: MediaQuery(data: MediaQuery.of(context).copyWith(
                                    size: Size(400, MediaQuery.of(context).size.height),
                                    ),
                                    child: Center(
                                      child: child!,
                                  ),
                                ));
                              },
                            );
                
                            if (pickedDate != null) {
                              setState(() {
                              selectedDate = pickedDate;
                              date.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                              });
                            }
                        },),
                      ],
                    ),
                
                    const SizedBox(height: 20),
                
                    _isLoading ? const CircularProgressIndicator(color: Color(0xFF00FF00)): ElevatedButton(
                        onPressed: _addTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          maximumSize: const Size(250, 50),
                        ),
                        child: const Text(
                          "Add Task",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
      }
    }