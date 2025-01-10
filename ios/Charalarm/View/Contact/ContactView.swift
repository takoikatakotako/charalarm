import SwiftUI

struct ContactView: View {
    @StateObject var viewState: ContactViewState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ユーザーID")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.appMainText))
                        Text(viewState.id)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color(.appMainText))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("メールアドレス")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.appMainText))
                        TextField("", text: $viewState.email)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color(.appMainText))
                            .padding(8)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("お問い合わせ内容")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(.appMainText))

                        ZStack {
                            TextEditor(text: $viewState.message)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color(.appMainText))
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(height: 300)
                                .padding(8)
                        }
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.top, 24)
                .padding(.horizontal, 16)
            }

            if viewState.showingIndicator {
                CharalarmActivityIndicator()
            }
        }
        .background(Color(.appBackground))
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(.appMain), for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .navigationBarItems(
            leading:
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 18, weight: .semibold))
                            .padding(.top, 4)
                            .padding(.trailing, 4)
                            .padding(.bottom, 4)
                            .foregroundStyle(Color.white)
                    }
                },
            trailing:
                HStack {
                    Button(action: {
                        viewState.sendMessage()
                    }) {
                        Text("送信")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .padding(4)
                    }
                }
        )
        .onAppear {
            viewState.onAppear()
        }
        .alert(
            viewState.alertEntity?.title ?? "",
            isPresented: $viewState.showingAlert,
            presenting: viewState.alertEntity
        ) { entity in
            Button(entity.actionText) {
                print(entity.actionText)
            }
        } message: { entity in
            Text(entity.message)
        }
    }
}

#Preview {
    NavigationView {
        ContactView(viewState: ContactViewState())
    }
}
