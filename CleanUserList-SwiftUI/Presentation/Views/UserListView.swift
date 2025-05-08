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
                } else {
                    userList
                }
            }
            .navigationTitle("Usuarios")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if viewModel.users.isEmpty {
                viewModel.loadMoreUsers()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Buscar usuarios", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
        }
        .padding(.horizontal)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Cargando usuarios...")
            Spacer()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack {
            Spacer()
            Text("Error: \(message)")
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Reintentar") {
                viewModel.loadMoreUsers()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    private var userList: some View {
        List {
            ForEach(viewModel.filteredUsers) { user in
                NavigationLink(destination: UserDetailView(viewModel: UserDetailViewModel(user: user))) {
                    UserRowView(user: user, onDelete: { id in
                        viewModel.deleteUser(withID: id)
                    })
                }
            }
            
            if !viewModel.isLoading && !viewModel.filteredUsers.isEmpty {
                Button("Cargar más usuarios") {
                    viewModel.loadMoreUsers()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .onAppear {
                    viewModel.loadMoreUsers()
                }
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            }
        }
        .listStyle(PlainListStyle())
    }
} 