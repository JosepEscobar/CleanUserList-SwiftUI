import Foundation
import Combine

protocol UserListViewModelType: ObservableObject {
    // Propiedades publicadas
    var users: [User] { get }
    var filteredUsers: [User] { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var searchText: String { get set }
    
    // Acciones que puede realizar
    func loadMoreUsers(count: Int)
    func loadSavedUsers()
    func deleteUser(withID id: String)
    
    // Métodos para testing
    func reset()
}

class UserListViewModel: UserListViewModelType {
    // MARK: - Published Properties
    @Published var users: [User] = []
    @Published var filteredUsers: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""
    
    // MARK: - Dependencies
    private let getUsersUseCase: GetUsersUseCase
    private let getSavedUsersUseCase: GetSavedUsersUseCase
    private let deleteUserUseCase: DeleteUserUseCase
    private let searchUsersUseCase: SearchUsersUseCase
    private let scheduler: DispatchQueue
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    init(
        getUsersUseCase: GetUsersUseCase,
        getSavedUsersUseCase: GetSavedUsersUseCase,
        deleteUserUseCase: DeleteUserUseCase,
        searchUsersUseCase: SearchUsersUseCase,
        scheduler: DispatchQueue = .main
    ) {
        self.getUsersUseCase = getUsersUseCase
        self.getSavedUsersUseCase = getSavedUsersUseCase
        self.deleteUserUseCase = deleteUserUseCase
        self.searchUsersUseCase = searchUsersUseCase
        self.scheduler = scheduler
        
        setupSearchPublisher()
        loadSavedUsers()
    }
    
    // MARK: - Test Helpers
    func reset() {
        cancellables.removeAll()
        users = []
        filteredUsers = []
        isLoading = false
        errorMessage = nil
        searchText = ""
        setupSearchPublisher()
    }
    
    // MARK: - Private Methods
    private func setupSearchPublisher() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.searchUsers(query: query)
            }
            .store(in: &cancellables)
    }
    
    private func searchUsers(query: String) {
        if query.isEmpty {
            filteredUsers = users
            return
        }
        
        searchUsersUseCase.execute(query: query)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] users in
                    self?.filteredUsers = users
                }
            )
            .store(in: &cancellables)
    }
    
    private func applyFilter() {
        if searchText.isEmpty {
            filteredUsers = users
        } else {
            searchUsers(query: searchText)
        }
    }
    
    // MARK: - Public Methods
    func loadMoreUsers(count: Int = 20) {
        isLoading = true
        errorMessage = nil
        
        getUsersUseCase.execute(count: count)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] users in
                    guard let self = self else { return }
                    self.users.append(contentsOf: users)
                    self.applyFilter()
                }
            )
            .store(in: &cancellables)
    }
    
    func loadSavedUsers() {
        isLoading = true
        errorMessage = nil
        
        getSavedUsersUseCase.execute()
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] users in
                    guard let self = self else { return }
                    self.users = users
                    self.applyFilter()
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteUser(withID id: String) {
        deleteUserUseCase.execute(userID: id)
            .receive(on: scheduler)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] _ in
                    guard let self = self else { return }
                    self.users.removeAll { $0.id == id }
                    self.applyFilter()
                }
            )
            .store(in: &cancellables)
    }
} 