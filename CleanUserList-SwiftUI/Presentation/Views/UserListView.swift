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
        static let mainStackSpacing: CGFloat = 0
        static let loadingScale: CGFloat = 1.5
        static let rowVerticalPadding: CGFloat = 4
        static let rowTopInset: CGFloat = 8
        static let rowBottomInset: CGFloat = 8
        static let infiniteScrollTriggerHeight: CGFloat = 20
        static let defaultBottomColor = Color.white
    }
    
    init(viewModel: UserListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Constants.defaultBottomColor
                    .ignoresSafeArea()
                
                VStack(spacing: Constants.mainStackSpacing) {
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
            .scaleEffect(Constants.loadingScale)
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
                    .padding(.vertical, Constants.rowVerticalPadding)
                }
                .listRowInsets(EdgeInsets(
                    top: Constants.rowTopInset, 
                    leading: Constants.horizontalPadding, 
                    bottom: Constants.rowBottomInset, 
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
            } else if searchText.isEmpty && !viewModel.allUsersLoaded {
                // Invisible element to trigger loading on infinite scroll
                Color.clear
                    .frame(height: Constants.infiniteScrollTriggerHeight)
                    .listRowSeparator(.hidden)
                    .onAppear {
                        if !viewModel.isLoadingMoreUsers {
                            Task {
                                await viewModel.loadMoreUsers(count: Constants.defaultLoadCount)
                            }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .padding(.top, Constants.listTopPadding)
        .background(Constants.defaultBottomColor)
        .refreshable {
            isRefreshing = true
            await viewModel.loadMoreUsers(count: Constants.defaultLoadCount)
            isRefreshing = false
        }
    }
} 
