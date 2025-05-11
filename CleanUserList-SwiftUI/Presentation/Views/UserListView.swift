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
        static let loadMoreThreshold: Int = 3
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
        .onAppear {
            viewModel.loadSavedUsers()
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
            if viewModel.isLoading && viewModel.users.isEmpty {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(error: error)
            } else if viewModel.isEmptyState {
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
                    viewModel.loadMoreUsers(count: Constants.defaultLoadCount)
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
                            // Este callback ya no es necesario ya que usamos swipe-to-delete
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
                .onAppear {
                    // Cargar más usuarios cuando el usuario llega a uno de los últimos elementos
                    if user.id == viewModel.filteredUsers.suffix(Constants.loadMoreThreshold).first?.id {
                        viewModel.loadMoreUsers(count: Constants.defaultLoadCount)
                    }
                }
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
            }
        }
        .listStyle(.plain)
        .padding(.top, Constants.listTopPadding)
        .background(Color.white)
        .refreshable {
            isRefreshing = true
            viewModel.loadMoreUsers(count: Constants.defaultLoadCount)
            isRefreshing = false
        }
    }
} 
