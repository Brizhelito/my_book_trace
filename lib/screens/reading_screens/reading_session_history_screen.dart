import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:MyBookTrace/models/reading_session.dart';
import 'package:MyBookTrace/models/book.dart';
import 'package:MyBookTrace/providers/reading_session_provider.dart';
import 'package:MyBookTrace/providers/book_provider.dart';

/// Pantalla para mostrar el historial de sesiones de lectura
class ReadingSessionHistoryScreen extends StatefulWidget {
  const ReadingSessionHistoryScreen({super.key});

  @override
  State<ReadingSessionHistoryScreen> createState() =>
      _ReadingSessionHistoryScreenState();
}

class _ReadingSessionHistoryScreenState
    extends State<ReadingSessionHistoryScreen> {
  bool _isLoading = true;
  List<ReadingSession> _allSessions = [];
  List<ReadingSession> _filteredSessions = [];
  List<Book> _books = [];

  // Filtros
  String? _selectedBookId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Cargar sesiones y libros
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessionProvider = Provider.of<ReadingSessionProvider>(
        context,
        listen: false,
      );
      final bookProvider = Provider.of<BookProvider>(context, listen: false);

      await sessionProvider.loadSessions();
      await bookProvider.loadBooks();

      setState(() {
        _allSessions = sessionProvider.sessions;
        _filteredSessions = _allSessions;
        _books = bookProvider.books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar las sesiones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Aplicar filtros a las sesiones
  void _applyFilters() {
    setState(() {
      _filteredSessions = _allSessions.where((session) {
        // Filtrar por libro
        if (_selectedBookId != null && _selectedBookId!.isNotEmpty) {
          if (session.bookId != _selectedBookId) {
            return false;
          }
        }

        // Filtrar por fecha de inicio
        if (_startDate != null) {
          if (session.date.isBefore(_startDate!)) {
            return false;
          }
        }

        // Filtrar por fecha de fin
        if (_endDate != null) {
          // Añadir un día completo para incluir el día final
          final endOfDay = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            23,
            59,
            59,
          );
          if (session.date.isAfter(endOfDay)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  // Resetear todos los filtros
  void _resetFilters() {
    setState(() {
      _selectedBookId = null;
      _startDate = null;
      _endDate = null;
      _filteredSessions = _allSessions;
    });
  }

  // Mostrar diálogo para seleccionar fechas
  Future<void> _showDateRangeDialog() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _applyFilters();
    }
  }

  // Mostrar diálogo para editar una sesión
  Future<void> _showEditSessionDialog(ReadingSession session) async {
    final formKey = GlobalKey<FormState>();
    final startPageController = TextEditingController(
      text: session.startPage.toString(),
    );
    final endPageController = TextEditingController(
      text: session.endPage.toString(),
    );
    final notesController = TextEditingController(text: session.notes);

    final book = _books.firstWhere(
      (b) => b.id == session.bookId,
      orElse: () => Book(id: '', title: 'Libro no encontrado', author: ''),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar sesión'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Libro: ${book.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(session.date)}',
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: startPageController,
                  decoration: const InputDecoration(
                    labelText: 'Página inicial',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa la página inicial';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Debe ser un número';
                    }
                    return null;
                  },
                ),

                TextFormField(
                  controller: endPageController,
                  decoration: const InputDecoration(labelText: 'Página final'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, ingresa la página final';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Debe ser un número';
                    }
                    final startPage =
                        int.tryParse(startPageController.text) ?? 0;
                    final endPage = int.tryParse(value) ?? 0;
                    if (endPage <= startPage) {
                      return 'La página final debe ser mayor que la inicial';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),
                Text(
                  'Duración: ${_formatDuration(session.duration)}',
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final sessionProvider = Provider.of<ReadingSessionProvider>(
          context,
          listen: false,
        );

        final updatedSession = ReadingSession(
          id: session.id,
          bookId: session.bookId,
          date: session.date,
          startPage: int.parse(startPageController.text),
          endPage: int.parse(endPageController.text),
          duration: session.duration,
          notes: notesController.text,
        );

        await sessionProvider.updateSession(updatedSession);
        _loadData(); // Recargar datos

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar la sesión: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Confirmar y eliminar una sesión
  Future<void> _deleteSession(ReadingSession session) async {
    final book = _books.firstWhere(
      (b) => b.id == session.bookId,
      orElse: () => Book(id: '', title: 'Libro no encontrado', author: ''),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar sesión'),
        content: Text(
          '¿Estás seguro de que deseas eliminar esta sesión de lectura de "${book.title}"?\n\n'
          'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(session.date)}\n'
          'Páginas: ${session.startPage} - ${session.endPage}\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final sessionProvider = Provider.of<ReadingSessionProvider>(
          context,
          listen: false,
        );
        await sessionProvider.deleteSession(session.id!);
        _loadData(); // Recargar datos

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión eliminada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar la sesión: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Formatear la duración para mostrarla
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  // Obtener el título de un libro por su ID
  String _getBookTitle(String bookId) {
    final book = _books.firstWhere(
      (book) => book.id == bookId,
      orElse: () => Book(id: '', title: 'Libro no encontrado', author: ''),
    );

    return book.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de lecturas'),
        actions: [
          IconButton(
            onPressed: _showDateRangeDialog,
            icon: const Icon(Icons.date_range),
            tooltip: 'Filtrar por fechas',
          ),
          IconButton(
            onPressed: _resetFilters,
            icon: const Icon(Icons.filter_alt_off),
            tooltip: 'Limpiar filtros',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtro por libro
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por libro',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedBookId,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Todos los libros'),
                      ),
                      ..._books.map(
                        (book) => DropdownMenuItem<String>(
                          value: book.id,
                          child: Text(
                            book.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedBookId = value;
                      });
                      _applyFilters();
                    },
                  ),
                ),

                // Mostrar fechas seleccionadas si hay un filtro activo
                if (_startDate != null || _endDate != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                              : _startDate != null
                              ? 'Desde ${DateFormat('dd/MM/yyyy').format(_startDate!)}'
                              : 'Hasta ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                            });
                            _applyFilters();
                          },
                          child: const Text('Limpiar fechas'),
                        ),
                      ],
                    ),
                  ),

                // Lista de sesiones
                Expanded(
                  child: _filteredSessions.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay sesiones de lectura para mostrar',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredSessions.length,
                          itemBuilder: (context, index) {
                            final session = _filteredSessions[index];
                            return _buildSessionItem(session);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Construir item de sesión para la lista
  Widget _buildSessionItem(ReadingSession session) {
    final pagesRead = session.endPage - session.startPage;
    final bookTitle = _getBookTitle(session.bookId);
    final readingSpeed = session.duration.inSeconds > 0
        ? (pagesRead * 3600) / session.duration.inSeconds
        : 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bookTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy').format(session.date),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Páginas: ${session.startPage} → ${session.endPage} ($pagesRead)',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tiempo: ${_formatDuration(session.duration)}',
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${readingSpeed.toStringAsFixed(1)} págs/hora',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(session.date),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            if (session.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Notas:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                session.notes,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditSessionDialog(session);
                break;
              case 'delete':
                _deleteSession(session);
                break;
            }
          },
        ),
      ),
    );
  }
}
