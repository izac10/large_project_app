📱 large_project_app

This is a multi-platform Flutter application developed during the Fall semester for COP4331C: Processes for Object-Oriented Software Development at the University of Central Florida (UCF). The app is designed using object-oriented principles and modern software engineering practices. It connects to a custom backend built specifically for this project.

🔗 Backend Integration

This mobile app is fully integrated with a dedicated backend API hosted in a separate repository:

Backend Repository:
https://github.com/pbayona9554/Large-Project

The backend provides the following capabilities:

• User and data management
• REST API endpoints for CRUD operations
• Database connectivity
• Authentication structures (depending on final implementation)
• Server-side validation and business logic

The mobile app communicates with the backend via HTTP requests, allowing real-time data handling and seamless interaction between frontend and server.

🚀 Overview

The goal of this project is to apply software development processes, documentation standards, and object-oriented concepts in a real-world style application. The project serves as a scalable foundation for a fully featured mobile system that can grow beyond the course requirements.

This Flutter-based structure supports multiple platforms including Android, iOS, web, and desktop environments.

🧩 Features

✔️ Cross-platform Flutter setup

✔️ Backend-connected architecture

✔️ Demonstrates object-oriented design and modular structure

✔️ Ready for UI screens, authentication, and database-driven workflows

✔️ Hot reload for rapid development

✔️ Clean and maintainable file layout

🛠️ Tech Stack
Frontend

Flutter

Dart

Backend

Custom API built for this project

Referenced repository: https://github.com/pbayona9554/Large-Project

Supported Platforms

Android

iOS

Web

Windows

macOS

Linux

📁 Project Structure
large_project_app/
│
├── lib/                 # Dart UI, services, and object-oriented logic
├── android/             # Android build files
├── ios/                 # iOS build files
├── web/                 # Web support
├── windows/             # Windows desktop support
├── macos/               # macOS support
├── linux/               # Linux support
│
├── pubspec.yaml         # App metadata, assets, and dependencies
└── README.md            # Project documentation

🔌 Connection to the Backend

The frontend communicates with the backend via REST API routes defined in the server repository. Typical interactions include:

GET /items
POST /login
POST /register
PUT /update/{id}
DELETE /remove/{id}


You can configure API URLs inside the Flutter service files located in:

lib/services/

▶️ Getting Started
Prerequisites

Flutter SDK

VS Code or Android Studio

Device emulator or physical device

Backend server running locally or hosted

Clone Frontend
git clone https://github.com/izac10/large_project_app
cd large_project_app
flutter pub get
flutter run

Clone Backend
git clone https://github.com/pbayona9554/Large-Project
cd Large-Project
npm install
npm start


Make sure your backend is running before testing API features in the app.
