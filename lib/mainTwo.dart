import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'main.dart';

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
      home: HomePageTwo(),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Principal Screen'),
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

class HomePageTwo extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePageTwo> {
  final TextEditingController _fabricanteController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  Producto? _product;
  // Validation function to check if a string is empty or null
  bool _isFieldEmpty(String value) {
    return value.isEmpty;
  }

  Future<List<Producto>> _getProducts() async {
    final dbHelper = DatabaseHelper.instance;
    return dbHelper.getAllProducts();
  }

  final RegExp _textWithNumberRegex = RegExp(r'[a-zA-Z]');

  Future<void> _addProduct() async {
    final id = int.tryParse(_idController.text.trim());
    final fabricante = _fabricanteController.text.trim();
    final value = double.tryParse(_valueController.text.trim());

    if (id == null || _isFieldEmpty(fabricante) || value == null) {
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
    } else if (!_textWithNumberRegex.hasMatch(fabricante)) {
      // Display an error message for invalid name format
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Validation Error'),
            content: Text('Fabricant name should contain only letters'),
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
    final product = Producto(
      codigo: id!,
      fabricante: fabricante,
      valor: value!,
    );
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.insertProduct(product);
    // Display a success message or handle the successful insertion
    _showSnackBar('Product added successfully');

    // Clear the text fields after successful insertion
    _idController.clear();
    _fabricanteController.clear();
    _valueController.clear();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void deleteProduct(Producto product) async {
    final dbHelper = DatabaseHelper.instance;
    final rowsDeleted = await dbHelper.deleteProduct(product.codigo);
    if (rowsDeleted > 0) {
      // Successfully deleted the client
      print('Product deleted');
    } else {
      // Failed to delete the client
      print('Failed to delete product');
    }
  }

  Future<void> _searchClient() async {
    final id = int.tryParse(_idController.text.trim());
    if (id != null) {
      final dbHelper = DatabaseHelper.instance;
      final product = await dbHelper.getProductByCode(id);
      setState(() {
        _product = product;
      });
      _showClientDetailsDialog(product);
    }
  }

  void _showClientDetailsDialog(Producto? _product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Product Details'),
          content: _product != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text('ID: ${_product.codigo}'),
                    Text('Fabricant: ${_product.fabricante}'),
                    Text('Value: ${_product.valor}'),
                  ],
                )
              : Text('Product not found.'),
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
            Text('Create and Search Products'),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'ID Number'),
            ),
            TextField(
              controller: _fabricanteController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(labelText: 'Fabricant'),
            ),
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(labelText: 'Value'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            ElevatedButton(
              onPressed: _addProduct,
              child: Text('Add Product'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            ElevatedButton(
              onPressed: _searchClient,
              child: Text('Search Product'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            Text('Listing Products'),
            FutureBuilder<List<Producto>>(
              future: _getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error saving: ${snapshot.error}');
                } else {
                  final products = snapshot.data ?? [];
                  return Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListTile(
                          title: Text(product.fabricante),
                          subtitle: Text(product.codigo.toString()),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              deleteProduct(product);
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
                // Navegar a la segunda ventana cuando se presiona el botón
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
//////////////////////////////////////////////

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreen createState() => _SecondScreen();
}

class _SecondScreen extends State<SecondScreen> {
  PedidoDetails? _pedidoDetails;
  // final RegExp _textWithNumberRegex = RegExp(r'[a-zA-Z]');
  Future<List<PedidoDetails>> _loadPedidoDetails() async {
    final dbHelper = DatabaseHelper.instance;
    return dbHelper.getPedidoDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ferretería rodamientos y fierros'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            Text('Listing Bills Section'),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            ElevatedButton(
              onPressed: () {
                // Volver a la pantalla principal cuando se presiona el botón
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => HomePage(),
                ));
              },
              child: Text('Go to Clients Section'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            ElevatedButton(
              onPressed: () {
                // Volver a la pantalla principal cuando se presiona el botón
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => HomePageTwo(),
                ));
              },
              child: Text('Go to Products Section'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            ElevatedButton(
              onPressed: () {
                // Volver a la pantalla principal cuando se presiona el botón
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ));
              },
              child: Text('Login'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            ElevatedButton(
              //ADD PRODUCT WITHOUT INTERFACE JUST BUTTON
              onPressed: () async {
                final newOrder = PedidoDetails(
                  pedidoCodigo: 103,
                  pedidoDescripcion: 'Settings for car',
                  pedidoFecha: '2023/06/22',
                  facturaCodigo: 1000,
                  facturaFecha: '2023/06/25',
                  facturaValor: 50040.089,
                );
                final dbHelper = DatabaseHelper.instance;
                await dbHelper.insertPedidoFraDetails(newOrder);
                _showOrderDetails(context, newOrder);
                _showSnackBar(context, 'Order added successfully');
              },
              child: Text('Add order'),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            Text('Listing orders'),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
            FutureBuilder<List<PedidoDetails>>(
              future: _loadPedidoDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error saving: ${snapshot.error}');
                } else {
                  final _pedidoDetails = snapshot.data ?? [];
                  return Expanded(
                    child: ListView.builder(
                      itemCount: _pedidoDetails.length,
                      itemBuilder: (BuildContext context, int index) {
                        final pedidoDetails = _pedidoDetails[index];
                        return ListTile(
                          title: Text(pedidoDetails.pedidoCodigo.toString()),
                          subtitle: Text(
                              'Description: ${pedidoDetails.pedidoDescripcion}\n'
                              'Order Date: ${pedidoDetails.pedidoFecha}\n'
                              'Invoice ${pedidoDetails.facturaCodigo}\n'
                              'Invoice Date: ${pedidoDetails.facturaFecha}\n'
                              'Price: ${pedidoDetails.facturaValor}'),
                        );
                      },
                    ),
                  );
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
            ),
          ],
        ),
      ),
    );
  }
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2),
    ),
  );
}

void _showOrderDetails(BuildContext context, PedidoDetails? _Odetails) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Order and invoice Details'),
        content: _Odetails != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Invoice: ${_Odetails.facturaCodigo}'),
                  Text('Invoice Date: ${_Odetails.facturaFecha}'),
                  Text('Order: ${_Odetails.pedidoCodigo}'),
                  Text('Order Date: ${_Odetails.pedidoFecha}'),
                  Text('Price: ${_Odetails.facturaValor}'),
                  Text('Description: ${_Odetails.pedidoDescripcion}'),
                ],
              )
            : Text('Order and invoice not found.'),
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

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreen createState() => _LoginScreen();
}

class _LoginScreen extends State<LoginScreen> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  bool _isInputValid() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    return username.isNotEmpty && password.isNotEmpty;
  }

  void _login() {
    if (_isInputValid()) {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // Simule la autenticación (reemplace esto con una llamada al servidor o base de datos real)
      if (username == 'Fernanda' && password == '1230.') {
        // Credenciales válidas, permitir el acceso o navegar a la siguiente pantalla
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // Credenciales inválidas, mostrar mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Incorrect credentials. Try again'),
          ),
        );
      }
    } else {
      // Campos vacíos, mostrar mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill out the fields.'),
        ),
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Ferretería rodamientos y fierros Login System'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                  ),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(labelText: 'Username'),
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText:
                        true, // Para ocultar la contraseña mientras se escribe
                    decoration: InputDecoration(labelText: 'Password'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(30.0),
                  ),
                  ElevatedButton(
                    onPressed: _login,
                    child: Text('Log In'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(60.0),
                  ),
                  Text('Principal Menu'),
                  Padding(
                    padding: const EdgeInsets.all(30.0),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Volver a la pantalla principal cuando se presiona el botón
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => HomePage(),
                      ));
                    },
                    child: Text('Go to Clients Section'),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                  ),
                ])));
  }
}
