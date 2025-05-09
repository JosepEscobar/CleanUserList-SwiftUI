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
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))
            
            TextField("search_users".localized, text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .disableAutocorrection(true)
                .font(.system(size: 16))
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
                .transition(.opacity)
                .animation(.easeInOut, value: viewModel.searchText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.top, 8)
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
                    // Show only saved users
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
            // Show users
            ForEach(viewModel.filteredUsers) { user in
                NavigationLink(destination: 
                    UserDetailView(viewModel: viewModel.makeUserDetailViewModel(for: user))
                ) {
                    UserRowView(
                        user: user, 
                        onDelete: { _ in }, // Not used with swipe
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
                // Detector when reaching near the end of the list
                .onAppear {
                    // If this is one of the last elements, load more
                    let userIndex = viewModel.filteredUsers.firstIndex(where: { $0.id == user.id }) ?? 0
                    let threshold = max(0, viewModel.filteredUsers.count - 5)
                    
                    // Detect if we're near the end
                    if userIndex >= threshold && viewModel.searchText.isEmpty && !viewModel.isLoadingMoreUsers {
                        viewModel.loadMoreUsers(count: 40) // Load 40 users as indicated by the API
                    }
                }
            }
            
            // Loading indicator at the end
            if viewModel.isLoading && !viewModel.filteredUsers.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .id("LoadingIndicator")
            }
        }
        .listStyle(PlainListStyle())
        .refreshable {
            // Pull to refresh - reset and load new users
            viewModel.loadMoreUsers(count: 40) // Load 40 users as indicated by the API
        }
    }
} 