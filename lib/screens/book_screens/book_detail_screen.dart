import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:my_book_trace/constants/app_constants.dart';
import 'package:my_book_trace/models/book.dart';
import 'package:my_book_trace/models/reading_session.dart';
import 'package:my_book_trace/providers/book_provider.dart';
import 'package:my_book_trace/providers/reading_session_provider.dart';
import 'package:intl/intl.dart';

/// Pantalla de detalles del libro seleccionado
class BookDetailScreen extends StatefulWidget {
  final String bookId;
  final String? initialTab;

  const BookDetailScreen({required this.bookId, this.initialTab, super.key});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Book? _book;

  // Lista de sesiones para el libro actual
  List<ReadingSession> _bookSessions = [];
  bool _loadingSessions = true;
  bool _sessionsLoadAttempted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Cargar detalles del libro
    _loadBookDetails();

    // Establecer la pestaña inicial si se especifica
    if (widget.initialTab != null) {
      switch (widget.initialTab) {
        case 'notes':
          _tabController.index = 1;
          break;
        case 'stats':
          _tabController.index = 2;
          break;
      }
    }

    // Cuando el libro esté cargado, cargamos sus sesiones de lectura
    _tabController.addListener(() {
      // Cargar sesiones tanto para notas (index 1) como para estadísticas (index 2)
      if ((_tabController.index == 1 || _tabController.index == 2) &&
          !_isLoading &&
          _book != null) {
        _loadReadingSessions();
      }
    });
  }

  // Cargar las sesiones de lectura para este libro
  Future<void> _loadReadingSessions() async {
    if (_book == null || !mounted) return;

    // Definir estado de carga
    setState(() {
      _loadingSessions = true;
    });

    try {
      final sessionProvider = Provider.of<ReadingSessionProvider>(
        context,
        listen: false,
      );
      final sessions = await sessionProvider.loadSessionsForBook(_book!.id!);

      if (mounted) {
        setState(() {
          _bookSessions = sessions;
          _loadingSessions = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar sesiones de lectura: $e');
    } finally {
      // Asegurar que el loader siempre se desactive, incluso en caso de error o si el widget ya no está montado
      if (mounted) {
        setState(() {
          _loadingSessions = false;
          _sessionsLoadAttempted = true; // Marcar que ya se intentó la carga
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Cargar los detalles del libro
  Future<void> _loadBookDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      await bookProvider.selectBook(widget.bookId);

      setState(() {
        _book = bookProvider.selectedBook;
        _isLoading = false;
        _loadingSessions = false; // Resetear estado de carga de sesiones
        _bookSessions = []; // Limpiar sesiones previas
        _sessionsLoadAttempted =
            false; // Permitir nuevo intento de carga para el nuevo libro
      });
      // Si la pestaña activa es notas o estadísticas, cargar sesiones inmediatamente
      if (_tabController.index == 1 || _tabController.index == 2) {
        _loadReadingSessions();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoading ? 'Cargando...' : _book?.title ?? 'Detalles del libro',
        ),
        actions: [
          // Botón de editar
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (_book?.id != null) {
                context.push(AppRoutes.editBookPath(_book!.id!));
              }
            },
          ),
          // Menú de opciones
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete' && _book?.id != null) {
                _showDeleteConfirmationDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Eliminar'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Detalles'),
            Tab(text: 'Notas'),
            Tab(text: 'Estadísticas'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _book == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No se pudo cargar el libro'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildNotesTab(),
                _buildStatsTab(),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  // Construir el botón flotante según la pestaña seleccionada
  Widget? _buildFloatingActionButton() {
    if (_book == null) return null;

    switch (_tabController.index) {
      case 0:
        // Pestaña de detalles - Botón para comenzar a leer
        if (_book!.status != Book.STATUS_COMPLETED) {
          return FloatingActionButton.extended(
            heroTag: 'book_detail_read_fab',
            onPressed: () {
              if (_book?.id != null) {
                context.push(AppRoutes.activeReadingSessionPath(_book!.id!));
              }
            },
            icon: const Icon(Icons.menu_book),
            label: Text(
              _book!.status == Book.STATUS_IN_PROGRESS
                  ? 'Continuar lectura'
                  : 'Comenzar lectura',
            ),
          );
        }
        break;
      case 1:
        // Pestaña de notas - Botón para añadir nota
        return FloatingActionButton.extended(
          heroTag: 'book_detail_note_fab',
          onPressed: () {
            context.push(AppRoutes.activeReadingSessionPath(_book!.id!));
          },
          icon: const Icon(Icons.note_add),
          label: Text(
            _book!.status == Book.STATUS_IN_PROGRESS
                ? 'Continuar lectura'
                : 'Comenzar lectura',
          ),
        );
    }

    return null;
  }

  // Pestaña de detalles del libro
  Widget _buildDetailsTab() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección de portada e información principal
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Portada del libro
              Container(
                width: 120,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                  image: _book?.coverImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_book!.coverImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _book?.coverImageUrl == null
                    ? Center(
                        child: Icon(
                          Icons.book,
                          size: 40,
                          color: Colors.grey[600],
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Información principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      _book?.title ?? '',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Autor
                    Text(
                      _book?.author ?? '',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    // Estado de lectura
                    _buildStatusChip(),
                    const SizedBox(height: 16),
                    // Calificación
                    if (_book?.rating != null)
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < (_book!.rating!.round())
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            '${_book?.rating}',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sección de información adicional
          _buildInfoSection('Información del libro', [
            _buildInfoItem('Páginas', '${_book?.pageCount ?? "N/A"}'),
            if (_book?.isbn != null) _buildInfoItem('ISBN', _book?.isbn ?? ''),
            if (_book?.publisher != null)
              _buildInfoItem('Editorial', _book?.publisher ?? ''),
            if (_book?.publicationYear != null)
              _buildInfoItem('Año', '${_book?.publicationYear}'),
            if (_book?.language != null)
              _buildInfoItem('Idioma', _book?.language ?? ''),
            if (_book?.genre != null)
              _buildInfoItem('Género', _book?.genre ?? ''),
          ]),

          const SizedBox(height: 24),

          // Sección de descripción
          if (_book?.description != null && _book!.description!.isNotEmpty) ...[
            Text('Descripción', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(_book?.description ?? '', style: theme.textTheme.bodyMedium),
          ],

          const SizedBox(height: 24),

          // Sección de progreso de lectura
          _buildInfoSection('Progreso de lectura', [
            if (_book?.startDate != null)
              _buildInfoItem('Inicio', _formatDate(_book!.startDate!)),
            if (_book?.finishDate != null)
              _buildInfoItem('Finalización', _formatDate(_book!.finishDate!)),
          ]),

          const SizedBox(height: 80), // Espacio para el FAB
        ],
      ),
    );
  }

  // Pestaña de notas del libro
  Widget _buildNotesTab() {
    if (_book == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notas de sesiones de lectura
          Text(
            'Notas de lectura',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _loadingSessions
              ? const Center(child: CircularProgressIndicator())
              : _buildSessionNotesList(),

          const SizedBox(height: 80), // Espacio para el FAB
        ],
      ),
    );
  }

  // Construir lista de notas de sesiones
  Widget _buildSessionNotesList() {
    // Filtrar solo sesiones que tengan notas
    final sessionsWithNotes = _bookSessions
        .where((session) => session.notes.isNotEmpty)
        .toList();

    if (sessionsWithNotes.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('No hay notas de sesiones de lectura')),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: sessionsWithNotes.length,
      itemBuilder: (context, index) {
        final session = sessionsWithNotes[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha y duración de la sesión
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(session.date),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      _formatDuration(session.duration),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const Divider(),
                // Notas de la sesión
                Text(session.notes),
                const SizedBox(height: 8),
                // Información de páginas leídas
                Text(
                  'Páginas: ${session.startPage} - ${session.endPage}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Pestaña de estadísticas de lectura
  Widget _buildStatsTab() {
    // Cargar sesiones si aún no se han cargado y el libro ya está cargado
    if (_book != null && !_isLoading) {
      // Siempre verificar si necesitamos cargar las sesiones, pero solo una vez
      if (_tabController.index == 2 &&
          !_sessionsLoadAttempted &&
          !_loadingSessions) {
        // Usar Future.microtask para evitar setState durante el build
        Future.microtask(() => _loadReadingSessions());
      }

      // Si está cargando, mostrar el indicador
      if (_loadingSessions) {
        return const Center(child: CircularProgressIndicator());
      }
      // Si no está cargando y no hay sesiones, mostrar mensaje
      else if (_bookSessions.isEmpty) {
        return const Center(
          child: Text('Aún no hay sesiones de lectura para este libro'),
        );
      }
    } else if (_isLoading) {
      // Si el libro aún está cargando
      return const Center(child: CircularProgressIndicator());
    }

    // Si hay un error y no hay libro
    if (_book == null) {
      return const Center(
        child: Text('No se pudieron cargar las estadísticas'),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de estadísticas
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de lectura',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    'Total de sesiones',
                    '${_bookSessions.length}',
                  ),
                  _buildStatItem(
                    'Páginas leídas',
                    _calculateTotalPagesRead().toString(),
                  ),
                  _buildStatItem('Tiempo total', _formatTotalReadingTime()),
                  // Estadísticas adicionales
                  _buildStatItem(
                    'Promedio páginas/sesión',
                    _bookSessions.isNotEmpty
                        ? (_calculateTotalPagesRead() / _bookSessions.length)
                              .toStringAsFixed(1)
                        : '0',
                  ),
                  _buildStatItem(
                    'Tiempo promedio/sesión',
                    _calculateAverageSessionTime(),
                  ),
                  if (_bookSessions.isNotEmpty) ...[
                    _buildStatItem(
                      'Primera sesión',
                      _formatDate(_getFirstSessionDate()),
                    ),
                    _buildStatItem(
                      'Última sesión',
                      _formatDate(_getLastSessionDate()),
                    ),
                  ],
                  _buildStatItem(
                    'Velocidad promedio',
                    _calculateAverageReadingSpeed(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Historial de sesiones
          Text(
            'Historial de sesiones',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          _bookSessions.isEmpty
              ? const Center(
                  child: Text('Aún no hay sesiones de lectura para este libro'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bookSessions.length,
                  itemBuilder: (context, index) {
                    final session = _bookSessions[index];
                    return _buildSessionCard(session);
                  },
                ),
        ],
      ),
    );
  }

  // Construir tarjeta para una sesión de lectura individual
  Widget _buildSessionCard(ReadingSession session) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final formattedDate = dateFormat.format(session.date);
    final pagesRead = session.endPage - session.startPage;
    final readingTime = _formatDuration(session.duration);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$pagesRead páginas',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Páginas: ${session.startPage} - ${session.endPage}'),
            Text('Tiempo: $readingTime'),

            // Mostrar notas si existen
            if (session.notes.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Notas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(session.notes),
            ],
          ],
        ),
      ),
    );
  }

  // Calcular el total de páginas leídas en todas las sesiones
  int _calculateTotalPagesRead() {
    int total = 0;
    for (final session in _bookSessions) {
      total += (session.endPage - session.startPage);
    }
    return total;
  }

  // Formatear el tiempo total de lectura
  String _formatTotalReadingTime() {
    Duration totalDuration = Duration.zero;
    for (final session in _bookSessions) {
      totalDuration += session.duration;
    }
    return _formatDuration(totalDuration);
  }

  // Formatear una duración a texto legible
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours h $minutes min';
    } else {
      return '$minutes min';
    }
  }

  // Calcular páginas por hora
  String _calculatePagesPerHour() {
    if (_bookSessions.isEmpty) {
      return '0 págs/hora';
    }

    int totalPages = 0;
    Duration totalDuration = Duration.zero;

    for (final session in _bookSessions) {
      totalPages += (session.endPage - session.startPage);
      totalDuration += session.duration;
    }

    // Evitar división por cero
    if (totalDuration.inSeconds == 0) {
      return '0 págs/hora';
    }

    // Calcular páginas por hora: (páginas * 3600) / segundos totales
    final pagesPerHour = (totalPages * 3600) / totalDuration.inSeconds;

    return '${pagesPerHour.toStringAsFixed(1)} págs/hora';
  }

  // Calcular el tiempo promedio por sesión
  String _calculateAverageSessionTime() {
    if (_bookSessions.isEmpty) {
      return '0 min';
    }

    Duration totalDuration = Duration.zero;
    for (final session in _bookSessions) {
      totalDuration += session.duration;
    }

    final averageMilliseconds =
        totalDuration.inMilliseconds ~/ _bookSessions.length;
    return _formatDuration(Duration(milliseconds: averageMilliseconds));
  }

  // Obtener la fecha de la primera sesión
  DateTime _getFirstSessionDate() {
    if (_bookSessions.isEmpty) {
      return DateTime.now();
    }

    // Ordenar sesiones por fecha ascendente y tomar la primera
    final sortedSessions = List<ReadingSession>.from(_bookSessions);
    sortedSessions.sort((a, b) => a.date.compareTo(b.date));
    return sortedSessions.first.date;
  }

  // Obtener la fecha de la última sesión
  DateTime _getLastSessionDate() {
    if (_bookSessions.isEmpty) {
      return DateTime.now();
    }

    // Ordenar sesiones por fecha descendente y tomar la primera
    final sortedSessions = List<ReadingSession>.from(_bookSessions);
    sortedSessions.sort((a, b) => b.date.compareTo(a.date));
    return sortedSessions.first.date;
  }

  // Calcular la velocidad de lectura promedio (páginas por hora)
  String _calculateAverageReadingSpeed() {
    if (_bookSessions.isEmpty) {
      return '0 pág/h';
    }

    int totalPages = _calculateTotalPagesRead();
    int totalSeconds = 0;

    for (final session in _bookSessions) {
      totalSeconds += session.duration.inSeconds;
    }

    if (totalSeconds == 0) {
      return '0 pág/h';
    }

    // Convertir segundos a horas y calcular páginas por hora
    final totalHours = totalSeconds / 3600;
    final pagesPerHour = totalPages / totalHours;

    return '${pagesPerHour.toStringAsFixed(1)} pág/h';
  }

  // Construir item de estadística
  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Construir chip de estado
  Widget _buildStatusChip() {
    Color chipColor;
    String statusText;

    switch (_book?.status) {
      case Book.STATUS_IN_PROGRESS:
        chipColor = Colors.blue;
        statusText = 'Leyendo';
        break;
      case Book.STATUS_COMPLETED:
        chipColor = Colors.green;
        statusText = 'Completado';
        break;
      case Book.STATUS_ABANDONED:
        chipColor = Colors.red;
        statusText = 'Abandonado';
        break;
      default:
        chipColor = Colors.orange;
        statusText = 'No iniciado';
    }

    return Chip(
      label: Text(
        statusText,
        style: TextStyle(
          color: chipColor.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white,
        ),
      ),
      backgroundColor: chipColor.withOpacity(0.2),
      side: BorderSide(color: chipColor),
    );
  }

  // Construir sección de información
  Widget _buildInfoSection(String title, List<Widget> children) {
    final theme = Theme.of(context);

    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  // Construir un elemento de información
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  // Formatear fecha para mostrar
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Diálogo de confirmación para eliminar libro
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${_book?.title}"?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();

              if (_book?.id != null) {
                final result = await Provider.of<BookProvider>(
                  context,
                  listen: false,
                ).deleteBook(_book!.id!);

                if (result && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Libro eliminado correctamente'),
                    ),
                  );
                  context.pop();
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
