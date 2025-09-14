# 🏓 Ping Pong FIE

Una aplicación Flutter moderna para llevar el marcador en partidos de ping pong, diseñada con Material Design 3 y arquitectura limpia.

![Flutter Version](https://img.shields.io/badge/flutter-%3E%3D3.7.2-blue.svg)
![Dart Version](https://img.shields.io/badge/dart-%3E%3D3.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-purple.svg)

## ✨ Características

- 🎮 Marcador interactivo con gestos
- 🔄 Control de saques automático
- 🏆 Sistema de puntuación oficial
- 🌟 Modo de desempate (después de 10-10)
- ⏱️ Temporizador de calentamiento
- 📊 Historial de partidas
- 🎵 Efectos de sonido
- 🎨 Diseño Material 3
- 📱 Modo landscape optimizado

## 🚀 Comenzando

### Prerrequisitos

- Flutter SDK ≥ 3.7.2
- Dart SDK ≥ 3.0.0
- Git

### Instalación

1. Clona el repositorio:
```bash
git clone https://github.com/MAGIN1104/pingPong.git
```

2. Navega al directorio del proyecto:
```bash
cd pingPong
```

3. Instala las dependencias:
```bash
flutter pub get
```

4. Ejecuta la aplicación:
```bash
flutter run
```

## 🏗️ Arquitectura

El proyecto sigue los principios de Clean Architecture y está organizado en features:

```
lib/
├── core/
│   └── di/           # Inyección de dependencias
└── features/
    ├── game/         # Feature principal del juego
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── setup/        # Configuración inicial
    └── splash/       # Splash screen animado
```

### Patrones y Tecnologías

- 🏛️ Clean Architecture
- 📦 BLoC para gestión de estado
- 💉 Get_it para inyección de dependencias
- 🔄 Repository pattern
- ✨ Animaciones personalizadas

## 🤝 Contribuyendo

Las contribuciones son bienvenidas. Para cambios importantes:

1. Fork el proyecto
2. Crea una nueva rama:
```bash
git checkout -b feature/nueva-caracteristica
```

3. Haz tus cambios y commitea:
```bash
git commit -m "feat: Agrega nueva característica"
```

4. Push a tu fork:
```bash
git push origin feature/nueva-caracteristica
```

5. Abre un Pull Request

### Convenciones de Código

- Seguir el [estilo de código de Dart](https://dart.dev/guides/language/effective-dart/style)
- Usar [Conventional Commits](https://www.conventionalcommits.org/) para mensajes de commit
- Mantener la arquitectura limpia existente
- Documentar nuevo código
- Agregar tests para nueva funcionalidad

## 📱 Capturas de Pantalla

[Aquí irían las capturas de pantalla de la aplicación]

## 🧪 Tests

Para ejecutar los tests:
```bash
flutter test
```

## 🙏 Agradecimientos

- [Flutter](https://flutter.dev/) - Framework
- [Bloc Library](https://bloclibrary.dev/) - Gestión de estado
- [Audio Players](https://pub.dev/packages/audioplayers) - Efectos de sonido
- [Confetti](https://pub.dev/packages/confetti) - Efectos visuales

Link del proyecto: [https://github.com/MAGIN1104/pingPong](https://github.com/MAGIN1104/pingPong)
