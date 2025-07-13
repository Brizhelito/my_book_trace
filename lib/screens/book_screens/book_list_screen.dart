import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:MyBookTrace/constants/app_constants.dart';
import 'package:MyBookTrace/models/book.dart';
import 'package:MyBookTrace/providers/book_provider.dart';
import 'package:provider/provider.dart';

/// Pantalla que muestra la lista de libros del usuario
class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _showFilters = false;
  
  // Controladores para filtros
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _publisherController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  final TextEditingController _yearStartController = TextEditingController();
  final TextEditingController _yearEndController = TextEditingController();
  
  // Opciones de ordenación
  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'title', 'text': 'Título', 'icon': Icons.sort_by_alpha},
    {'value': 'author', 'text': 'Autor', 'icon': Icons.person},
    {'value': 'added', 'text': 'Fecha de adición', 'icon': Icons.calendar_today},
    {'value': 'updated', 'text': 'Última actualización', 'icon': Icons.update},
    {'value': 'rating', 'text': 'Calificación', 'icon': Icons.star},
    {'value': 'pages', 'text': 'Número de páginas', 'icon': Icons.book},
    {'value': 'year', 'text': 'Año de publicación', 'icon': Icons.date_range},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Inicializar el provider de libros
    Future.microtask(() {
      debugPrint('BookListScreen: Cargando libros al iniciar la pantalla');
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.loadBooks();
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Forzar la recarga de libros cuando la pantalla vuelve a ser visible
    debugPrint('BookListScreen: didChangeDependencies llamado - Recargando libros');
    Future.microtask(() {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      bookProvider.loadBooks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _genreController.dispose();
    _publisherController.dispose();
    _languageController.dispose();
    _yearStartController.dispose();
    _yearEndController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar libros...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                // Actualizar la búsqueda
                Provider.of<BookProvider>(context, listen: false).searchBooks(value);
              },
            )
          : const Text('Mi Biblioteca'),
        actions: [
          // Botón de búsqueda
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  // Recargar todos los libros
                  Provider.of<BookProvider>(context, listen: false).loadBooks();
                }
              });
            },
          ),
          // Botón de filtros
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          // Botón para limpiar filtros
          if (_hasActiveFilters())
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Limpiar filtros',
              onPressed: () {
                _clearAllFilters();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Leyendo'),
            Tab(text: 'Completados'),
            Tab(text: 'Pendientes'),
          ],
          onTap: (index) {
            final bookProvider = Provider.of<BookProvider>(context, listen: false);
            switch (index) {
              case 0:
                bookProvider.setFilter('all');
                break;
              case 1:
                bookProvider.setFilter(Book.statusInProgress);
                break;
              case 2:
                bookProvider.setFilter(Book.statusCompleted);
                break;
              case 3:
                bookProvider.setFilter(Book.statusNotStarted);
                break;
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Panel de filtros avanzados
          if (_showFilters) _buildAdvancedFiltersPanel(),
          
          // Lista de libros con pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Todos los libros
                _buildBookGrid('all'),
                // Libros en progreso
                _buildBookGrid(Book.statusInProgress),
                // Libros completados
                _buildBookGrid(Book.statusCompleted),
                // Libros pendientes
                _buildBookGrid(Book.statusNotStarted),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'book_list_fab',
        onPressed: () => context.push(AppRoutes.addBook),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Verifica si hay filtros activos
  bool _hasActiveFilters() {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    return bookProvider.filterGenre != null || 
           bookProvider.filterLanguage != null || 
           bookProvider.filterPublisher != null || 
           bookProvider.filterYearStart != null || 
           bookProvider.filterYearEnd != null || 
           bookProvider.sortBy != 'title' || 
           !bookProvider.sortAscending || 
           bookProvider.searchQuery.isNotEmpty;
  }
  
  // Limpia todos los filtros
  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _genreController.clear();
      _publisherController.clear();
      _languageController.clear();
      _yearStartController.clear();
      _yearEndController.clear();
      _isSearching = false;
    });
    
    // Restablecer filtros en el provider
    Provider.of<BookProvider>(context, listen: false).clearFilters();
  }
  
  // Construye el panel de filtros avanzados
  Widget _buildAdvancedFiltersPanel() {
    final bookProvider = Provider.of<BookProvider>(context, listen: false);
    
    // Inicializar controladores con valores actuales si existen
    if (_genreController.text.isEmpty && bookProvider.filterGenre != null) {
      _genreController.text = bookProvider.filterGenre!;
    }
    if (_publisherController.text.isEmpty && bookProvider.filterPublisher != null) {
      _publisherController.text = bookProvider.filterPublisher!;
    }
    if (_languageController.text.isEmpty && bookProvider.filterLanguage != null) {
      _languageController.text = bookProvider.filterLanguage!;
    }
    if (_yearStartController.text.isEmpty && bookProvider.filterYearStart != null) {
      _yearStartController.text = bookProvider.filterYearStart!.toString();
    }
    if (_yearEndController.text.isEmpty && bookProvider.filterYearEnd != null) {
      _yearEndController.text = bookProvider.filterYearEnd!.toString();
    }
    
    String currentSortOption = bookProvider.sortBy;
    bool isAscending = bookProvider.sortAscending;
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del panel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filtros avanzados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton.icon(
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Restablecer'),
                  onPressed: _clearAllFilters,
                ),
              ],
            ),
            const Divider(),
            
            // Filtros por género, editorial e idioma
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                // Filtro por género
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _genreController,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      bookProvider.setGenreFilter(value.isNotEmpty ? value : null);
                    },
                  ),
                ),
                
                // Filtro por editorial
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _publisherController,
                    decoration: const InputDecoration(
                      labelText: 'Editorial',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      bookProvider.setPublisherFilter(value.isNotEmpty ? value : null);
                    },
                  ),
                ),
                
                // Filtro por idioma
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _languageController,
                    decoration: const InputDecoration(
                      labelText: 'Idioma',
                      prefixIcon: Icon(Icons.language),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      bookProvider.setLanguageFilter(value.isNotEmpty ? value : null);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Filtros por año
            Row(
              children: [
                const Text('Año: ', style: TextStyle(fontWeight: FontWeight.bold)),
                // Año inicial
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _yearStartController,
                    decoration: const InputDecoration(
                      labelText: 'Desde',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      int? yearStart;
                      if (value.isNotEmpty) {
                        yearStart = int.tryParse(value);
                      }
                      int? yearEnd;
                      if (_yearEndController.text.isNotEmpty) {
                        yearEnd = int.tryParse(_yearEndController.text);
                      }
                      bookProvider.setYearFilter(yearStart, yearEnd);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Año final
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _yearEndController,
                    decoration: const InputDecoration(
                      labelText: 'Hasta',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      int? yearEnd;
                      if (value.isNotEmpty) {
                        yearEnd = int.tryParse(value);
                      }
                      int? yearStart;
                      if (_yearStartController.text.isNotEmpty) {
                        yearStart = int.tryParse(_yearStartController.text);
                      }
                      bookProvider.setYearFilter(yearStart, yearEnd);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Opciones de ordenación
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                // Opciones de ordenación
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _sortOptions.map((option) {
                    final bool isSelected = currentSortOption == option['value'];
                    return FilterChip(
                      selected: isSelected,
                      label: Text(option['text'] as String),
                      avatar: Icon(option['icon'] as IconData, size: 18),
                      onSelected: (selected) {
                        if (selected) {
                          bookProvider.setSorting(option['value'] as String, isAscending);
                          setState(() {});
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                // Dirección de ordenación
                Row(
                  children: [
                    const Text('Dirección:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      selected: isAscending,
                      label: const Text('Ascendente'),
                      avatar: const Icon(Icons.arrow_upward, size: 18),
                      onSelected: (selected) {
                        if (selected) {
                          bookProvider.setSorting(currentSortOption, true);
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      selected: !isAscending,
                      label: const Text('Descendente'),
                      avatar: const Icon(Icons.arrow_downward, size: 18),
                      onSelected: (selected) {
                        if (selected) {
                          bookProvider.setSorting(currentSortOption, false);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookGrid(String filter) {
    return Consumer<BookProvider>(
      builder: (context, bookProvider, child) {
        final books = filter == 'all'
            ? bookProvider.books
            : bookProvider.books.where((book) => book.status == filter).toList();
        
        if (books.isEmpty) {
          return const Center(
            child: Text('No hay libros en esta categoría'),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return _buildBookItem(book);
          },
        );
      },
    );
  }

  Widget _buildBookItem(Book book) {
    // Asegurar que el widget tiene una clave única para evitar conflictos de Hero
    final String bookKey = book.id ?? UniqueKey().toString();
    
    return GestureDetector(
      key: ValueKey(bookKey),  // Usar una clave única
      onTap: () {
        if (book.id != null) {
          // Usar push normal para permitir volver atrás correctamente
          context.push(AppRoutes.bookDetailPath(book.id!));
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portada del libro
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
                image: book.coverImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(book.coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: book.coverImageUrl == null
                  ? Center(
                      child: Icon(
                        Icons.book,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          // Título del libro
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          // Autor del libro
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
