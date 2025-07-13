import 'package:flutter/foundation.dart';

/// Servicio de logging para centralizar y estandarizar todos los logs de la aplicación.
/// 
/// Este servicio reemplaza el uso directo de print() en el código para ofrecer
/// mejor control sobre qué se registra y cómo se formatean los mensajes.
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  
  factory LoggerService() => _instance;
  
  LoggerService._internal();

  /// Log de información general
  void info(String message, {String? tag}) {
    _log('INFO', message, tag: tag);
  }
  
  /// Log de mensajes de debug (solo visibles en modo debug)
  void debug(String message, {String? tag}) {
    // Solo mostrar mensajes de debug en modo debug
    if (kDebugMode) {
      _log('DEBUG', message, tag: tag);
    }
  }
  
  /// Log de advertencias
  void warning(String message, {String? tag}) {
    _log('WARNING', message, tag: tag);
  }
  
  /// Log de errores
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, tag: tag);
    
    // Registrar error y stack trace si están disponibles
    if (error != null) {
      _log('ERROR', 'Error details: $error', tag: tag);
    }
    
    if (stackTrace != null) {
      _log('ERROR', 'Stack trace: $stackTrace', tag: tag);
    }
  }
  
  /// Método interno para formatear y mostrar logs
  void _log(String level, String message, {String? tag}) {
    final DateTime now = DateTime.now();
    final String timeStamp = '${now.hour}:${now.minute}:${now.second}.${now.millisecond}';
    final String formattedTag = tag != null ? '[$tag]' : '';
    
    // En un entorno de producción, aquí se podría implementar el envío de logs
    // a servicios de analytics o monitoreo
    debugPrint('$timeStamp [$level] $formattedTag $message');
  }
}

/// Instancia global del logger para facilitar su uso
final logger = LoggerService();
