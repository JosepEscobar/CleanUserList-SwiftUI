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
        static let loadMoreThreshold: Int = 5
        static let defaultLoadCount: Int = 40
        static let searchDelay: TimeInterval = 0.5
    }
    
    init(viewModel: UserListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
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
        .onChange(of: viewModel.users.count) { oldCount, newCount in
            if newCount > Constants.loadMoreThreshold {
                viewModel.loadMoreUsers(count: Constants.defaultLoadCount)
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
        ScrollView {
            LazyVStack(spacing: Constants.verticalPadding) {
                ForEach(viewModel.filteredUsers) { user in
                    userRow(for: user)
                }
                
                if viewModel.isLoadingMoreUsers {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.top, Constants.topPadding)
        }
        .refreshable {
            isRefreshing = true
            viewModel.loadMoreUsers(count: Constants.defaultLoadCount)
            isRefreshing = false
        }
    }
    
    private func userRow(for user: User) -> some View {
        NavigationLink(destination: UserDetailView(viewModel: viewModel.makeUserDetailViewModel(for: user))) {
            UserRowView(
                user: user,
                onDelete: { _ in
                    viewModel.deleteUser(withID: user.id)
                },
                viewModel: viewModel
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
