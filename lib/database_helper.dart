import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'ferreteria_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create tables here
    await db.execute('''
      CREATE TABLE clients (
        codigo PRIMARY KEY,
        nombre TEXT,
        direccion TEXT,
        telefono TEXT
      )
    ''');

    await db.execute('''
    CREATE TABLE pedidos (
      pedidoCodigo INTEGER PRIMARY KEY AUTOINCREMENT,
      pedidoDescripcion TEXT,
      pedidoFecha TEXT,
      cliente_id INTEGER,
      FOREIGN KEY (cliente_id) REFERENCES clients (codigo)
    )
  ''');

    await db.execute('''
    CREATE TABLE productos (
      codigo INTEGER PRIMARY KEY AUTOINCREMENT,
      fabricante TEXT,
      valor REAL
    )
  ''');

    await db.execute('''
    CREATE TABLE facturas (
      facturaCodigo INTEGER PRIMARY KEY AUTOINCREMENT,
      facturaFecha TEXT,
      facturaValor REAL,
      pedido_id INTEGER,
      FOREIGN KEY (pedido_id) REFERENCES pedidos (pedidoCodigo)
    )
  ''');

    await db.execute('''
    CREATE TABLE pedidoDetails (
      pedidoCodigo INTEGER PRIMARY KEY AUTOINCREMENT,
      pedidoDescripcion TEXT,
      pedidoFecha TEXT,
      facturaCodigo INTEGER,
      facturaFecha TEXT,
      facturaValor REAL,
      pedido_id INTEGER,
      FOREIGN KEY (pedido_id) REFERENCES pedidos (pedidoCodigo)
    )
  ''');
  }

  Future<int> insertClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }

  Future<List<Client>> getAllClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clients');
    return List.generate(maps.length, (i) {
      return Client(
        codigo: maps[i]['codigo'],
        nombre: maps[i]['nombre'],
        direccion: maps[i]['direccion'],
        telefono: maps[i]['telefono'],
      );
    });
  }

  Future<int> delete(int codigo) async {
    final db = await database;
    return await db.delete(
      'clients',
      where: 'codigo = ?',
      whereArgs: [codigo],
    );
  }

  Future<Client?> getClientById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'codigo = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) {
      return null; // No found client
    } else {
      return Client(
        codigo: maps[0]['codigo'],
        nombre: maps[0]['nombre'],
        direccion: maps[0]['direccion'],
        telefono: maps[0]['telefono'],
      );
    }
  }

  Future<void> insertProduct(Producto producto) async {
    final db = await database;

    await db.insert(
      'productos',
      producto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteProduct(int codigo) async {
    final db = await database;
    return await db.delete(
      'productos',
      where: 'codigo = ?',
      whereArgs: [codigo],
    );
  }

  Future<List<Producto>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('productos');
    return List.generate(maps.length, (i) {
      return Producto(
        codigo: maps[i]['codigo'],
        fabricante: maps[i]['fabricante'],
        valor: maps[i]['valor'],
      );
    });
  }

  Future<Producto?> getProductByCode(int codigo) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'productos',
      where: 'codigo = ?',
      whereArgs: [codigo],
    );

    if (maps.isEmpty) {
      return null; // Product no found
    }

    return Producto.fromMap(maps.first);
  }

  Future<void> insertPedidoFraDetails(PedidoDetails pedidoDetails) async {
    final db = await database;
    await db.insert(
      'pedidoDetails',
      pedidoDetails.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PedidoDetails>> getPedidoDetails() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pedidoDetails');
    return List.generate(maps.length, (i) {
      return PedidoDetails(
        pedidoCodigo: maps[i]['pedidoCodigo'],
        pedidoDescripcion: maps[i]['pedidoDescripcion'],
        pedidoFecha: maps[i]['pedidoFecha'],
        facturaCodigo: maps[i]['facturaCodigo'],
        facturaFecha: maps[i]['facturaFecha'],
        facturaValor: maps[i]['facturaValor'],
      );
    });
  }
}

class Client {
  int codigo;
  String nombre;
  String direccion;
  String telefono;

  Client({
    required this.codigo,
    required this.nombre,
    required this.direccion,
    required this.telefono,
  });

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'direccion': direccion,
      'telefono': telefono,
    };
  }
}

class Producto {
  int codigo;
  String fabricante;
  double valor;

  Producto(
      {required this.codigo, required this.fabricante, required this.valor});

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'fabricante': fabricante,
      'valor': valor,
    };
  }

  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      codigo: map['codigo'],
      fabricante: map['fabricante'],
      valor: map['valor'],
    );
  }
}

class PedidoDetails {
  int pedidoCodigo;
  String pedidoDescripcion;
  String pedidoFecha;
  int facturaCodigo;
  String facturaFecha;
  double facturaValor;

  PedidoDetails({
    required this.pedidoCodigo,
    required this.pedidoDescripcion,
    required this.pedidoFecha,
    required this.facturaCodigo,
    required this.facturaFecha,
    required this.facturaValor,
  });

  Map<String, dynamic> toMap() {
    return {
      'pedidoCodigo': pedidoCodigo,
      'pedidoDescripcion': pedidoDescripcion,
      'pedidoFecha': pedidoFecha,
      'facturaCodigo': facturaCodigo,
      'facturaFecha': facturaFecha,
      'facturaValor': facturaValor
    };
  }

  factory PedidoDetails.fromMap(Map<String, dynamic> map) {
    return PedidoDetails(
      pedidoCodigo: map['pedidoCodigo'],
      pedidoDescripcion: map['pedidoDescripcion'],
      pedidoFecha: map['pedidoFecha'],
      facturaCodigo: map['facturaCodigo'],
      facturaFecha: map['facturaFecha'],
      facturaValor: map['facturaValor'],
    );
  }
}
