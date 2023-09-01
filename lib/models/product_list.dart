import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/exceptions/http_exception.dart';
import 'package:shop/models/product.dart';
import 'package:shop/utils/constants.dart';

class ProductList with ChangeNotifier {
  final String _token;
  final String _userId;
  List<Product> _items = [];

  List<Product> get items => [..._items];
  List<Product> get favoriteItems =>
      _items.where((prod) => prod.isFavorite).toList();

  ProductList([
    this._token = '',
    this._userId = '',
    this._items = const [],
  ]);

  int get itemsCount {
    return _items.length;
  }

  Future<void> addProduct(Product product) async {
    final respostaServer = await http.post(
      Uri.parse(
          '${Constants.PRODUCT_BASE_URL}.json?auth=$_token'), // .JSON REQUERIDO PELO FIREBASE NA HORA DA CRIACAO
      body: jsonEncode(
        {
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
        },
      ),
    );

    final id = jsonDecode(respostaServer.body)['name'];
    _items.add(Product(
      id: id,
      name: product.name,
      description: product.description,
      price: product.price,
      imageUrl: product.imageUrl,
    ));
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    // p DE PRODUTO
    int index = _items.indexWhere((p) => p.id == product.id);

    if (index >= 0) {
      await http.patch(
        Uri.parse(
            '${Constants.PRODUCT_BASE_URL}/${product.id}.json?auth=$_token'), // .JSON REQUERIDO PELO FIREBASE NA HORA DA CRIACAO
        body: jsonEncode(
          {
            'name': product.name,
            'description': product.description,
            'price': product.price,
            'imageUrl': product.imageUrl,
          }, // NAO MANDA A PARTE DE FAVORITO AQUI
        ),
      );
      _items[index] = product;
      notifyListeners();
    }
  }

  Future<void> removeProduct(Product product) async {
    // p DE PRODUTO
    int index = _items.indexWhere((p) => p.id == product.id);

    if (index >= 0) {
      // AQUI ELE CHECA SE O PRODUTO PERTENCE A LISTA
      final product = _items[index];
      _items.remove(product);
      notifyListeners();

      final resposta = await http.delete(
        Uri.parse(
            '${Constants.PRODUCT_BASE_URL}/${product.id}.json?auth=$_token'),
      );

      if (resposta.statusCode >= 400) {
        _items.insert(index, product);
        notifyListeners();
        throw HttpException(
          msg: 'Nao foi possivel excluir o produto',
          statusCode: resposta.statusCode,
        );
      }
    }
  }

  Future<void> loadProducts() async {
    _items.clear();
    final resposta = await http
        .get(Uri.parse('${Constants.PRODUCT_BASE_URL}.json?auth=$_token'));
    if (resposta.body == 'null') return;

    final respostaFavorita = await http.get(
        Uri.parse(
            '${Constants.USERS_FAVORITES_URL}/$_userId.json?auth=$_token'), // .JSON REQUERIDO PELO FIREBASE NA HORA DA CRIACAO
      );

    Map<String, dynamic> favData = respostaFavorita.body == 'null' ? {} : jsonDecode(respostaFavorita.body);


    Map<String, dynamic> data = jsonDecode(resposta.body);
    data.forEach((productId, productData) {
      final isFavorite = favData[productId] ?? false;
      _items.add(
        Product(
          id: productId,
          name: productData['name'],
          description: productData['description'],
          price: productData['price'],
          imageUrl: productData['imageUrl'],
          isFavorite: isFavorite,
        ),
      );
    });
    notifyListeners();
  }

  Future<void> saveProduct(Map<String, Object> data) {
    bool hasId = data['id'] != null;

    final product = Product(
      id: hasId ? data['id'] as String : Random().nextDouble().toString(),
      name: data['name'] as String,
      description: data['description'] as String,
      price: data['price'] as double,
      imageUrl: data['imageUrl'] as String,
    );

    if (hasId) {
      return updateProduct(product);
    } else {
      return addProduct(product);
    }

    // notifyListeners();    NAO PRECISA DELE MAIS AQUI POIS O PROPRIO addProduct CHAMA O NOTIFYLISTENERS
  }
}

// bool _showFavoritesOnly = false;

//   List<Product> get items {
//     if(_showFavoritesOnly){
//       return _items.where((prod) => prod.isFavorite).toList();
//     }
//     return [..._items];
//   } 

//   void showFavoritesOnly(){
//     _showFavoritesOnly = true;
//     notifyListeners();
//   }
//   void showAll(){
//     _showFavoritesOnly = false;
//     notifyListeners();
//   }