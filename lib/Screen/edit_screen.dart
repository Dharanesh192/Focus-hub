import 'package:flutter/material.dart';
import 'package:to_do_list/Screen/widget.dart';
import 'package:to_do_list/models/task_model.dart';
import 'package:to_do_list/repository/task_repository.dart';

class Edittask extends StatefulWidget {

  final String currenttask;
  final String currentpriority;
  final String? currentcategory;
  final DateTime? currentdeadline;
  final String taskId;
  final DateTime created; 
  final bool completion;
  
  const Edittask({
    required this.currenttask,
    required this.currentpriority,
    this.currentcategory,
    this.currentdeadline,
    required this.taskId,
    required this.created,
    required this.completion,
    super.key
  });

  @override
  State<Edittask> createState() => _EdittaskState();
}

class _EdittaskState extends State<Edittask> {


  late TextEditingController edittask;
  late DateTime editcreated;
  late String edittaskId;
  late String editpriority; 
  late TextEditingController editcategory;
  late TextEditingController date;
  FocusNode dateFocus = FocusNode();
  final _repository = TaskRepository(); 
  DateTime? editselectedDate;                
  bool _isLoading = false;            

  @override
  void initState() {
    edittask = TextEditingController(text: widget.currenttask);
    editpriority = widget.currentpriority;
    edittaskId = widget.taskId;
    editcreated = widget.created;
    editcategory = TextEditingController(text: widget.currentcategory  ?? '');
    date = TextEditingController(text: widget.currentdeadline != null
        ? "${widget.currentdeadline!.day}/${widget.currentdeadline!.month}/${widget.currentdeadline!.year}"
        : "",);
    editselectedDate = widget.currentdeadline;
    super.initState();
    }

  @override
  void dispose() {
    edittask.dispose();
    editcategory.dispose();
    date.dispose();
    dateFocus.dispose();
    super.dispose();
  }


// create a function in task_repository.dart to update the data in sembast and supabase
  Future<void> _editTask() async {

      if (edittask.text.isEmpty) {
        showLocalSnackbar(
          context,
          message: 'Task name cannot be empty 😅',
          type: SnackbarType.warning,
        );
    return;
  }

  setState(() => _isLoading = true);
  final editTask = TaskModel(
    taskId: edittaskId,
    taskName: edittask.text,
    priority: editpriority,
    category: editcategory.text.isEmpty ? null : editcategory.text,
    deadline: editselectedDate,
    createdAt: editcreated,
    isComplete: widget.completion,
    updatedAt: DateTime.now(),
    complete_date: null
  );
  try{
  await _repository.editTask(editTask);
  if (mounted) Navigator.pop(context, true);
  }
  catch (e){
   showLocalSnackbar(
      context,
      message: 'Error 🤔: $e',
      type: SnackbarType.error,
    );
  }
  finally{
    setState(() => _isLoading = false);
  }
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
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Edit Task",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                            color: Colors.blue[300],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_circle_right_outlined,size: 40, color: Colors.blue[300]),
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
                
                    Editortextstyler(controller: edittask, hint: "Enter your task"),
                
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
                                          initialValue: editpriority,
                                          dropdownColor: const Color.fromARGB(255, 22, 27, 34),
                                          borderRadius: BorderRadius.circular(10),
                                          style: const TextStyle(color: Colors.white54),
                                        
                                          decoration: InputDecoration(
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(color: Colors.white54),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: const BorderSide(color:Color(0xFF64B5F6)),
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
                                              editpriority = value!;
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
                                  Editortextstyler(controller: editcategory, hint: "Enter your category"),
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
                              borderSide: const BorderSide(color:Color(0xFF64B5F6)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: date.text.isNotEmpty ? 
                            IconButton(icon: Icon(Icons.cancel_outlined, size: 20),
                            color: Colors.white54,
                            tooltip: "Clear date",
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            padding: const EdgeInsets.only(right: 10),
                            onPressed: () {
                              setState(() {
                                date.clear();
                                editselectedDate = null;
                              });}) : null,
                          ),
                          
                          onTap: () async {
                            dateFocus.unfocus();
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: editselectedDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2200),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color(0xFF64B5F6),
                                      onPrimary: Colors.black,
                                      surface: Color.fromARGB(255, 22, 27, 34),
                                      onSurface: Colors.white,
                                    ),
                                  ),
                                  child: MediaQuery(data: MediaQuery.of(context).copyWith(
                                    size: Size(400, MediaQuery.of(context).size.height),
                                    ),
                                  child: Center(
                                    child: SizedBox(
                                      child: child,
                                    ),
                                  ),
                                ));
                              },
                            );
                
                            if (pickedDate != null) {
                              setState(() {
                              editselectedDate = pickedDate;
                              date.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                              });
                              
                            }
                        },),
                      ],
                    ),
                
                    const SizedBox(height: 20),
                
                    _isLoading ? const CircularProgressIndicator(color: Color(0xFF64B5F6)): ElevatedButton(
                        onPressed: _editTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF64B5F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          maximumSize: const Size(250, 50), //width, height
                        ),
                        child: const Text(
                          "Update Task",
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