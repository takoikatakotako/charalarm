import SwiftUI

struct ContactView: View {
    @State var viewState: ContactViewState

    var body: some View {
        Form {
            Section(String(localized: "contact-user-id")) {
                Text(viewState.id)
                    .font(.footnote.monospaced())
                    .textSelection(.enabled)
            }

            Section(String(localized: "contact-email")) {
                TextField(String(localized: "contact-email"), text: $viewState.email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            Section(String(localized: "contact-message")) {
                TextEditor(text: $viewState.message)
                    .frame(minHeight: 240)
            }
        }
        .overlay {
            if viewState.showingIndicator {
                CharalarmActivityIndicator()
            }
        }
        .navigationTitle(String(localized: "config-contact"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(String(localized: "contact-send")) {
                    viewState.sendMessage()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            viewState.onAppear()
        }
        .alert(
            viewState.alertEntity?.title ?? "",
            isPresented: $viewState.showingAlert,
            presenting: viewState.alertEntity
        ) { entity in
            Button(entity.actionText) {}
        } message: { entity in
            Text(entity.message)
        }
    }
}

#Preview {
    NavigationStack {
        ContactView(viewState: ContactViewState())
    }
}
