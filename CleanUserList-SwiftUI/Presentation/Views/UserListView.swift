import SwiftUI

struct UserListView: View {
    @StateObject private var viewModel: UserListViewModel
    @State private var searchText = ""
    @State private var isRefreshing = false
    
    private enum Constants {
        static let cornerRadius: CGFloat = 12
        static let shadowOpacity: Double = 0.05
        static let shadowRadius: CGFloat = 5
        static let shadowOffsetY: CGFloat = 2
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let topPadding: CGFloat = 8
        static let defaultLoadCount: Int = 20
        static let searchDelay: TimeInterval = 0.5
        static let listTopPadding: CGFloat = 16
    }
    
    init(viewModel: UserListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchBar
                    mainContent
                }
            }
        }
        .task {
            if !viewModel.hasLoadedUsers {
                await viewModel.loadInitialUsers()
            }
        }
    }
    
    private var searchBar: some View {
        SearchBarView(searchText: $searchText)
            .onChange(of: searchText) { oldValue, newValue in
                viewModel.searchText = newValue
            }
    }
    
    private var mainContent: some View {
        Group {
            if viewModel.isLoading && (!viewModel.hasLoadedUsers || viewModel.users.isEmpty) {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error: error)
            } else if viewModel.isEmptyState && viewModel.hasLoadedUsers {
                emptyStateView
            } else {
                userList
            }
        }
    }
    
    private var loadingView: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(error: String) -> some View {
        ErrorView(
            message: error,
            isNetworkError: viewModel.isNetworkError,
            savedUsersCount: viewModel.users.count,
            onRetry: {
                viewModel.retryLoading()
            },
            onContinueWithSaved: {
                viewModel.errorMessage = nil
            }
        )
    }
    
    private var emptyStateView: some View {
        EmptyStateView(
            isSearching: !searchText.isEmpty,
            onAction: {
                if !searchText.isEmpty {
                    searchText = ""
                } else {
                    Task {
                        await viewModel.loadMoreUsers(count: Constants.defaultLoadCount)
                    }
                }
            }
        )
    }
    
    private var userList: some View {
        List {
            ForEach(viewModel.filteredUsers) { user in
                NavigationLink(destination: UserDetailView(viewModel: viewModel.makeUserDetailViewModel(for: user))) {
                    UserRowView(
                        user: user,
                        onDelete: { _ in
                            // This callback is no longer needed as we use swipe-to-delete
                        },
                        viewModel: viewModel
                    )
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(
                    top: 8, 
                    leading: Constants.horizontalPadding, 
                    bottom: 8, 
                    trailing: Constants.horizontalPadding
                ))
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let user = viewModel.filteredUsers[index]
                    viewModel.deleteUser(withID: user.id)
                }
            }
            
            if viewModel.isLoadingMoreUsers {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                    .padding()
            } else if searchText.isEmpty {
                // Solo mostrar elemento de carga en modo lista normal (no búsqueda)
                LoadMoreButton {
                    if !viewModel.isLoadingMoreUsers {
                        Task {
                            await viewModel.loadMoreUsers(count: Constants.defaultLoadCount)
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .padding(.top, Constants.listTopPadding)
        .background(Color.white)
        .refreshable {
            isRefreshing = true
            await viewModel.loadMoreUsers(count: Constants.defaultLoadCount)
            isRefreshing = false
        }
    }
}

// Componente simple para cargar más datos al final de la lista
struct LoadMoreButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text("Cargar más")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                Spacer()
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
} 
