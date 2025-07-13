# My Book Trace

Aplicación en Flutter para el seguimiento de lecturas de libros.

## Estructura del Proyecto y Diseño

El proyecto sigue una arquitectura limpia y organizada para facilitar la mantenibilidad y escalabilidad. La estructura principal del código se encuentra dentro del directorio `lib/` y se organiza de la siguiente manera:

-   **`main.dart`**: Punto de entrada de la aplicación. Aquí se inicializa la app y se configuran los providers principales.

-   **`/config`**: Contiene archivos de configuración global para la aplicación, como temas, rutas y otras configuraciones iniciales.

-   **`/constants`**: Almacena valores constantes utilizados en toda la aplicación, como claves de API, strings de UI, o colores específicos para evitar hardcodear valores.

-   **`/models`**: Define las clases de modelo de datos (ej. `Book`, `ReadingSession`, `User`). Estas clases representan la estructura de los datos que maneja la aplicación.

-   **`/providers`**: Utiliza el paquete `provider` para la gestión de estado. Cada provider expone un estado y notifica a los widgets cuando este cambia, permitiendo una reactividad eficiente en la UI.

-   **`/repositories`**: Contiene la lógica de acceso a datos. Abstrae las fuentes de datos (API, base de datos local) del resto de la aplicación, proveyendo una interfaz limpia para obtener y guardar datos.

-   **`/screens`**: Contiene las diferentes pantallas o vistas de la aplicación. Cada pantalla es un widget que representa una ruta de navegación completa.

-   **`/services`**: Implementa la lógica de negocio de la aplicación. Los servicios son utilizados por los providers y los widgets para realizar operaciones como autenticación, cálculos complejos o comunicación con APIs.

-   **`/utils`**: Directorio para funciones y clases de utilidad reutilizables en diferentes partes del proyecto (ej. formateadores de fecha, validadores).

-   **`/widgets`**: Almacena widgets reutilizables que se usan en varias pantallas, como botones personalizados, tarjetas de información o diálogos. Esto promueve la consistencia visual y la reutilización de código.

## Librerías Principales

El proyecto utiliza una selección de librerías de alta calidad para potenciar sus funcionalidades. A continuación se detallan las más importantes:

-   **`go_router`**: Gestiona la navegación y el enrutamiento de la aplicación de una manera robusta y centralizada, permitiendo manejar rutas complejas y deep linking.
-   **`provider`**: Solución principal para la gestión de estado. Facilita la comunicación entre los widgets y la lógica de negocio de forma eficiente y con bajo acoplamiento.
-   **`sqflite`**: Proporciona acceso a una base de datos SQLite local para el almacenamiento persistente de datos, como libros, sesiones de lectura y desafíos.
-   **`shared_preferences`**: Utilizado para guardar datos simples y preferencias del usuario de forma persistente, como configuraciones de la aplicación o el estado de la sesión.
-   **`fl_chart`**: Permite la creación de gráficos y diagramas interactivos y personalizables para visualizar las estadísticas de lectura.
-   **`uuid`**: Genera identificadores únicos universales (UUIDs) para garantizar que los registros en la base de datos tengan una clave única y segura.
-   **`path`**: Utilidad para la manipulación de rutas del sistema de archivos, esencial para localizar la base de datos `sqflite`.
-   **`cupertino_icons`**: Incluye los iconos de estilo iOS para mantener una apariencia nativa en esa plataforma.
