# CleanUserList-SwiftUI

A modern iOS application that displays and manages a list of users with a clean architecture approach, following best practices in Swift and SwiftUI development.

## Architecture

This project implements a Clean Architecture pattern, which separates the code into distinct layers with clear responsibilities:

### Domain Layer

The core of the application, containing:
- **Entities**: Business models (User, Location, Picture)
- **Use Cases**: Application-specific business rules that orchestrate the flow of data
- **Repository Interfaces**: Abstraction for data operations

### Data Layer

Handles data management:
- **Repositories**: Implementation of the repository interfaces defined in the domain layer
- **Network**: APIClient for fetching data from remote sources
- **Storage**: Local persistence using SwiftData

### Presentation Layer

UI components and logic:
- **ViewModels**: Prepare and manage data for the UI
- **Views**: SwiftUI components for rendering the user interface

## Technical Features

### Modern Swift Patterns

- **Async/Await**: Used throughout the application for asynchronous operations
- **Protocol-Oriented Programming**: Heavy use of protocols for dependency injection and testability
- **Structured Concurrency**: Tasks and task management for async operations

### Error Handling

- Comprehensive error handling throughout all layers
- Network error detection and recovery mechanisms
- User-friendly error states in the UI

### Data Persistence

- SwiftData for local storage
- Offline support with local caching of network responses

### Network Layer

- Retry mechanisms for failed API requests
- Response caching
- Custom error handling

### Testing

- Comprehensive unit tests for all layers
- Mock implementations for testing dependencies
- Async test support

## Project Structure

```
CleanUserList-SwiftUI/
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   └── Repositories/
├── Data/
│   ├── Repositories/
│   ├── Network/
│   └── Storage/
├── Presentation/
│   ├── ViewModels/
│   └── Views/
└── Tests/
    ├── Domain/
    ├── Data/
    └── Presentation/
```

## Development Process

The project was developed following a test-driven approach, with a focus on:

1. Clean, maintainable code
2. Separation of concerns
3. Dependency injection for testability
4. Proper error handling

## Requirements

- iOS 16.0+
- Xcode 14.0+
- Swift 6+ 