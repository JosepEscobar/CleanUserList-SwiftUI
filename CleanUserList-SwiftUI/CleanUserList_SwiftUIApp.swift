//
//  CleanUserList_SwiftUIApp.swift
//  CleanUserList-SwiftUI
//
//  Created by Josep Escobar on 8/5/25.
//

import SwiftUI
import SwiftData

@main
struct CleanUserList_SwiftUIApp: App {
    let dependencyContainer = DependencyContainer()
    
    var body: some Scene {
        WindowGroup {
            UserListView(viewModel: dependencyContainer.makeUserListViewModel())
        }
        .modelContainer(for: [UserEntity.self])
    }
}

class DependencyContainer {
    // API
    private lazy var apiClient: APIClient = {
        return DefaultAPIClient()
    }()
    
    // Storage
    private lazy var userStorage: UserStorage = {
        do {
            // Usar SwiftData para persistencia
            return try SwiftDataStorage()
        } catch {
            // Fallback a UserDefaults si SwiftData falla
            print("Error initializing SwiftDataStorage: \(error.localizedDescription)")
            print("Falling back to UserDefaultsStorage")
            return UserDefaultsStorage()
        }
    }()
    
    // Repository
    private lazy var userRepository: UserRepository = {
        return DefaultUserRepository(apiClient: apiClient, userStorage: userStorage)
    }()
    
    // Use Cases
    private lazy var getUsersUseCase: GetUsersUseCase = {
        return DefaultGetUsersUseCase(repository: userRepository)
    }()
    
    private lazy var getSavedUsersUseCase: GetSavedUsersUseCase = {
        return DefaultGetSavedUsersUseCase(repository: userRepository)
    }()
    
    private lazy var deleteUserUseCase: DeleteUserUseCase = {
        return DefaultDeleteUserUseCase(repository: userRepository)
    }()
    
    private lazy var searchUsersUseCase: SearchUsersUseCase = {
        return DefaultSearchUsersUseCase(repository: userRepository)
    }()
    
    // View Models
    func makeUserListViewModel() -> UserListViewModel {
        return UserListViewModel(
            getUsersUseCase: getUsersUseCase,
            getSavedUsersUseCase: getSavedUsersUseCase,
            deleteUserUseCase: deleteUserUseCase,
            searchUsersUseCase: searchUsersUseCase
        )
    }
    
    func makeUserDetailViewModel(user: User) -> UserDetailViewModel {
        return UserDetailViewModel(user: user)
    }
}
