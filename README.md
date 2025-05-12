# CleanUserList-SwiftUI

![Swift](https://img.shields.io/badge/Swift-6-orange)
![iOS](https://img.shields.io/badge/iOS-18.4+-blue)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4-green)
![SwiftData](https://img.shields.io/badge/SwiftData-1-purple)
![Xcode](https://img.shields.io/badge/Xcode-16-blue)
![License](https://img.shields.io/badge/License-MIT-lightgrey)
![Architecture](https://img.shields.io/badge/Architecture-Clean+MVVM-yellow)

<p align="left">
  <img src="https://img.shields.io/badge/Tests-Passing-brightgreen" />
  <img src="https://img.shields.io/badge/Coverage-60%25-yellow" />
</p>

---

A modern iOS application that displays and manages a list of users with Clean Architecture, showcasing best practices in Swift and SwiftUI development. This project demonstrates how to build a maintainable, scalable, and testable iOS application with modern Swift features.

## 📋 Features

- **User List Management**: Display, search, and delete users
- **Offline Support**: Works without internet connection using SwiftData
- **Modern UI**: Built with SwiftUI with smooth animations and transitions
- **Clean Architecture**: Clear separation of concerns with domain-driven design
- **Comprehensive Testing**: Extensive unit tests with high coverage
- **Error Handling**: Robust error management with user-friendly feedback
- **Async/Await**: Modern concurrency implementation

## 🏗️ Architecture

The project implements Clean Architecture with MVVM pattern across three distinct layers:

### 🧠 Domain Layer

The core business logic layer that is independent of any framework:

- **Entities**: Core business models (User, Location, Picture)
- **Use Cases**: Application-specific business rules
- **Repository Interfaces**: Abstract definitions for data operations

### 💾 Data Layer

Handles all data operations through:

- **Repositories**: Implementations of domain repositories
- **Network**: API client with retry mechanisms and error handling
- **Storage**: Local persistence through SwiftData

### 🖼️ Presentation Layer

The UI components and view logic following MVVM pattern:

- **ViewModels**: Prepare and manage data for views using MVVM pattern
- **Views**: SwiftUI components with reactive updates
- **Components**: Reusable UI elements

## 🔧 Technical Details

### Dependencies

- **SwiftUI**: Framework for building user interfaces
- **SwiftData**: Persistence framework for local storage
- **Kingfisher**: Image loading and caching library
- **Nimble**: Matcher framework for expressive unit tests

### Modern Swift Patterns

- **MVVM**: Model-View-ViewModel pattern for UI implementation
- **Async/Await**: Used throughout for asynchronous operations
- **Actors**: For thread-safe state management
- **Dependency Injection**: For better testability
- **Protocol-Oriented Programming**: For flexibility and abstraction
- **Property Wrappers**: For cleaner state management

### SwiftData Integration

The app leverages Apple's modern persistence framework:

- Model container configuration for clean schema management
- TransactionContext for controlled data operations
- Optimized query descriptors with indexing for performance
- External storage attributes for efficient data handling

## 🧪 Testing Strategy

The project includes comprehensive test coverage:

- **Unit Tests**: For all business logic and use cases
- **Repository Tests**: For data layer operations
- **ViewModel Tests**: For presentation logic
- **Mock Objects**: For isolated component testing
- **Async Testing**: Custom extensions for testing asynchronous code

## 🚀 Getting Started

### Requirements

- iOS 18.4+
- Xcode 16.0+
- Swift 6+

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/CleanUserList-SwiftUI.git
```

2. Open the project in Xcode
```bash
cd CleanUserList-SwiftUI
open CleanUserList-SwiftUI.xcodeproj
```

3. Build and run the application

## 📝 Project Structure

```
CleanUserList-SwiftUI/
├── Domain/
│   ├── Models/
│   ├── UseCases/
│   ├── Protocols/
│   └── Repositories/
├── Data/
│   ├── Network/
│   │   └── APIClient
│   ├── PersistentStorage/
│   │   └── SwiftData/
│   ├── DTOs
│   └── Repositories/
├── Presentation/
│   ├── ViewModels/
│   ├── Views/
│   ├── Components/
│   └── Utilities/
└── Tests/
    ├── Domain/
    ├── Data/
    └── Presentation/
```


## 📜 License

This project is [MIT](LICENSE) licensed.

## 👏 Acknowledgements

- [RandomUser API](https://randomuser.me/) - For providing the user data
- [Apple Documentation](https://developer.apple.com/documentation/) - For comprehensive SwiftUI and SwiftData documentation
- [Kingfisher](https://github.com/onevcat/Kingfisher) - For efficient image handling
- [Nimble](https://github.com/Quick/Nimble) - For expressive test assertions 