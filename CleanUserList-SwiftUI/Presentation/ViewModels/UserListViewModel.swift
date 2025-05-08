import Foundation
import Combine

class UserListViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var filteredUsers: [User] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""
    
    private let getUsersUseCase: GetUsersUseCase
    private let getSavedUsersUseCase: GetSavedUsersUseCase
    private let deleteUserUseCase: DeleteUserUseCase
    private let searchUsersUseCase: SearchUsersUseCase
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        getUsersUseCase: GetUsersUseCase,
        getSavedUsersUseCase: GetSavedUsersUseCase,
        deleteUserUseCase: DeleteUserUseCase,
        searchUsersUseCase: SearchUsersUseCase
    ) {
        self.getUsersUseCase = getUsersUseCase
        self.getSavedUsersUseCase = getSavedUsersUseCase
        self.deleteUserUseCase = deleteUserUseCase
        self.searchUsersUseCase = searchUsersUseCase
        
        setupSearchPublisher()
        loadSavedUsers()
    }
    
    private func setupSearchPublisher() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.searchUsers(query: query)
            }
            .store(in: &cancellables)
    }
    
    func loadMoreUsers(count: Int = 20) {
        isLoading = true
        errorMessage = nil
        
        getUsersUseCase.execute(count: count)
            .receive(on: DispatchQueue.main)
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
            .receive(on: DispatchQueue.main)
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
            .receive(on: DispatchQueue.main)
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
    
    private func searchUsers(query: String) {
        if query.isEmpty {
            filteredUsers = users
            return
        }
        
        searchUsersUseCase.execute(query: query)
            .receive(on: DispatchQueue.main)
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
} 