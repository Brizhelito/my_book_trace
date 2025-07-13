import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/logger_service.dart';

/// Servicio para consultar APIs externas de libros
class BookApiService {
  /// URL base de la API de Google Books
  static const String _googleBooksBaseUrl =
      'https://www.googleapis.com/books/v1/volumes';

  /// Buscar información de un libro por ISBN
  static Future<Map<String, dynamic>?> fetchBookByIsbn(String isbn) async {
    // Limpiar el ISBN de cualquier carácter que no sea número
    final cleanIsbn = isbn.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanIsbn.isEmpty) {
      return null;
    }

    try {
      // Consultar la API de Google Books
      final response = await http.get(
        Uri.parse('$_googleBooksBaseUrl?q=isbn:$cleanIsbn'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Verificar si se encontró algún libro
        if (data['totalItems'] > 0) {
          final bookData = data['items'][0]['volumeInfo'];
          return _formatBookData(bookData, cleanIsbn);
        }
      }
      
      // No se encontró ningún libro o hubo un error
      return null;
    } catch (e) {
      logger.error('Error al consultar la API de Google Books', error: e, tag: 'BookApiService');
      return null;
    }
  }

  /// Dar formato a los datos del libro obtenidos de la API
  static Map<String, dynamic> _formatBookData(
      Map<String, dynamic> bookData, String isbn) {
    // Extraer el año de publicación de la fecha completa
    int? publicationYear;
    if (bookData['publishedDate'] != null) {
      final dateStr = bookData['publishedDate'] as String;
      // La fecha puede venir en formatos como: "2022", "2022-01" o "2022-01-15"
      publicationYear = int.tryParse(dateStr.split('-')[0]);
    }

    // Obtener la URL de la portada (puede ser null)
    String? coverUrl;
    if (bookData['imageLinks'] != null) {
      coverUrl = bookData['imageLinks']['thumbnail'] as String?;
      // Convertir http a https para evitar problemas de seguridad
      if (coverUrl != null && coverUrl.startsWith('http:')) {
        coverUrl = coverUrl.replaceFirst('http:', 'https:');
      }
    }

    // Crear un mapa con los datos del libro
    return {
      'title': bookData['title'],
      'author': bookData['authors']?.join(', ') ?? 'Desconocido',
      'isbn': isbn,
      'coverImageUrl': coverUrl,
      'pageCount': bookData['pageCount'],
      'description': bookData['description'],
      'publisher': bookData['publisher'],
      'publicationYear': publicationYear,
      // Obtener el primer género/categoría
      'genre': bookData['categories']?.first,
      'language': bookData['language'],
    };
  }
}
