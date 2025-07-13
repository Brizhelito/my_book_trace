import 'package:flutter/material.dart';
import 'package:MyBookTrace/models/book.dart';
import 'package:MyBookTrace/constants/app_constants.dart';
import 'package:go_router/go_router.dart';

/// Widget que muestra los libros favoritos del usuario
class FavoriteBooksCard extends StatelessWidget {
  final List<Book> favoriteBooks;

  const FavoriteBooksCard({
    super.key,
    required this.favoriteBooks,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay datos, mostrar mensaje
    if (favoriteBooks.isEmpty) {
      return _buildEmptyCard();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Libros Favoritos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Basado en tu tiempo de lectura',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista de libros favoritos
            ...favoriteBooks.map((book) => _buildBookItem(context, book)),
          ],
        ),
      ),
    );
  }

  /// Construye un widget vacío cuando no hay datos
  Widget _buildEmptyCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Libros Favoritos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Center(
              heightFactor: 3,
              child: Text(
                'Registra más sesiones de lectura para ver tus favoritos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un elemento de libro favorito
  Widget _buildBookItem(BuildContext context, Book book) {
    return InkWell(
      onTap: () {
        if (book.id != null) {
          context.push(AppRoutes.bookDetailPath(book.id!));
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada del libro
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: book.coverImageUrl != null && book.coverImageUrl!.isNotEmpty
                  ? Image.network(
                      book.coverImageUrl!,
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildCoverPlaceholder(),
                    )
                  : _buildCoverPlaceholder(),
            ),
            const SizedBox(width: 12),
            
            // Información del libro
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (book.genre != null && book.genre!.isNotEmpty)
                    Text(
                      book.genre!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            
            // Icono para indicar que es un favorito
            const Icon(
              Icons.favorite,
              color: Colors.redAccent,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un placeholder para la portada
  Widget _buildCoverPlaceholder() {
    return Container(
      width: 60,
      height: 90,
      color: Colors.grey[300],
      child: const Icon(
        Icons.book,
        color: Colors.grey,
      ),
    );
  }
}
