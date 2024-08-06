import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'mainTwo.dart';

void main() async {
  sqfliteFfiInit();
  // Change the default factory. On iOS/Android, if not using `sqlite_flutter_lib` you can forget
  // this step, it will use the sqlite version available on the system.
  databaseFactory = databaseFactoryFfi;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pantalla Principal'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  Client? _client;

  // Validation function to check if a string is empty or null
  bool _isFieldEmpty(String value) {
    return value.isEmpty;
  }

  Future<List<Client>> _getClients() async {
    final dbHelper = DatabaseHelper.instance;
    return dbHelper.getAllClients();
  }

  final RegExp _textWithNumberRegex = RegExp(r'[a-zA-Z]');

  Future<void> _addClient() async {
    final id = int.tryParse(_idController.text.trim());
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();

    if (id == null ||
        _isFieldEmpty(name) ||
        _isFieldEmpty(address) ||
        _isFieldEmpty(phoneNumber)) {
      // Display an error message or handle validation error as needed
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Validation Error'),
            content: Text('Please fill in all fields.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else if (!_textWithNumberRegex.hasMatch(name)) {
      // Display an error message for invalid name format
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Validation Error'),
            content: Text('Name should contain only letters'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }

    // All fields are valid, add the client to the database
    final client = Client(
      codigo: id!,
      nombre: name,
      direccion: address,
      telefono: phoneNumber,
    );
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.insertClient(client);
    // Display a success message or handle the successful insertion
    _showSnackBar('Client added successfully');

    // Clear the text fields after successful insertion
    _idController.clear();
    _nameController.clear();
    _addressController.clear();
    _phoneNumberController.clear();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void deleteClient(Client client) async {
    final dbHelper = DatabaseHelper.instance;
    final rowsDeleted = await dbHelper.delete(client.codigo);
    if (rowsDeleted > 0) {
      // Successfully deleted the client
      print('Client deleted');
    } else {
      // Failed to delete the client
      print('Failed to delete client');
    }
  }

  Future<void> _searchClient() async {
    final id = int.tryParse(_idController.text.trim());
    if (id != null) {
      final dbHelper = DatabaseHelper.instance;
      final client = await dbHelper.getClientById(id);
      setState(() {
        _client = client;
      });
      _showClientDetailsDialog(client);
    }
  }

  void _showClientDetailsDialog(Client? _client) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Client Details'),
          content: _client != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('ID: ${_client.codigo}'),
                    Text('Name: ${_client.nombre}'),
                    Text('Address: ${_client.direccion}'),
                    Text('Phone Number: ${_client.telefono}'),
                  ],
                )
              : Text('Client not found.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ferretería rodamientos y fierros'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create and Search Clients'),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'ID Number'),
            ),
            TextField(
              controller: _nameController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _addressController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            ElevatedButton(
              onPressed: _addClient,
              child: Text('Add Client'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            ElevatedButton(
              onPressed: _searchClient,
              child: Text('Search Client'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            Text('Listing Clients'),
            FutureBuilder<List<Client>>(
              future: _getClients(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error saving: ${snapshot.error}');
                } else {
                  final clients = snapshot.data ?? [];
                  return Expanded(
                    child: ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        return ListTile(
                          title: Text(client.nombre),
                          subtitle: Text(client.codigo.toString()),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              deleteClient(client);
                            },
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => HomePageTwo(),
                  ),
                );
              },
              child: Text('Go to Products Section'),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SecondScreen(),
                  ),
                );
              },
              child: Text('Go to Bills Section'),
            ),
          ],
        ),
      ),
    );
  }
}
