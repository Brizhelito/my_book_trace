import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Pantalla para escanear códigos de barras ISBN
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  // Controlador básico de escáner
  final MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  
  // Controlador para el campo de texto del ISBN manual
  final TextEditingController _isbnController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Función para procesar el ISBN ingresado manualmente
  void _submitManualIsbn() {
    // Validar el formulario
    if (_formKey.currentState!.validate()) {
      // Obtener el ISBN del campo de texto
      final isbn = _isbnController.text.trim();
      
      // Cerrar el teclado
      FocusScope.of(context).unfocus();
      
      // Devolver el ISBN ingresado manualmente
      Navigator.of(context).pop(isbn);
    }
  }
  
  @override
  void dispose() {
    controller.dispose();
    _isbnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear ISBN'),
        actions: [
          // Botón simple para linterna
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          // Botón simple para cambiar de cámara
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: (BarcodeCapture capture) {
                if (!_isScanning) return;

                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  // Verificar que tenemos un valor y es un ISBN (EAN)
                  if (barcode.rawValue != null) {
                    // Evitar múltiples detecciones
                    setState(() => _isScanning = false);
                    // Devolver el código detectado
                    Navigator.of(context).pop(barcode.rawValue);
                    break;
                  }
                }
              },
            ),
          ),
          // Instrucciones en la parte inferior
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black54,
            child: const Text(
              'Apunta a un código de barras ISBN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Separador
          const Divider(height: 1, color: Colors.grey),
          
          // Sección para ingresar ISBN manualmente
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '¿Problemas con el escáner?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _isbnController,
                    decoration: const InputDecoration(
                      labelText: 'Ingresa el ISBN manualmente',
                      hintText: 'Ej. 9788417347161',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.input),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un ISBN';
                      }
                      if (value.length < 10 || value.length > 13) {
                        return 'ISBN debe tener 10 o 13 dígitos';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _submitManualIsbn,
                    child: const Text('Buscar por ISBN'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
