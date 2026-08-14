import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/repository/task_repository.dart';
import 'Screen/task_view.dart';
import 'Screen/widget.dart';
import 'Screen/add_task.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://zdmiohkywkyfajfmbhyp.supabase.co",
    // ignore: deprecated_member_use
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpkbWlvaGt5d2t5ZmFqZm1iaHlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM5MzAwMDMsImV4cCI6MjA4OTUwNjAwM30.VntnNex5t-cnTNGmNtcF2M4Stz6URsd9LrnfRIk-qsQ",
  );
  runApp(const Homepage());
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _Homepagestate();
}

class _Homepagestate extends State<Homepage> {
  final _taskview = GlobalKey<TaskviewState>(); // Create a global key to access the TaskviewState and refresh the UI after adding a task
  final TextEditingController inputdata = TextEditingController();
  final _supabase = Supabase.instance.client;
  final _repository = TaskRepository();
  bool iscategory = false;
  String? keyword; // New variable to track the search keyword
  String? activeFilter; // New variable to track the active filter
  bool get isLoggedIn => _supabase.auth.currentUser != null;
  late final StreamSubscription<AuthState> _authSubscription;
  late final StreamSubscription _connectivitySubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();

  Future<void> _checkTaskCount(BuildContext context) async {
    final count = await _repository.guesttaskcount();
    if (count % 3 == 0 && count > 0 && !isLoggedIn) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color.fromARGB(255, 22, 27, 34),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text(
            "Hey! Just a quick note",
            style: TextStyle(color: Color(0xFF00FF00), fontWeight: FontWeight.bold),
          ),
          content: Text(
            "Your $count tasks are currently saved locally.\n\n"
            "If you accidentally clear the browser data, "
            "then it can't be recovered!\n\n"
            "Secure your tasks by backing them up \n\nwith your Google account.",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Maybe later", style: TextStyle(color: Colors.white54)),
                ),
                SizedBox(width: 10),
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: Color(0xFF00FF00)),
                  onPressed: () async {
                    await _supabase.auth.signInWithOAuth(OAuthProvider.google, redirectTo: kIsWeb ? '${Uri.base.origin}/' : 'io.supabase.todolist://login-callback');
                    Navigator.pop(context);
                  },
                  child: const Text("Login with Gmail", style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState(); // This function will be start first at main.dart file call
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async { // Get the auth state details that cantains only (event and session) in JSON 
    
      if(data.event == AuthChangeEvent.initialSession){
        if(data.session == null){
          return;
          }

        Future.delayed(Duration(milliseconds: 300), () async{
          if(!mounted) return;
          await _repository.pullTasksFromSupabase();
          await _taskview.currentState?.taskdata();
          _taskview.currentState?.listenRealtime();
          _repository.syncPendingTasks();
        });
        return;
      }

      if (data.event == AuthChangeEvent.tokenRefreshed || data.event == AuthChangeEvent.signedIn) {
        /* If it is (signin event) -> (New usr) or (tokenrefreshed event) -> (old user agin open the app / old user ID is used from the storage ) then */

        if (data.session == null) return;
        setState(() {}); // ← update UI immediately (avatar appears now)
        
        Future.delayed(Duration.zero, () async {
          if (!mounted) return;
          _taskview.currentState?.listenRealtime(); // ← start the websocket

          if (!(await _repository.guesttask())) {
            bool load = false; // To track the loading dialog state
            if (!load) { // Show the loading dialog only if it's not already open
              load = true; // Change the value to close the window in next call
              showDialog(
                context: _navigatorKey.currentContext!,
                barrierDismissible: false,  // user can't tap outside to close
                builder: (_) => const LoadingDialog(message: 'Syncing tasks...'),
              );
            }

            await _repository.pullTasksFromSupabase(); // Do the actual works getting all the tasks and show them
            await _taskview.currentState?.taskdata();

            if (load && _navigatorKey.currentContext!.mounted) { // Pop the loading window and reset the value
              Navigator.of(_navigatorKey.currentContext!).pop();
              load = false;
            }
            
            return;
          }

          await showDialog( // This will show when they is a guest task
            context: _navigatorKey.currentContext!,
            builder: (context) => ScaffoldMessenger(
            child : Dialog(
              backgroundColor: Color.fromARGB(255, 13, 17, 23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: Colors.white),
              ),
              child: SizedBox(height: MediaQuery.of(context).size.height < 450 ? 350 : 400, width: MediaQuery.of(context).size.width < 450 ? double.infinity : 400, child: Syncscreen()), // Call this syncscreen() class to get the user opinion to sync or not the guest task
            ),),
          );
          await _taskview.currentState?.taskdata(); // refresh tasks after sync
        });
      }

      if (data.event == AuthChangeEvent.signedOut) { // Trigger when the user logout
        Future.delayed(Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {}); // this was already immediate, should be fine
          _taskview.currentState?.taskdata();
        });
      }
    });
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none && isLoggedIn) { // get the status of the internet if internet is connected and user logged in
        _repository.syncPendingTasks();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    inputdata.dispose();
    iscategory = false; // Reset the category filter when the widget is disposed
    _connectivitySubscription.cancel();
    _taskview.currentState?.listenRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            "Focus Hub",
            style: TextStyle(fontFamily: 'Teko', fontWeight: FontWeight.bold, fontSize: 35, color: Color(0xFF00FF00)),
          ),
          backgroundColor: const Color.fromARGB(255, 22, 27, 34),
          leading: IconButton(
            icon: Icon(Icons.task_alt, color: Color(0xFF00FF00), size: 35),
            onPressed: () => {},
          ),
          actions: [
            Builder(
              builder: (context) => Padding(
                padding: EdgeInsets.only(right: 20),
                child: GestureDetector(
                    onTap: () => // use isloggedIn to determine whether to show the sign out dialog or the sign in dialog
                      showDialog(
                        context: context,
                        builder: (context) => ScaffoldMessenger(
                          child : Dialog(
                          backgroundColor: Color.fromARGB(255, 13, 17, 23),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.white),
                          ),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height < 450 ? 350 : 400,
                            width: MediaQuery.of(context).size.width < 450 ? double.infinity : 400,
                            child: isLoggedIn ? Logscreen(textword: "Sign out", method: false) : Logscreen(textword: "Continue with Google", method: true), // use isloggedIn to determine whether to show sign in or sign out
                            ),
                          ),
                        ),
                      ),
                  child: isLoggedIn
                      ? (isLoggedIn &&
                                _supabase.auth.currentUser?.userMetadata?['avatar_url'] !=
                                    null // use isloggIn to set the icon or avatar
                            ? CircleAvatar(backgroundImage: NetworkImage(_supabase.auth.currentUser!.userMetadata!['avatar_url']), radius: 18)
                            : Icon(Icons.account_circle, color: Color(0xFF00FF00), size: 30))
                      : Icon(Icons.login_rounded, color: Color(0xFF00FF00), size: 35),
                ),
              ),
            ),
          ],
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color.fromRGBO(13, 17, 23, 1),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600; /* check the width of the parent widget to determine whether to use the column or row layout, you can adjust the breakpoint as needed */
                  final searchbox = Expanded(
                    child: Container(
                      height: 48,
                      margin: EdgeInsets.only(top: 20),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(color: Color.fromARGB(255, 22, 27, 34), borderRadius: BorderRadius.circular(25)),
                      child: TextField(
                        controller: inputdata,
                        onChanged: (value) {
                          keyword = value; // Update the search keyword whenever the user types in the search bar
                          _taskview.currentState?.filter(activeFilter ?? 'All', keyword ?? '', iscategory);
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.white54),
                          suffixIcon: inputdata.text != "" ? IconButton(
                            icon: Icon(Icons.clear),
                            hoverColor: Colors.transparent,
                            color: Colors.white54,
                            onPressed: () {
                              keyword = '';
                              inputdata.clear();
                               _taskview.currentState?.filter(activeFilter ?? 'All', keyword ?? '', iscategory);
                              setState(() {});
                            }
                          ) : null,
                          hintText: 'Search bar',
                          hintStyle: TextStyle(color: Color.fromARGB(255, 117, 117, 115), fontWeight: FontWeight.w700, fontSize: 20),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                  );

                  final filter = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 125,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 22, 27, 34), // Highlight if a filter is active
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
                          child: PopupMenuButton<String>(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.white, width: 2),
                            ),
                            tooltip: '',
                            splashRadius: null,
                            color: Color.fromARGB(255, 22, 27, 34),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'All',
                                child: Text('Clear Filter', style: TextStyle(color: Colors.white54)),
                              ),
                              const PopupMenuItem(
                                value: 'Deadline',
                                child: Text('By deadline', style: TextStyle(color: Colors.white54)),
                              ),
                              const PopupMenuItem(
                                value: 'High',
                                child: Text('High Priority', style: TextStyle(color: Colors.white54)),
                              ),
                              const PopupMenuItem(
                                value: 'Medium',
                                child: Text('Medium Priority', style: TextStyle(color: Colors.white54)),
                              ),
                              const PopupMenuItem(
                                value: 'Low',
                                child: Text('Low Priority', style: TextStyle(color: Colors.white54)),
                              )
                            ],
                            onSelected: (value) {
                              setState(() {
                                activeFilter = activeFilter == value ? null : value; // toggle off if same
                                keyword = ''; // Clear the search keyword when a filter is selected
                                inputdata.clear(); // Clear the search bar when a filter is selected
                                _taskview.currentState?.filter(activeFilter ?? 'All', keyword ?? '', iscategory); // Call the filter function in TaskviewState to filter the task list based on the selected priority
                              });
                            },

                            child: Center(
                              child: Text(
                                activeFilter != null ? activeFilter == 'All' ? 'Filter By': activeFilter!: 'Filter By',
                                style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      ElevatedButton(
                        onPressed: () => {
                          setState(() {
                            iscategory ? iscategory = false : iscategory = true;
                            _taskview.currentState?.filter(activeFilter ?? 'All', keyword ?? '', iscategory);
                          }),
                        },
                        style: ElevatedButton.styleFrom(fixedSize: const Size.fromHeight(48), backgroundColor: iscategory == false ? Color.fromARGB(255, 22, 27, 34) : Colors.white, foregroundColor: Colors.transparent),
                        child: Text(
                          'Category',
                          style: TextStyle(color: iscategory == false ? Colors.white54 : Color.fromARGB(255, 22, 27, 34), fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width * 0.8).clamp(350, 800),
                      height: 125, // Careful with this fixed height, if the height is given to mush the gap b/w the search box and filter will be too much, if given to less the filter will be too close to the search box
                      child: Column(
                        children: [
                          searchbox,
                          SizedBox(height: 10),
                          Center(child: filter),
                        ],
                      ),
                    );
                  }
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width * 0.8).clamp(350, 800),
                    child: Row(
                      children: [
                        searchbox,
                        SizedBox(width: 10),
                        Container(
                          margin: EdgeInsets.only(top: 20), // ← margin only in desktop
                          child: filter,
                        ),
                      ],
                    ),
                  );
                },
              ),

              Expanded(child: Taskview(key: _taskview)),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () async {
              final added = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => Center(
                  child: ScaffoldMessenger(
                  child: Container(
                    clipBehavior: Clip.hardEdge, // it prevents the content from Addtask is overflowing outside the container when the keyboard appears
                    decoration: BoxDecoration(color: Color.fromARGB(255, 13, 17, 23), borderRadius: BorderRadius.circular(15)),
                    width: (MediaQuery.of(context).size.width * 0.75).clamp(100, 475),
                    height: (MediaQuery.of(context).size.height * 0.6).clamp(420, 475),
                    child: const Addtask(),
                  ),
                 ),
                ),
              );
              // ✅ if statement trigger after task added
              if (added == true) {
                _taskview.currentState?.taskdata(); // Call the loadTasks function in TaskviewState to refresh the task list after adding a new task
                setState(() {});
                await _checkTaskCount(context); // ← trigger check
              }
            },
            backgroundColor: const Color(0xFF00FF00),
            shape: const CircleBorder(),
            child: const Icon(Icons.add_task_rounded, color: Colors.black, size: 35),
          ),
        ),
      ),
    );
  }
}
