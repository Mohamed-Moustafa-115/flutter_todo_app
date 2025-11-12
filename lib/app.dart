import 'package:flutter/material.dart';
import 'package:flutter_todo_app/services/sqlite.dart';
import 'package:sqlite_async/sqlite_async.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  SqliteDatabase? _database;
  List<Map<String, dynamic>> _items = [];
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  void _loadDatabase() async {
    _database = await SqliteService().initDataBase();
    _items = await _database!.getAll("SELECT * FROM test_data");
    setState(() {
      _items;
    });
  }

  @override
  void initState() {
    _loadDatabase();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Todo App'),
        centerTitle: true,
        backgroundColor: Colors.lime,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              Table(
                border: TableBorder.all(),
                children: const [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'ID',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Title',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Description',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Actions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    return Table(
                      border: TableBorder.all(),
                      children: [
                        TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(_items[index]['id'].toString()),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(_items[index]['title'].toString()),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                _items[index]['description'].toString(),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                _items[index]['status'] == 1
                                    ? 'Pending'
                                    : 'Completed',
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      int? localSelectedOption;
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return StatefulBuilder(
                                            builder: (context, setLocalState) {
                                              return AlertDialog(
                                                title: Text('Add New Todo'),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    TextField(
                                                      controller:
                                                          titleController,
                                                      decoration:
                                                          InputDecoration(
                                                            labelText: 'Title',
                                                          ),
                                                    ),
                                                    TextField(
                                                      controller:
                                                          descriptionController,
                                                      decoration:
                                                          InputDecoration(
                                                            labelText:
                                                                'Description',
                                                          ),
                                                    ),
                                                    RadioListTile<int>(
                                                      title: Text(
                                                        'Primary Color',
                                                      ),
                                                      value: 1,
                                                      groupValue:
                                                          localSelectedOption,
                                                      activeColor: Colors.blue,
                                                      onChanged: (int? value) {
                                                        setLocalState(() {
                                                          localSelectedOption =
                                                              value;
                                                        });
                                                      },
                                                    ),
                                                    RadioListTile<int>(
                                                      title: Text(
                                                        'Secondary Color',
                                                      ),
                                                      value: 2,
                                                      groupValue:
                                                          localSelectedOption,
                                                      activeColor: Colors.green,
                                                      onChanged: (int? value) {
                                                        setLocalState(() {
                                                          localSelectedOption =
                                                              value;
                                                        });
                                                      },
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      String title =
                                                          titleController.text;
                                                      String description =
                                                          descriptionController
                                                              .text;
                                                      int status =
                                                          localSelectedOption ??
                                                          0;

                                                      await _database!.execute(
                                                        'INSERT INTO test_data (title, description, status) VALUES (?, ?, ?)',
                                                        [
                                                          title,
                                                          description,
                                                          status,
                                                        ],
                                                      );
                                                      titleController.clear();
                                                      descriptionController
                                                          .clear();
                                                      _loadDatabase();
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                                    child: Text('Add'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return StatefulBuilder(
                                            builder: (context, setLocalState) {
                                              return AlertDialog(
                                                title: Text('Confirm Deletion'),
                                                content: Text(
                                                  'Are you sure you want to delete this item?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                                    child: Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      await _database!.execute(
                                                        'DelETE FROM test_data WHERE id = ?',
                                                        [
                                                          _items[index]['id']
                                                        ],
                                                      );
                                                      titleController.clear();
                                                      descriptionController
                                                          .clear();
                                                      _loadDatabase();
                                                      Navigator.of(
                                                        context,
                                                      ).pop();
                                                    },
                                                    child: Text('Delete'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  itemCount: _items.length,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primaryFixed,
        onPressed: () {
          int? localSelectedOption;
          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setLocalState) {
                  return AlertDialog(
                    title: Text('Add New Todo'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(labelText: 'Title'),
                        ),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(labelText: 'Description'),
                        ),
                        RadioListTile<int>(
                          title: Text('Primary Color'),
                          value: 1,
                          groupValue: localSelectedOption,
                          activeColor: Colors.blue,
                          onChanged: (int? value) {
                            setLocalState(() {
                              localSelectedOption = value;
                            });
                          },
                        ),
                        RadioListTile<int>(
                          title: Text('Secondary Color'),
                          value: 2,
                          groupValue: localSelectedOption,
                          activeColor: Colors.green,
                          onChanged: (int? value) {
                            setLocalState(() {
                              localSelectedOption = value;
                            });
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          String title = titleController.text;
                          String description = descriptionController.text;
                          int status = localSelectedOption ?? 0;

                          await _database!.execute(
                            'INSERT INTO test_data (title, description, status) VALUES (?, ?, ?)',
                            [title, description, status],
                          );
                          titleController.clear();
                          descriptionController.clear();
                          _loadDatabase();
                          Navigator.of(context).pop();
                        },
                        child: Text('Add'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
