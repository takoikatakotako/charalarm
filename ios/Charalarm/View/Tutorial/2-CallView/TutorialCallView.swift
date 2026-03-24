import SwiftUI

struct TutorialCallView: View {
    @State var viewModel = TutorialCallViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Spacer()
                Image(R.image.zundamonSmile.name)
                    .resizable()
                    .scaledToFit()
                    .padding(.top, 60)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }

            if viewModel.isCalling {
                VStack {
                    Text("ずんだもん")
                        .foregroundStyle(Color.white)
                        .font(Font.system(size: 48))
                        .padding(.top, 156)
                    Spacer()
                    HStack {
                        VStack {
                            NavigationLink(destination: TutorialThirdView()) {
                                Image(R.image.profileCallEnd.name)
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
                                viewModel.callButtonTapped()
                            }) {
                                Image(R.image.profileCall.name)
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
                .background(Color(R.color.charalarmDefaultGray.name))
            }

            if viewModel.showingNextButton {
                NavigationLink(
                    destination: TutorialThirdView(),
                    label: {
                        TutorialButtonContent(text: String(localized: "commo-next"))
                            .padding(.horizontal, 16)
                    })
                    .padding(.bottom, 28)
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .ignoresSafeArea()
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    TutorialCallView()
}
