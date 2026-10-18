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
                VStack {
                    Text("ずんだもん")
                        .foregroundStyle(Color.white)
                        .font(Font.system(size: 48))
                        .padding(.top, 156)
                    Spacer()
                    HStack {
                        VStack {
                            NavigationLink(destination: TutorialThirdView()) {
                                Image(.profileCallEnd)
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .padding(16)
                                    .background(Color.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                            }
                        }

                        Spacer()

                        VStack {
                            Button(action: {
                                viewState.callButtonTapped()
                            }) {
                                Image(.profileCall)
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .padding(16)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 32))
                            }
                        }
                    }
                    .padding(.horizontal, 64)
                    .padding(.bottom, 32)
                }
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .background(Color(.charalarmDefaultGray))
            }

            if viewState.showingNextButton {
                NavigationLink(
                    destination: TutorialThirdView(),
                    label: {
                        TutorialButtonContent(text: String(localized: "common-next"))
                            .padding(.horizontal, 16)
                    })
                    .padding(.bottom, 28)
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
