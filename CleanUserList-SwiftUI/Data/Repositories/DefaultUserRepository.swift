import Foundation

@MainActor
class DefaultUserRepository: UserRepository {
    private let apiClient: APIClient
    private let userStorage: UserStorage
    private var lastRequestedCount: Int = 0
    private var retryCount: Int = 0
    private let maxRetries: Int = 3
    private var isFirstLoad: Bool = true
    
    init(apiClient: APIClient, userStorage: UserStorage) {
        self.apiClient = apiClient
        self.userStorage = userStorage
    }
    
    func getUsers(count: Int) async throws -> [User] {
        self.lastRequestedCount = count
        
        do {
            // Si es la primera carga y hay más de 20 usuarios solicitados, cargamos directamente de la API
            if isFirstLoad && count >= 20 {
                isFirstLoad = false
                // Intentar cargar directamente de la API para mayor velocidad inicial
                return try await fetchAndStoreMoreUsers(count: count)
            }
            
            // En cargas normales, primero verificamos si tenemos usuarios guardados
            let savedUsers = try await getSavedUsers()
            
            // Si hay usuarios guardados y son suficientes, los devolvemos inmediatamente
            // y actualizamos en segundo plano
            if !savedUsers.isEmpty && savedUsers.count >= count / 2 {
                // Actualizar en segundo plano solo si no es la primera carga
                Task {
                    do {
                        _ = try await fetchAndStoreMoreUsers(count: count)
                    } catch {
                        print("Error actualizando usuarios en segundo plano: \(error)")
                    }
                }
                return savedUsers
            }
            
            // Si no hay suficientes usuarios o es necesario cargar más
            isFirstLoad = false
            return try await fetchAndStoreMoreUsers(count: count)
        } catch {
            // Si hay algún error pero tenemos usuarios guardados, los devolvemos
            let savedUsers = try? await getSavedUsers()
            if let users = savedUsers, !users.isEmpty {
                return users
            }
            throw error
        }
    }
    
    private func fetchAndStoreMoreUsers(count: Int) async throws -> [User] {
        do {
            // Cargar con tiempo de timeout reducido en la primera carga para mayor reactividad
            let response = try await apiClient.getUsers(count: count)
            let newUsers = response.results.map { $0.toDomain() }
            
            // Guardar usuarios en una tarea separada para no bloquear la UI
            if !newUsers.isEmpty {
                Task {
                    do {
                        try await saveUsers(newUsers)
                    } catch {
                        print("Error guardando usuarios: \(error)")
                    }
                }
            }
            
            retryCount = 0 // Resetear el contador de reintentos
            return newUsers
        } catch let apiError as APIError {
            // Reintentar en caso de errores de red
            if case .networkError = apiError, retryCount < maxRetries {
                retryCount += 1
                // Esperar menos tiempo en el primer reintento para mayor reactividad
                let waitTime = isFirstLoad ? 
                    UInt64(1_000_000_000) : // 1 segundo si es primera carga
                    UInt64(pow(2.0, Double(retryCount)) * 1_000_000_000)
                    
                try await Task.sleep(nanoseconds: waitTime)
                return try await fetchAndStoreMoreUsers(count: count)
            }
            throw apiError
        } catch {
            throw error
        }
    }
    
    func saveUsers(_ users: [User]) async throws {
        try await userStorage.saveUsers(users)
    }
    
    func deleteUser(withID id: String) async throws {
        try await userStorage.deleteUser(withID: id)
    }
    
    func searchUsers(query: String) async throws -> [User] {
        let users = try await getSavedUsers()
        
        let lowercasedQuery = query.lowercased()
        return users.filter { user in
            user.fullName.lowercased().contains(lowercasedQuery) ||
            user.email.lowercased().contains(lowercasedQuery)
        }
    }
    
    func getSavedUsers() async throws -> [User] {
        return try await userStorage.getUsers()
    }
}

enum RepositoryError: Error {
    case unknown
} 