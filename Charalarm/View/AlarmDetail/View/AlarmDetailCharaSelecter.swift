import SwiftUI
import SDWebImageSwiftUI

protocol AlarmDetailCharaSelecterDelegate {
    func setRandomChara()
    func showVoiceList(chara: Chara)
}

struct AlarmDetailCharaSelecter: View {
    var delegate: AlarmDetailCharaSelecterDelegate
    @Binding var selectedChara: Chara?
    @Binding var charas: [Chara]

    var body: some View {
        VStack(alignment: .leading) {
            Text("キャラクター")
                .font(Font.system(size: 16).bold())
            ScrollView(.horizontal, showsIndicators: false) {

                if charas.isEmpty {
                    Text("Loading")
                        .frame(height: 64)
                } else {
                    LazyHStack(spacing: 12) {
                        if let chara = selectedChara {
                            WebImage(url: URL(string: chara.thumbnailUrlString))
                                .resizable()
                                .frame(width: 64, height: 64)
                                .cornerRadius(10)
                        } else {
                            Text("?")
                                .frame(width: 64, height: 64)
                                .foregroundColor(Color.white)
                                .font(Font.system(size: 24).bold())
                                .background(Color(UIColor.lightGray))
                                .cornerRadius(10)
                        }

                        Button {
                            delegate.setRandomChara()
                        } label: {
                            Text("?")
                                .frame(width: 56, height: 56)
                                .foregroundColor(Color.white)
                                .font(Font.system(size: 24).bold())
                                .background(Color(UIColor.lightGray))
                                .cornerRadius(10)
                                .padding(.top, 8)
                        }

                        ForEach(charas) { chara in
                            Button {
                                delegate.showVoiceList(chara: chara)
                            } label: {
                                WebImage(url: URL(string: chara.thumbnailUrlString))
                                    .resizable()
                                    .frame(width: 56, height: 56)
                                    .cornerRadius(10)
                                    .padding(.top, 8)
                            }
                        }
                    }
                    .frame(height: 64)
                }
            }
        }
    }
}

// struct AlarmDetailCharaSelecter_Previews: PreviewProvider {
//    struct PreviewWrapper: View, AlarmDetailCharaSelecterDelegate {
//        @State var selectedChara: Character?
//        @State var charas: [Character] = [Character.mock()]
//
//        var body: some View {
//            AlarmDetailCharaSelecter(delegate: self, selectedChara: $selectedChara, charas: $charas)
//        }
//
//        func setRandomChara() {}
//        func showVoiceList(chara: Character) {}
//    }
//
//    static var previews: some View {
//        PreviewWrapper()
//            .previewLayout(.sizeThatFits)
//    }
// }
