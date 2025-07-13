import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:my_book_trace/models/book.dart';
import 'package:my_book_trace/models/reading_session.dart';
import 'package:my_book_trace/providers/book_provider.dart';
import 'package:my_book_trace/providers/reading_session_provider.dart';

/// Pantalla para registrar una sesión de lectura activa
class ActiveReadingSessionScreen extends StatefulWidget {
  final String bookId;

  const ActiveReadingSessionScreen({required this.bookId, super.key});

  @override
  State<ActiveReadingSessionScreen> createState() =>
      _ActiveReadingSessionScreenState();
}

class _ActiveReadingSessionScreenState
    extends State<ActiveReadingSessionScreen> {
  bool _isLoading = true;
  Book? _book;
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final _currentPageController = TextEditingController();
  final _notesController = TextEditingController();

  // Variables para el contador de tiempo
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  bool _isSessionActive = false;

  // Página inicial y final de la sesión
  int _startPage = 0;
  int _endPage = 0;

  // Estadísticas de la sesión
  double _pagesPerMinute = 0.0;
  Duration _estimatedTimeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadBookDetails();
    _currentPageController.addListener(_updateReadingStats);
  }

  // Actualizar estadísticas de lectura
  void _updateReadingStats() {
    if (!mounted ||
        _book == null ||
        _book!.pageCount == null ||
        _book!.pageCount == 0)
      return;

    final currentPage = int.tryParse(_currentPageController.text) ?? _startPage;
    final pagesRead = currentPage - _startPage;

    if (_elapsedTime.inSeconds > 0 && pagesRead > 0) {
      // Calcular páginas por minuto
      _pagesPerMinute = (pagesRead / _elapsedTime.inSeconds) * 60;

      // Calcular tiempo estimado restante
      final pagesRemaining = _book!.pageCount! - currentPage;
      if (pagesRemaining > 0) {
        final secondsRemaining = (pagesRemaining / _pagesPerMinute) * 60;
        _estimatedTimeRemaining = Duration(seconds: secondsRemaining.toInt());
      } else {
        _estimatedTimeRemaining = Duration.zero;
      }
    } else {
      _pagesPerMinute = 0.0;
      _estimatedTimeRemaining = Duration.zero;
    }

    setState(() {}); // Actualizar la UI
  }

  @override
  void dispose() {
    // Solo cancelar el timer sin actualizar el estado
    _cancelTimerSilently();
    _currentPageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Cancela el timer sin actualizar el estado (seguro para usar en dispose)
  void _cancelTimerSilently() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  // Cargar detalles del libro
  Future<void> _loadBookDetails() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      await bookProvider.selectBook(widget.bookId);

      if (mounted) {
        // Verificar si el widget sigue montado antes de actualizar el estado
        setState(() {
          _book = bookProvider.selectedBook;
          _isLoading = false;
        });

        // Mostrar diálogo para seleccionar página inicial
        if (_book != null) {
          _showStartPageDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        // Verificar si el widget sigue montado antes de actualizar el estado
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el libro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Iniciar el contador de tiempo
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // Verificar si el widget sigue montado antes de actualizar el estado
        setState(() {
          _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
          _updateReadingStats(); // Actualizar estadísticas con cada segundo
        });
      } else {
        // Si el widget ya no está montado, cancelar el timer
        timer.cancel();
      }
    });

    if (mounted) {
      // Verificar si el widget sigue montado antes de actualizar el estado
      setState(() {
        _isSessionActive = true;
      });
    }
  }

  // Detener el contador de tiempo
  void _stopTimer() {
    _timer?.cancel();
    if (mounted) {
      // Verificar si el widget sigue montado antes de actualizar el estado
      setState(() {
        _isSessionActive = false;
      });
    }
  }

  // Pausar o reanudar la sesión
  void _toggleSession() {
    if (_isSessionActive) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  // Finalizar la sesión
  void _finishSession() {
    // Verificar que la página final sea mayor que la inicial
    final currentPage = int.tryParse(_currentPageController.text);
    if (currentPage == null || currentPage <= _startPage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La página actual debe ser mayor que la página inicial',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Mostrar diálogo de confirmación
    showDialog(
      context: context,
      builder: (context) => _buildFinishSessionDialog(),
    ).then((confirmed) {
      if (confirmed ?? false) {
        _stopTimer();
        _saveReadingSession();
      }
    });
  }

  // Diálogo para seleccionar página inicial
  Future<void> _showStartPageDialog() async {
    // Inicializar con la página actual del libro
    final initialPage = _book!.currentPage ?? 0;
    final pageController = TextEditingController(text: initialPage.toString());
    final formKey = GlobalKey<FormState>();

    final int? selectedPage = await showDialog<int>(
      context: context,
      barrierDismissible: false, // El usuario debe tomar una acción
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Iniciar sesión de lectura'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('¿Desde qué página deseas comenzar tu lectura?'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pageController,
                  decoration: const InputDecoration(
                    labelText: 'Página inicial',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bookmark_border),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un número de página';
                    }
                    final page = int.tryParse(value);
                    if (page == null) {
                      return 'Ingresa un número válido';
                    }
                    if (page < 1) {
                      return 'La página debe ser al menos 1';
                    }
                    if (_book!.pageCount != null && page > _book!.pageCount!) {
                      return 'La página no puede ser mayor que el total (${_book!.pageCount})';
                    }
                    return null;
                  },
                ),
                if (_book!.pageCount != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'El libro tiene un total de ${_book!.pageCount} páginas',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
                if (_book!.currentPage != null && _book!.currentPage! > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Última página registrada: ${_book!.currentPage}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Usar la página actual del libro como valor predeterminado
                Navigator.of(context).pop(initialPage);
              },
              child: const Text('Usar última página'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final page = int.parse(pageController.text);
                  Navigator.of(context).pop(page);
                }
              },
              child: const Text('Comenzar'),
            ),
          ],
        );
      },
    );

    // Si se seleccionó una página, actualizar _startPage
    if (selectedPage != null) {
      setState(() {
        _startPage = selectedPage;
        _currentPageController.text = _startPage.toString();
      });
    } else {
      // Si el usuario canceló el diálogo, volver a la pantalla anterior
      if (mounted) {
        context.pop();
      }
    }
  }

  // Diálogo para finalizar sesión
  Widget _buildFinishSessionDialog() {
    final int pagesRead = int.parse(_currentPageController.text) - _startPage;
    final double readingSpeed = _elapsedTime.inSeconds > 0
        ? (pagesRead * 3600) / _elapsedTime.inSeconds
        : 0;

    // Asegurar que el controlador de notas esté inicializado
    _notesController.text = _notesController.text.trim();

    return AlertDialog(
      title: const Text('Finalizar sesión'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Has leído durante ${_formatDuration(_elapsedTime)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Estadísticas en tiempo real
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Páginas/min',
                    _pagesPerMinute.toStringAsFixed(1),
                    Icons.speed_rounded,
                  ),
                  _buildStatItem(
                    'Tiempo restante',
                    _formatDuration(_estimatedTimeRemaining),
                    Icons.hourglass_bottom_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Páginas leídas
              Text(
                'Has leído desde la página $_startPage hasta la página ${_currentPageController.text}',
              ),
              const SizedBox(height: 8),
              Text(
                'Total: $pagesRead páginas',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Velocidad: ${readingSpeed.toStringAsFixed(1)} páginas/hora',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 16),

              // Notas de la sesión - Mejorado para asegurar captura adecuada
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notas de la sesión',
                  hintText: 'Añade notas sobre tu sesión de lectura',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt),
                ),
                maxLines: 3,
                onChanged: (value) {
                  // Actualizar inmediatamente para asegurar que se guarde
                  debugPrint('Notas actualizadas: $value');
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(false), // Devolver false al cancelar
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            debugPrint('Guardando sesión con notas: ${_notesController.text}');
            Navigator.of(context).pop(true); // Devolver true al confirmar
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  // Guardar la sesión de lectura
  Future<void> _saveReadingSession() async {
    if (_book == null || _book!.id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error: No se puede guardar la sesión, libro no válido',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final sessionProvider = Provider.of<ReadingSessionProvider>(
        context,
        listen: false,
      );

      // Obtener el número de página final y validar
      final int endPage = int.parse(_currentPageController.text);
      if (endPage <= _startPage) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La página final debe ser mayor que la inicial'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Validar duración
      if (_elapsedTime.inSeconds <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La sesión debe tener una duración válida'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Actualizar el libro con la nueva página actual
      final updatedBook = _book!.copyWith(
        currentPage: endPage,
        status: endPage >= (_book!.pageCount ?? 0)
            ? Book.STATUS_COMPLETED
            : Book.STATUS_IN_PROGRESS,
        startDate: _book!.startDate ?? DateTime.now(),
        finishDate: endPage >= (_book!.pageCount ?? 0)
            ? DateTime.now()
            : _book!.finishDate,
        updatedAt: DateTime.now(),
      );

      debugPrint('Actualizando libro: ${updatedBook.id} a página: $endPage');
      final bookUpdateSuccess = await bookProvider.updateBook(updatedBook);
      if (!bookUpdateSuccess) {
        throw Exception('Error al actualizar el libro');
      }

      // Crear y guardar la sesión de lectura
      // Preparar notas y eliminar cualquier caracter no válido o problemas comunes
      String sanitizedNotes = _notesController.text.trim();

      // Validación exhaustiva de la integridad del ID del libro
      if (_book == null) {
        throw Exception('Error: El libro es nulo');
      }

      if (_book!.id == null || _book!.id!.isEmpty) {
        throw Exception('Error: El ID del libro es nulo o está vacío');
      }

      debugPrint('VALIDACIÓN: ID del libro: "${_book!.id!}"');
      debugPrint('Preparando sesión con notas: "$sanitizedNotes"');

      final String bookId = _book!.id!;

      final session = ReadingSession(
        bookId: bookId,
        date: DateTime.now(),
        startPage: _startPage,
        endPage: endPage,
        duration: _elapsedTime,
        notes: sanitizedNotes,
      );

      debugPrint(
        'Guardando sesión para libro: ${session.bookId}, páginas: ${session.startPage}-${session.endPage}',
      );

      try {
        final newSession = await sessionProvider.addSession(session);

        if (newSession == null) {
          debugPrint('ERROR CRÍTICO: La sesión guardada es nula');
          throw Exception(
            'Error al guardar la sesión de lectura: la sesión retornada es nula',
          );
        }

        debugPrint('Sesión guardada correctamente con ID: ${newSession.id}');
      } catch (e, stack) {
        debugPrint('ERROR DETALLADO al guardar sesión: $e');
        debugPrint('Stack trace: $stack');
        rethrow; // Relanzo la excepción para mantener el flujo original
      }

      if (mounted) {
        // Calcular estadísticas para el mensaje
        final int pagesRead = endPage - _startPage;
        final double readingSpeed = _elapsedTime.inSeconds > 0
            ? (pagesRead * 3600) / _elapsedTime.inSeconds
            : 0;
        final double percentCompleted = _book!.pageCount != null
            ? (endPage / _book!.pageCount!) * 100
            : 0;

        // Determinar si se alcanzó algún hito
        String achievement = '';
        Color backgroundColor = Colors.green;

        if (endPage >= (_book!.pageCount ?? 0)) {
          // Libro completado
          achievement = '¡Felicidades! Has completado este libro 🎉';
          backgroundColor = Colors.purple;
        } else if (percentCompleted >= 75) {
          achievement = '¡Ya casi terminas el libro! 🚀';
          backgroundColor = Colors.deepPurple;
        } else if (percentCompleted >= 50) {
          achievement = '¡Has superado la mitad del libro! 🔥';
          backgroundColor = Colors.blue.shade800;
        } else if (readingSpeed > 30) {
          achievement = '¡Gran velocidad de lectura! ⚡';
          backgroundColor = Colors.teal;
        } else if (pagesRead > 20) {
          achievement = '¡Buen avance en esta sesión! 👍';
          backgroundColor = Colors.green.shade700;
        }

        // Mostrar SnackBar informativo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesión guardada: $pagesRead páginas en ${_formatDuration(_elapsedTime)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (achievement.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(achievement),
                  ),
              ],
            ),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
          ),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  // Widget para mostrar una estadística individual
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[700], size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sesión de lectura')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _book == null
          ? const Center(child: Text('No se pudo cargar el libro'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del libro
                  Card(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Portada del libro
                          Container(
                            width: 80,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.grey[300],
                              image: _book?.coverImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        _book!.coverImageUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _book?.coverImageUrl == null
                                ? const Center(
                                    child: Icon(Icons.book, size: 40),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),

                          // Detalles del libro
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _book!.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _book!.author,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_book!.pageCount != null)
                                  Text(
                                    '${_book!.pageCount} páginas totales',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tiempo transcurrido
                  Text(
                    'Tiempo de lectura',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            _formatDuration(_elapsedTime),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Botón de iniciar/pausar
                              FilledButton.icon(
                                onPressed: _toggleSession,
                                icon: Icon(
                                  _isSessionActive
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  _isSessionActive ? 'Pausar' : 'Iniciar',
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Botón de finalizar
                              OutlinedButton.icon(
                                onPressed: _isSessionActive
                                    ? _finishSession
                                    : null,
                                icon: const Icon(Icons.stop),
                                label: const Text('Finalizar'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Estadísticas en tiempo real
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Páginas/min',
                        _pagesPerMinute.toStringAsFixed(1),
                        Icons.speed_rounded,
                      ),
                      _buildStatItem(
                        'Tiempo restante',
                        _formatDuration(_estimatedTimeRemaining),
                        Icons.hourglass_bottom_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progreso de lectura
                  Text(
                    'Progreso de lectura',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Indicador de progreso
                          if (_book!.pageCount != null)
                            LinearProgressIndicator(
                              value:
                                  int.parse(
                                    _currentPageController.text.isEmpty
                                        ? '0'
                                        : _currentPageController.text,
                                  ) /
                                  _book!.pageCount!,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          const SizedBox(height: 16),

                          // Página actual
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _currentPageController,
                                  decoration: const InputDecoration(
                                    labelText: 'Página actual',
                                    hintText: 'Ingresa la página actual',
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _endPage =
                                          int.tryParse(value) ?? _startPage;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (_book!.pageCount != null)
                                Text(
                                  'de ${_book!.pageCount}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Páginas leídas en esta sesión
                          Text(
                            'Páginas leídas en esta sesión: ${_endPage - _startPage}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
