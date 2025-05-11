//
//  CleanUserList_SwiftUIApp.swift
//  CleanUserList-SwiftUI
//
//  Created by Josep Escobar on 8/5/25.
//

import SwiftUI
import SwiftData
import Kingfisher

@main
struct CleanUserList_SwiftUIApp: App {
    let dependencyContainer = DependencyContainer()
    
    init() {
        // Configurar Kingfisher al iniciar la aplicación
        UserAsyncImageView.configureKingfisher()
        
        // Configurar el color de acento global
        UINavigationBar.appearance().tintColor = UIColor.systemGray
    }
    
    var body: some Scene {
        WindowGroup {
            // Vista principal sin LocalizedView envolvente
            UserListView(viewModel: makeViewModel())
                .accentColor(Color(UIColor.systemGray))
        }
        .modelContainer(for: [UserEntity.self], inMemory: false)
    }
    
    // Method marked with @MainActor to initialize the ViewModel
    @MainActor
    private func makeViewModel() -> UserListViewModel {
        return dependencyContainer.makeUserListViewModel()
    }
}

// Add the DependencyProvider definition before DependencyContainer
class DependencyProvider {
    let loadImageUseCase: LoadImageUseCase
    
    init(loadImageUseCase: LoadImageUseCase) {
        self.loadImageUseCase = loadImageUseCase
    }
}

@MainActor
class DependencyContainer {
    // URLSession configured for better network handling
    private lazy var configuredSession: URLSession = {
        return NetworkConfiguration.configureURLSession()
    }()
    
    // API
    private lazy var apiClient: APIClient = {
        return DefaultAPIClient()
    }()
    
    // Storage - Using only SwiftData
    @MainActor
    private lazy var userStorage: UserStorage = {
        do {
            let storage = try SwiftDataStorage()
            return storage
        } catch {
            // In case of error, we throw a fatalError since we need storage
            fatalError("Critical error initializing SwiftDataStorage: \(error.localizedDescription)")
        }
    }()
    
    // Repository
    @MainActor
    private lazy var userRepository: UserRepository = {
        return DefaultUserRepository(apiClient: apiClient, userStorage: userStorage)
    }()
    
    // Use Cases
    @MainActor
    private lazy var getUsersUseCase: GetUsersUseCase = {
        return DefaultGetUsersUseCase(repository: userRepository)
    }()
    
    @MainActor
    private lazy var getSavedUsersUseCase: GetSavedUsersUseCase = {
        return DefaultGetSavedUsersUseCase(repository: userRepository)
    }()
    
    @MainActor
    private lazy var deleteUserUseCase: DeleteUserUseCase = {
        return DefaultDeleteUserUseCase(repository: userRepository)
    }()
    
    @MainActor
    private lazy var searchUsersUseCase: SearchUsersUseCase = {
        return DefaultSearchUsersUseCase(repository: userRepository)
    }()
    
    private lazy var loadImageUseCase: LoadImageUseCase = {
        return DefaultLoadImageUseCase()
    }()
    
    // Dependency Provider - For access to dependencies from any view
    lazy var dependencyProvider: DependencyProvider = {
        return DependencyProvider(loadImageUseCase: loadImageUseCase)
    }()
    
    // View Models
    @MainActor
    func makeUserListViewModel() -> UserListViewModel {
        return UserListViewModel(
            getUsersUseCase: getUsersUseCase,
            getSavedUsersUseCase: getSavedUsersUseCase,
            deleteUserUseCase: deleteUserUseCase,
            searchUsersUseCase: searchUsersUseCase,
            loadImageUseCase: loadImageUseCase
        )
    }
    
    @MainActor
    func makeUserDetailViewModel(user: User) -> UserDetailViewModel {
        // Initialize the viewModel safely using RuntimeWarning instead of error
        let viewModel = UserDetailViewModel(user: user, loadImageUseCase: loadImageUseCase)
        return viewModel
    }
}
