import SwiftUI

struct UserListView: View {
    @StateObject var viewModel: UserListViewModel
    @State private var selectedUser: User?
    
    var body: some View {
        NavigationView {
            VStack {
                searchBar
                
                if viewModel.isLoading && viewModel.filteredUsers.isEmpty {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage, viewModel.filteredUsers.isEmpty {
                    errorView(message: errorMessage)
                } else if viewModel.isEmptyState || (viewModel.filteredUsers.isEmpty && viewModel.hasLoadedUsers) {
                    emptyResultsView
                } else {
                    userList
                }
            }
            .navigationTitle("users_title".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if viewModel.users.isEmpty {
                viewModel.loadSavedUsers()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("search_users".localized, text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
        }
        .padding(.horizontal)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("loading_users".localized)
            Spacer()
        }
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: viewModel.searchText.isEmpty ? "person.slash" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            if viewModel.searchText.isEmpty {
                LocalizedText("no_users_available")
                    .font(.headline)
                
                LocalizedText("try_loading_users")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                LocalizedText("no_results_found")
                    .font(.headline)
                
                LocalizedText("try_another_search")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                if viewModel.searchText.isEmpty {
                    viewModel.loadMoreUsers()
                } else {
                    viewModel.searchText = ""
                }
            }) {
                HStack {
                    Image(systemName: viewModel.searchText.isEmpty ? "arrow.clockwise" : "xmark.circle")
                    LocalizedText(viewModel.searchText.isEmpty ? "load_users" : "clear_search")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Spacer()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: viewModel.isNetworkError ? "wifi.exclamationmark" : "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
                .padding()
            
            Text(message)
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if viewModel.isNetworkError {
                LocalizedText("connection_problem")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: {
                viewModel.retryLoading()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    LocalizedText("retry")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            if !viewModel.users.isEmpty {
                Button(action: {
                    // Mostrar solo los usuarios guardados
                    viewModel.errorMessage = nil
                }) {
                    LocalizedText("continue_with_saved_users", arguments: viewModel.users.count)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
    }
    
    private var userList: some View {
        List {
            // Mostrar los usuarios
            ForEach(viewModel.filteredUsers) { user in
                NavigationLink(destination: 
                    UserDetailView(viewModel: viewModel.makeUserDetailViewModel(for: user))
                ) {
                    UserRowView(
                        user: user, 
                        onDelete: { _ in }, // No se usa con swipe
                        viewModel: viewModel
                    )
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        withAnimation {
                            viewModel.deleteUser(withID: user.id)
                        }
                    } label: {
                        Label("delete".localized, systemImage: "trash")
                    }
                }
                // Detector al llegar cerca del final de la lista
                .onAppear {
                    // Si este es uno de los últimos elementos, cargar más
                    let userIndex = viewModel.filteredUsers.firstIndex(where: { $0.id == user.id }) ?? 0
                    let threshold = max(0, viewModel.filteredUsers.count - 5)
                    
                    // Detectar si estamos cerca del final
                    if userIndex >= threshold && viewModel.searchText.isEmpty && !viewModel.isLoadingMoreUsers {
                        viewModel.loadMoreUsers(count: 40) // Load 40 users as indicated by the API
                    }
                }
            }
            
            // Indicador de carga al final
            if viewModel.isLoading && !viewModel.filteredUsers.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .id("LoadingIndicator")
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            // Pull to refresh - reiniciar y cargar usuarios nuevos
            viewModel.loadMoreUsers(count: 40) // Load 40 users as indicated by the API
        }
    }
} 