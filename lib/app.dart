import 'package:flutter/material.dart';
import 'services/sqlite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final SqliteService _dbService = SqliteService();
  List<Map<String, dynamic>> _items = [];
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _dbInfo = {};

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  void _loadDatabase() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Get database info first
      _dbInfo = await _dbService.getDatabaseInfo();
      print('Database info: $_dbInfo');

      // Initialize database
      await _dbService.initDatabase();
      
      // Load data
      _items = await _dbService.getAll("SELECT * FROM test_data");
      
      // Update db info
      _dbInfo = await _dbService.getDatabaseInfo();
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading database: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      
      _showErrorDialog(
        'Database Error',
        'Failed to initialize database:\n\nPath: ${_dbInfo['path']}\n\nError: $e',
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text(message),
                SizedBox(height: 16),
                _buildDebugInfoDialog(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadDatabase();
              },
              child: Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebugInfoDialog() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Debug Information:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          SizedBox(height: 4),
          Text('Path: ${_dbInfo['path'] ?? 'Unknown'}', style: TextStyle(fontSize: 10)),
          Text('File exists: ${_dbInfo['exists'] ?? 'Unknown'}', style: TextStyle(fontSize: 10)),
          Text('Directory: ${_dbInfo['directory'] ?? 'Unknown'}', style: TextStyle(fontSize: 10)),
          Text('Directory exists: ${_dbInfo['directory_exists'] ?? 'Unknown'}', style: TextStyle(fontSize: 10)),
          Text('Platform: ${_dbInfo['platform'] ?? 'Unknown'}', style: TextStyle(fontSize: 10)),
          Text('SQLite Type: ${_dbInfo['sqlite_type'] ?? 'Unknown'}', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Future<void> _showOperationDialog({
    required String title,
    required String message,
    required Future<void> Function() operation,
    String successMessage = 'Operation completed successfully!',
  }) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(child: Text(message)),
              ],
            ),
          );
        },
      );

      // Perform the operation
      await operation();

      // Close loading dialog and show success
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
        ),
      );

      // Reload data
      _loadDatabase();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error dialog
      _showErrorDialog(
        'Operation Failed',
        'Failed to complete operation: $e',
      );
    }
  }

  void _addItem() {
    int? localSelectedOption = 1;

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
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<int>(
                    title: Text('Pending'),
                    value: 1,
                    groupValue: localSelectedOption,
                    onChanged: (int? value) {
                      setLocalState(() {
                        localSelectedOption = value;
                      });
                    },
                  ),
                  RadioListTile<int>(
                    title: Text('Completed'),
                    value: 2,
                    groupValue: localSelectedOption,
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a title'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    await _showOperationDialog(
                      title: 'Adding Todo',
                      message: 'Please wait while we add your todo item...',
                      operation: () async {
                        await _dbService.execute(
                          'INSERT INTO test_data (title, description, status) VALUES (?, ?, ?)',
                          [titleController.text, descriptionController.text, localSelectedOption],
                        );
                        titleController.clear();
                        descriptionController.clear();
                      },
                      successMessage: 'Todo item added successfully!',
                    );
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
  }

  void _editItem(int index) {
    titleController.text = _items[index]['title'];
    descriptionController.text = _items[index]['description'];
    int? localSelectedOption = _items[index]['status'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: Text('Edit Todo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<int>(
                    title: Text('Pending'),
                    value: 1,
                    groupValue: localSelectedOption,
                    onChanged: (int? value) {
                      setLocalState(() {
                        localSelectedOption = value;
                      });
                    },
                  ),
                  RadioListTile<int>(
                    title: Text('Completed'),
                    value: 2,
                    groupValue: localSelectedOption,
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a title'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    await _showOperationDialog(
                      title: 'Updating Todo',
                      message: 'Please wait while we update your todo item...',
                      operation: () async {
                        await _dbService.update(
                          'UPDATE test_data SET title = ?, description = ?, status = ? WHERE id = ?',
                          [
                            titleController.text,
                            descriptionController.text,
                            localSelectedOption,
                            _items[index]['id']
                          ],
                        );
                        titleController.clear();
                        descriptionController.clear();
                      },
                      successMessage: 'Todo item updated successfully!',
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          icon: Icon(Icons.warning, color: Colors.orange),
          content: Text('Are you sure you want to delete "${_items[index]['title']}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _showOperationDialog(
                  title: 'Deleting Todo',
                  message: 'Please wait while we delete your todo item...',
                  operation: () async {
                    await _dbService.delete(
                      'DELETE FROM test_data WHERE id = ?',
                      [_items[index]['id']],
                    );
                  },
                  successMessage: 'Todo item deleted successfully!',
                );
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebugInfo() {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, size: 16, color: Colors.blue),
                SizedBox(width: 4),
                Text('Database Info:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            SizedBox(height: 4),
            Text('Path: ${_dbInfo['path'] ?? 'Unknown'}', style: TextStyle(fontSize: 10)),
            Text('File exists: ${_dbInfo['exists'] ?? 'Unknown'}', style: TextStyle(fontSize: 10)),
            Text('Directory: ${_dbInfo['directory'] ?? 'Unknown'}', style: TextStyle(fontSize: 10)),
            Text('SQLite: ${_dbInfo['sqlite_type'] ?? 'Unknown'}', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading database...'),
            SizedBox(height: 8),
            _buildDebugInfo(),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Database Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            SizedBox(height: 24),
            _buildDebugInfo(),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDatabase,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildDebugInfo(),
        SizedBox(height: 8),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Todo Items (${_items.length})',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No todo items yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the + button to add your first todo',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _items[index]['status'] == 1 ? Colors.orange : Colors.green,
                          child: Icon(
                            _items[index]['status'] == 1 ? Icons.pending : Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          _items[index]['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: _items[index]['status'] == 2 ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(_items[index]['description']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editItem(index),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteItem(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Todo App'),
        centerTitle: true,
        backgroundColor: Colors.lime,
        actions: [
          if (_hasError)
            IconButton(
              icon: Icon(Icons.error, color: Colors.red),
              onPressed: () {
                _showErrorDialog(
                  'Database Error Details',
                  _errorMessage,
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDatabase,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(8),
        child: _buildContent(),
      ),
      floatingActionButton: _hasError ? null : FloatingActionButton(
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: _addItem,
      ),
    );
  }
}