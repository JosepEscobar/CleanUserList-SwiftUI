import SwiftUI

struct UserDetailView: View {
    @ObservedObject var viewModel: UserDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                AsyncImage(url: viewModel.pictureURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 150, height: 150)
                .clipShape(Circle())
                .shadow(radius: 5)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 16) {
                    detailRow(icon: "person.fill", title: "Nombre", value: viewModel.name)
                    detailRow(icon: "envelope.fill", title: "Email", value: viewModel.email)
                    detailRow(icon: "phone.fill", title: "Teléfono", value: viewModel.phone)
                    detailRow(icon: "figure.wave", title: "Género", value: viewModel.gender)
                    detailRow(icon: "mappin.and.ellipse", title: "Dirección", value: viewModel.location)
                    detailRow(icon: "calendar", title: "Fecha de registro", value: viewModel.registeredDate)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                )
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Detalle del usuario")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
    }
} 