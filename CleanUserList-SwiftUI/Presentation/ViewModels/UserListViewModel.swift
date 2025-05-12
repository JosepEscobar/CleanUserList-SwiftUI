@preconcurrency import Foundation
import SwiftUI

// Mark the protocol with @MainActor to make all its requirements compatible with the main actor
@MainActor
protocol UserListViewModelType: ObservableObject {
    // Published properties
    var users: [User] { get }
    var filteredUsers: [User] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var searchText: String { get set }
    var isNetworkError: Bool { get }
    var hasLoadedUsers: Bool { get }
    var isEmptyState: Bool { get }
    var isLoadingMoreUsers: Bool { get }
    var allUsersLoaded: Bool { get }
    
    // Actions that can be performed
    func loadMoreUsers(count: Int)
    func loadSavedUsers()
    func deleteUser(withID id: String)
    func retryLoading()
    func makeUserDetailViewModel(for user: User) -> UserDetailViewModel
    func loadImage(from url: URL) async throws -> Image
}

@MainActor
final class UserListViewModel: UserListViewModelType {
    private enum Constants {
        static let defaultUserCount = 10
        static let maxNetworkRetryAttempts = 3
        static let retryDelay: UInt64 = 3_000_000_000 // 3 seconds in nanoseconds
        static let searchDelay: UInt64 = 300_000_000 // 300ms in nanoseconds
        static let defaultLoadCount = 20
        
        enum ErrorMessages {
            static let connectionError = "Connection error. Please check your network and try again."
            static let showingSavedUsers = "Connection error. Showing saved users."
            static let tooManyAttempts = "Too many failed attempts. Users could not be loaded."
        }
    }
    
    // MARK: - Published Properties
    @Published var users: [User] = []
    @Published var filteredUsers: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchText: String = "" {
        didSet {
            if searchText.isEmpty {
                filteredUsers = users
            } else {
                searchUsers(query: searchText)
                
                // If we're searching, cancel any additional loading task
                loadMoreTask?.cancel()
                isLoadingMoreUsers = false
            }
        }
    }
    @Published var isNetworkError: Bool = false
    @Published var hasLoadedUsers: Bool = false
    @Published var isLoadingMoreUsers: Bool = false
    @Published var allUsersLoaded: Bool = false
    
    // MARK: - Dependencies
    private let getUsersUseCase: GetUsersUseCase
    private let getSavedUsersUseCase: GetSavedUsersUseCase
    private let deleteUserUseCase: DeleteUserUseCase
    private let searchUsersUseCase: SearchUsersUseCase
    private let loadImageUseCase: LoadImageUseCase
    
    // MARK: - Private Properties
    private var lastRequestedCount: Int = Constants.defaultUserCount
    private var networkRetryAttempts: Int = 0
    private var searchTask: Task<Void, Never>? = nil
    private var loadMoreTask: Task<Void, Never>? = nil
    
    // MARK: - Computed Properties
    var isEmptyState: Bool {
        return hasLoadedUsers && users.isEmpty && !isLoading && errorMessage == nil
    }
    
    // MARK: - Initializer
    init(
        getUsersUseCase: GetUsersUseCase,
        getSavedUsersUseCase: GetSavedUsersUseCase,
        deleteUserUseCase: DeleteUserUseCase,
        searchUsersUseCase: SearchUsersUseCase,
        loadImageUseCase: LoadImageUseCase
    ) {
        self.getUsersUseCase = getUsersUseCase
        self.getSavedUsersUseCase = getSavedUsersUseCase
        self.deleteUserUseCase = deleteUserUseCase
        self.searchUsersUseCase = searchUsersUseCase
        self.loadImageUseCase = loadImageUseCase
        
        // Load saved users first, correctly waiting for the asynchronous operation
        Task { [weak self] in
            guard let self = self else { return }
            await loadSavedUsersAsync()
        }
    }
    
    // MARK: - Factory Methods
    func makeUserDetailViewModel(for user: User) -> UserDetailViewModel {
        return UserDetailViewModel(user: user, loadImageUseCase: loadImageUseCase)
    }
    
    // MARK: - Image Loading
    func loadImage(from url: URL) async throws -> Image {
        // Capture the use case locally to avoid data races
        let useCase = self.loadImageUseCase
        return try await useCase.execute(from: url)
    }
    
    // MARK: - Private Methods
    private func searchUsers(query: String) {
        searchTask?.cancel()
        
        if query.isEmpty {
            filteredUsers = users
            return
        }
        
        searchTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                try await Task.sleep(nanoseconds: Constants.searchDelay)
                
                if !query.isEmpty {
                    isLoading = true
                }
                
                let results = try await searchUsersUseCase.execute(query: query)
                
                if !Task.isCancelled {
                    if query != searchText {
                        // Results discarded
                    } else {
                        self.filteredUsers = results
                    }
                }
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                }
            }
            
            isLoading = false
        }
    }
    
    private func applyFilter() {
        if searchText.isEmpty {
            filteredUsers = users
        } else {
            searchUsers(query: searchText)
        }
    }
    
    private func handleError(_ error: Error) {
        let isNetworkRelatedError = errorIsNetworkRelated(error)
        self.isNetworkError = isNetworkRelatedError
        
        if isNetworkRelatedError {
            errorMessage = Constants.ErrorMessages.connectionError
            
            if !users.isEmpty {
                errorMessage = Constants.ErrorMessages.showingSavedUsers
                
                Task { [weak self] in
                    guard let self = self else { return }
                    try? await Task.sleep(nanoseconds: Constants.retryDelay)
                    if self.errorMessage == Constants.ErrorMessages.showingSavedUsers {
                        self.errorMessage = nil
                    }
                }
            }
        } else {
            errorMessage = error.localizedDescription
        }
    }
    
    // Helper function to identify network errors
    private func errorIsNetworkRelated(_ error: Error) -> Bool {
        // Check specific API errors
        if let apiError = error as? APIError {
            return apiError == .networkError || 
                   apiError == .timeout || 
                   apiError == .serverError(statusCode: 503) || 
                   apiError == .unreachable
        }
        
        // Check URLError error codes
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            let networkErrorCodes: [Int] = [
                NSURLErrorTimedOut,
                NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorDNSLookupFailed,
                NSURLErrorNotConnectedToInternet,
                NSURLErrorInternationalRoamingOff,
                NSURLErrorCallIsActive
            ]
            return networkErrorCodes.contains(nsError.code)
        }
        
        return false
    }
    
    // MARK: - Public Methods
    func retryLoading() {
        networkRetryAttempts += 1
        
        if networkRetryAttempts > Constants.maxNetworkRetryAttempts {
            errorMessage = Constants.ErrorMessages.tooManyAttempts
            hasLoadedUsers = true
        } else {
            // Use the same simplified loading function
            loadMoreUsers(count: lastRequestedCount)
        }
    }
    
    func loadMoreUsers(count: Int = Constants.defaultLoadCount) {
        // Don't load more users if we're performing a search
        if !searchText.isEmpty {
            return
        }
        
        loadMoreTask?.cancel()
        
        loadMoreTask = Task { [weak self] in
            guard let self = self else { return }
            await loadMoreUsersAsync(count: count)
        }
    }
    
    private func loadMoreUsersAsync(count: Int = Constants.defaultLoadCount) async {
        guard !isLoadingMoreUsers else { return }
        
        isLoading = true
        isLoadingMoreUsers = true
        errorMessage = nil
        isNetworkError = false
        lastRequestedCount = count
        
        do {
            let newUsers = try await getUsersUseCase.execute(count: count)
            
            let existingIDs = Set(self.users.map { $0.id })
            let uniqueNewUsers = newUsers.filter { !existingIDs.contains($0.id) }
            
            if !uniqueNewUsers.isEmpty {
                self.users.append(contentsOf: uniqueNewUsers)
            }
            
            self.applyFilter()
            self.hasLoadedUsers = true
            
        } catch {
            self.networkRetryAttempts += 1
            self.handleError(error)
        }
        
        isLoading = false
        isLoadingMoreUsers = false
    }
    
    func loadSavedUsers() {
        Task { [weak self] in
            guard let self = self else { return }
            await loadSavedUsersAsync()
        }
    }
    
    private func loadSavedUsersAsync() async {
        isLoading = true
        errorMessage = nil
        isNetworkError = false
        
        do {
            let savedUsers = try await getSavedUsersUseCase.execute()
            
            self.users = savedUsers
            self.applyFilter()
            self.hasLoadedUsers = true
            
            if savedUsers.isEmpty {
                await loadMoreUsersAsync(count: Constants.defaultLoadCount)
            }
            
        } catch {
            self.handleError(error)
            
            await loadMoreUsersAsync(count: Constants.defaultLoadCount)
        }
        
        isLoading = false
    }
    
    func deleteUser(withID id: String) {
        Task { [weak self] in
            guard let self = self else { return }
            await deleteUserAsync(withID: id)
        }
    }
    
    private func deleteUserAsync(withID id: String) async {
        do {
            try await deleteUserUseCase.execute(userID: id)
            
            self.users.removeAll { $0.id == id }
            self.applyFilter()
            
        } catch {
            self.handleError(error)
        }
    }
} 
