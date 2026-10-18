import SwiftUI

struct TutorialCallView: View {
    @State var viewState = TutorialCallViewState()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                Image(.zundamonSmile)
                    .resizable()
                    .scaledToFit()
                    .padding(.top, 60)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }

            if viewState.isCalling {
                ZStack {
                    CallBackground()
                    VStack {
                        CallerNameText(name: "ずんだもん")
                            .padding(.top, 120)
                        Spacer()
                        HStack {
                            NavigationLink {
                                TutorialThirdView()
                            } label: {
                                Image(systemName: "phone.down.fill")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 76, height: 76)
                                    .background(Color(.callRed), in: Circle())
                            }
                            Spacer()
                            CallActionButton(kind: .answer) {
                                viewState.callButtonTapped()
                            }
                        }
                        .padding(.horizontal, 56)
                        .padding(.bottom, 64)
                    }
                }
                .transition(.opacity)
            }

            if viewState.showingNextButton {
                NavigationLink(
                    destination: TutorialThirdView(),
                    label: {
                        TutorialButtonContent(text: String(localized: "common-next"))
                            .padding(.horizontal, 16)
                    })
                    .padding(.bottom, 44)
            }
        }
        .onAppear {
            viewState.onAppear()
        }
        .onDisappear {
            viewState.onDisappear()
        }
        .ignoresSafeArea()
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    TutorialCallView()
}
