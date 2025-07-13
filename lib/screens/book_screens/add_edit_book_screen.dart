import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:MyBookTrace/models/book.dart';
import 'package:MyBookTrace/providers/book_provider.dart';
import 'package:MyBookTrace/screens/book_screens/barcode_scanner_screen.dart';
import 'package:MyBookTrace/services/book_api_service.dart';

/// Pantalla para añadir o editar un libro
class AddEditBookScreen extends StatefulWidget {
  final String? bookId;

  const AddEditBookScreen({this.bookId, super.key});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _pageCountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _publisherController = TextEditingController();
  final _publicationYearController = TextEditingController();
  final _genreController = TextEditingController();
  final _languageController = TextEditingController();

  String _selectedStatus = Book.statusNotStarted;
  double _rating = 0;
  bool _isLoading = false;
  bool _isLoadingIsbn = false;
  bool _isEditing = false;
  Book? _originalBook;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.bookId != null;

    // Cargar datos del libro si estamos editando
    if (_isEditing) {
      _loadBookData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _coverUrlController.dispose();
    _pageCountController.dispose();
    _descriptionController.dispose();
    _publisherController.dispose();
    _publicationYearController.dispose();
    _genreController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  // Cargar datos del libro para editar
  Future<void> _loadBookData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      await bookProvider.selectBook(widget.bookId!);
      _originalBook = bookProvider.selectedBook;

      if (_originalBook != null) {
        _titleController.text = _originalBook!.title;
        _authorController.text = _originalBook!.author;
        _isbnController.text = _originalBook!.isbn ?? '';
        _coverUrlController.text = _originalBook!.coverImageUrl ?? '';
        _pageCountController.text = _originalBook!.pageCount?.toString() ?? '';
        _descriptionController.text = _originalBook!.description ?? '';
        _publisherController.text = _originalBook!.publisher ?? '';
        _publicationYearController.text =
            _originalBook!.publicationYear?.toString() ?? '';
        _genreController.text = _originalBook!.genre ?? '';
        _languageController.text = _originalBook!.language ?? '';

        setState(() {
          _selectedStatus = _originalBook!.status;
          _rating = _originalBook!.rating ?? 0;
        });
      }
    } catch (e) {
      // Mostrar error - verificar si aún está montado el widget
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el libro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Función para escanear el código de barras ISBN
  Future<void> _scanBarcode() async {
    setState(() {
      _isLoadingIsbn = true;
    });

    try {
      // Navegamos a la pantalla de escaneo
      final barcodeScanRes = await Navigator.of(context).push<String?>(
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );

      if (barcodeScanRes != null) {
        _isbnController.text = barcodeScanRes;
        await _fetchBookInfoByIsbn(barcodeScanRes);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al escanear el código'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingIsbn = false;
      });
    }
  }

  // Buscar información del libro por ISBN
  Future<void> _fetchBookInfoByIsbn(String isbn) async {
    try {
      setState(() {
        _isLoadingIsbn = true;
      });

      // Consultar la API de Google Books
      final bookData = await BookApiService.fetchBookByIsbn(isbn);

      if (bookData != null) {
        // Completar los campos del formulario con los datos obtenidos
        _titleController.text = bookData['title'] ?? '';
        _authorController.text = bookData['author'] ?? '';
        _coverUrlController.text = bookData['coverImageUrl'] ?? '';
        _pageCountController.text = bookData['pageCount']?.toString() ?? '';
        _descriptionController.text = bookData['description'] ?? '';
        _publisherController.text = bookData['publisher'] ?? '';
        _publicationYearController.text =
            bookData['publicationYear']?.toString() ?? '';
        _genreController.text = bookData['genre'] ?? '';
        _languageController.text = bookData['language'] ?? '';

        // Mostrar mensaje de éxito
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Información del libro obtenida correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // No se encontró información para el ISBN
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se encontró información para el ISBN: $isbn'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar información del libro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingIsbn = false;
      });
    }
  }

  /// Guardar el libro
  void _saveBook() async {
    // Validar el formulario
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        debugPrint('AddEditBookScreen: Iniciando guardado de libro...');
        
        // Recopilar datos del libro
        final bookData = Book(
          id: _isEditing ? _originalBook!.id : null,
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          isbn: _isbnController.text.isEmpty
              ? null
              : _isbnController.text.trim(),
          coverImageUrl: _coverUrlController.text.isEmpty
              ? null
              : _coverUrlController.text.trim(),
          pageCount: _pageCountController.text.isEmpty
              ? null
              : int.parse(_pageCountController.text),
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text.trim(),
          publisher: _publisherController.text.isEmpty
              ? null
              : _publisherController.text.trim(),
          publicationYear: _publicationYearController.text.isEmpty
              ? null
              : int.parse(_publicationYearController.text),
          genre: _genreController.text.isEmpty
              ? null
              : _genreController.text.trim(),
          language: _languageController.text.isEmpty
              ? null
              : _languageController.text.trim(),
          status: _selectedStatus,
          rating: _rating == 0 ? null : _rating,
          // Preservar las fechas si estamos editando
          startDate: _isEditing ? _originalBook!.startDate : null,
          finishDate: _isEditing ? _originalBook!.finishDate : null,
          createdAt: _isEditing ? _originalBook!.createdAt : DateTime.now(),
          updatedAt: DateTime.now(),
        );

        debugPrint('AddEditBookScreen: Datos del libro preparados: ${bookData.title}');
        final bookProvider = Provider.of<BookProvider>(context, listen: false);

        String? bookId;
        if (_isEditing) {
          debugPrint('AddEditBookScreen: Actualizando libro existente con ID: ${bookData.id}');
          final success = await bookProvider.updateBook(bookData);
          debugPrint('AddEditBookScreen: Resultado de actualización: $success');
          bookId = bookData.id;
        } else {
          debugPrint('AddEditBookScreen: Añadiendo nuevo libro');
          bookId = await bookProvider.addBook(bookData);
          debugPrint('AddEditBookScreen: Libro añadido con ID: $bookId');
        }
        
        // Forzar recarga de libros para garantizar que se muestre el libro guardado
        debugPrint('AddEditBookScreen: Recargando lista de libros');
        await bookProvider.loadBooks();

        if (mounted) {
          // Verificar que el libro se guardó correctamente
          final bool encontrado = bookId != null && bookProvider.books.any((b) => b.id == bookId);
          debugPrint('AddEditBookScreen: Verificación - ¿Libro encontrado en lista actualizada?: $encontrado');
          
          // Mostrar mensaje de éxito o error según corresponda
          if (encontrado) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEditing
                      ? 'Libro actualizado correctamente'
                      : 'Libro añadido correctamente',
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Asegurar que se completa la carga de libros antes de navegar
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              debugPrint('AddEditBookScreen: Navegando de vuelta a la biblioteca');
              // Volver a la pantalla de biblioteca
              context.go('/books');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: El libro no aparece en la biblioteca después de guardar'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('AddEditBookScreen: ERROR al guardar el libro: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar el libro: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      debugPrint('AddEditBookScreen: El formulario no es válido, no se guarda el libro');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar libro' : 'Añadir libro')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título del libro
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        hintText: 'Ingresa el título del libro',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa el título del libro';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Autor del libro
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Autor *',
                        hintText: 'Ingresa el autor del libro',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa el autor del libro';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ISBN con botón de escaneo
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _isbnController,
                            decoration: const InputDecoration(
                              labelText: 'ISBN',
                              hintText: 'ISBN del libro (opcional)',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _isLoadingIsbn ? null : _scanBarcode,
                          icon: _isLoadingIsbn
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.qr_code_scanner),
                          tooltip: 'Escanear ISBN',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // URL de la portada
                    TextFormField(
                      controller: _coverUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL de la portada',
                        hintText: 'URL de la imagen de portada (opcional)',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vista previa de la portada
                    if (_coverUrlController.text.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _coverUrlController.text,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return const Center(
                                child: Text('Error al cargar la imagen'),
                              );
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Número de páginas
                    TextFormField(
                      controller: _pageCountController,
                      decoration: const InputDecoration(
                        labelText: 'Número de páginas *',
                        hintText: 'Ejemplo: 300',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El número de páginas es obligatorio';
                        }
                        final pageCount = int.tryParse(value.trim());
                        if (pageCount == null) {
                          return 'Ingresa un número válido';
                        }
                        if (pageCount < 1) {
                          return 'El número de páginas debe ser mayor a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Estado de lectura
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Estado de lectura *',
                      ),
                      items: [
                        DropdownMenuItem(
                          value: Book.statusNotStarted,
                          child: const Text('No iniciado'),
                        ),
                        DropdownMenuItem(
                          value: Book.statusInProgress,
                          child: const Text('En progreso'),
                        ),
                        DropdownMenuItem(
                          value: Book.statusCompleted,
                          child: const Text('Completado'),
                        ),
                        DropdownMenuItem(
                          value: Book.statusAbandoned,
                          child: const Text('Abandonado'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Calificación
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Calificación'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rating = index + 1;
                                  });
                                },
                                child: Icon(
                                  index < _rating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 32,
                                ),
                              );
                            }),
                            const SizedBox(width: 16),
                            if (_rating > 0)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rating = 0;
                                  });
                                },
                                child: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Descripción del libro (opcional)',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Detalles adicionales
                    ExpansionTile(
                      title: const Text('Detalles adicionales'),
                      children: [
                        // Editorial
                        TextFormField(
                          controller: _publisherController,
                          decoration: const InputDecoration(
                            labelText: 'Editorial',
                            hintText: 'Editorial (opcional)',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Año de publicación
                        TextFormField(
                          controller: _publicationYearController,
                          decoration: const InputDecoration(
                            labelText: 'Año de publicación',
                            hintText: 'Año de publicación (opcional)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        // Género
                        TextFormField(
                          controller: _genreController,
                          decoration: const InputDecoration(
                            labelText: 'Género',
                            hintText: 'Género literario (opcional)',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Idioma
                        TextFormField(
                          controller: _languageController,
                          decoration: const InputDecoration(
                            labelText: 'Idioma',
                            hintText: 'Idioma del libro (opcional)',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Botón de guardar
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _saveBook,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            _isEditing ? 'Actualizar libro' : 'Guardar libro',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
