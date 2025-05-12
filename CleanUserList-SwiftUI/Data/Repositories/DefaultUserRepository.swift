import Foundation

@MainActor
class DefaultUserRepository: UserRepository {
    private enum Constants {
        static let maxRetries: Int = 3
        static let minUserCountForDirectAPILoad: Int = 20
        static let oneSecondInNanoseconds: UInt64 = 1_000_000_000
        static let userCountThresholdRatio: Int = 2 // divisor for sufficient users count (count/2)
        static let loadThreshold: Int = 8 // Cuántos elementos antes del final para cargar más
    }
    
    private let apiClient: APIClient
    private let userStorage: UserStorage
    private var lastRequestedCount: Int = 0
    private var retryCount: Int = 0
    private var isFirstLoad: Bool = true
    private var cachedUsers: [User] = []
    private var backgroundUpdateTask: Task<Void, Never>? = nil
    
    init(apiClient: APIClient, userStorage: UserStorage) {
        self.apiClient = apiClient
        self.userStorage = userStorage
    }
    
    // Método principal para carga inicial
    func getUsers(count: Int) async throws -> [User] {
        self.lastRequestedCount = count
        
        // Primero verificamos si tenemos datos en memoria
        if !cachedUsers.isEmpty && cachedUsers.count >= count / Constants.userCountThresholdRatio {
            // Si tenemos datos en memoria suficientes, los devolvemos inmediatamente
            // y actualizamos en segundo plano
            startBackgroundUpdate(count: count)
            return cachedUsers
        }
        
        // Si no hay suficientes en memoria, verificamos SwiftData
        let savedUsers = try await getSavedUsers()
        
        if !savedUsers.isEmpty && savedUsers.count >= count / Constants.userCountThresholdRatio {
            // Si tenemos suficientes en SwiftData, los devolvemos y actualizamos en memoria
            self.cachedUsers = savedUsers
            // Actualizamos en segundo plano
            startBackgroundUpdate(count: count)
            return savedUsers
        }
        
        // Si no hay suficientes datos en caché, cargamos de la API
        isFirstLoad = false
        let newUsers = try await fetchAndStoreMoreUsers(count: count)
        return newUsers
    }
    
    // Método para paginación - siempre carga desde la API
    func loadMoreUsers(count: Int) async throws -> [User] {
        // Siempre cargamos desde la API para paginación
        let newUsers = try await fetchAndStoreMoreUsers(count: count)
        return newUsers
    }
    
    // Método para verificar si debemos cargar más contenido (para UI)
    func shouldLoadMore(currentIndex: Int, totalCount: Int) -> Bool {
        let threshold = totalCount - Constants.loadThreshold
        return currentIndex >= threshold
    }
    
    // Inicia una actualización en segundo plano sin bloquear
    private func startBackgroundUpdate(count: Int) {
        // Cancelar tarea anterior si existe
        backgroundUpdateTask?.cancel()
        
        backgroundUpdateTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                // No esperamos el resultado ya que es background
                _ = try await fetchAndStoreMoreUsers(count: count)
            } catch {
                // Solo registramos el error sin propagarlo al usuario
                print("Error en actualización en segundo plano: \(error)")
            }
        }
    }
    
    private func fetchAndStoreMoreUsers(count: Int) async throws -> [User] {
        do {
            // Load with reduced timeout for the first load for better reactivity
            let response = try await apiClient.getUsersWithRetry(count: count)
            
            // Obtener el orden máximo actual de los usuarios
            let savedUsers = try? await getSavedUsers()
            let maxOrder = savedUsers?.map { $0.order }.max() ?? -1
            
            // Asignar orden secuencial a los nuevos usuarios preservando su orden
            var newUsers = [User]()
            for (index, userDTO) in response.results.enumerated() {
                // Convertir a dominio pero manteniendo el orden
                var user = userDTO.toDomain()
                // Recreamos el usuario para asignarle un orden
                user = User(
                    id: user.id,
                    name: user.name,
                    surname: user.surname,
                    fullName: user.fullName,
                    email: user.email,
                    phone: user.phone,
                    gender: user.gender,
                    location: user.location,
                    registeredDate: user.registeredDate,
                    picture: user.picture,
                    order: maxOrder + 1 + index // Asignamos orden consecutivo
                )
                newUsers.append(user)
            }
            
            // Actualizar la caché en memoria
            if !newUsers.isEmpty {
                // Añadir solo usuarios únicos a la caché
                let existingIDs = Set(self.cachedUsers.map { $0.id })
                let uniqueNewUsers = newUsers.filter { !existingIDs.contains($0.id) }
                
                if !uniqueNewUsers.isEmpty {
                    self.cachedUsers.append(contentsOf: uniqueNewUsers)
                    
                    // Guardar en SwiftData en segundo plano
                    Task {
                        do {
                            try await saveUsers(uniqueNewUsers)
                        } catch {
                            print("Error saving users: \(error)")
                        }
                    }
                }
            }
            
            retryCount = 0 // Reset the retry counter
            return newUsers
        } catch let apiError as APIError {
            // Retry in case of network errors
            if case .networkError = apiError, retryCount < Constants.maxRetries {
                retryCount += 1
                // Wait less time on the first retry for better reactivity
                let waitTime = isFirstLoad ? 
                    Constants.oneSecondInNanoseconds : // 1 second if it's the first load
                    UInt64(pow(2.0, Double(retryCount)) * Double(Constants.oneSecondInNanoseconds))
                    
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
        // También eliminar de la caché en memoria
        cachedUsers.removeAll { $0.id == id }
    }
    
    func searchUsers(query: String) async throws -> [User] {
        // Primero intentamos buscar en la caché en memoria
        if !cachedUsers.isEmpty {
            let lowercasedQuery = query.lowercased()
            let results = cachedUsers.filter { user in
                user.fullName.lowercased().contains(lowercasedQuery) ||
                user.email.lowercased().contains(lowercasedQuery)
            }
            
            if !results.isEmpty {
                return results
            }
        }
        
        // Si no hay resultados en memoria, buscamos en SwiftData
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
