import SwiftUI

struct TopButtonContent: View {
    private let imageName: String?
    private let systemImageName: String?

    init(imageName: String) {
        self.imageName = imageName
        self.systemImageName = nil
    }

    /// SF Symbols のアイコン。アセットのアイコン（36pt）と大きさをそろえる。
    init(systemImageName: String) {
        self.imageName = nil
        self.systemImageName = systemImageName
    }

    var body: some View {
        Group {
            if let imageName {
                Image(imageName)
            } else if let systemImageName {
                Image(systemName: systemImageName)
                    .font(.system(size: 24))
                    .frame(width: 36, height: 36)
            }
        }
        .foregroundStyle(.white)
        .padding(8)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

#Preview {
    HStack {
        TopButtonContent(imageName: "top-news")
        TopButtonContent(systemImageName: "phone.fill")
    }
    .background(.gray)
}
