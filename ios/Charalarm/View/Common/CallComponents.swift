import SwiftUI

/// 電話の画面の背景（着信・通話中で共通）
struct CallBackground: View {
    var body: some View {
        LinearGradient(colors: [Color(white: 0.22), Color(white: 0.06)], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

/// 電話に出る・切るの丸いボタン
struct CallActionButton: View {
    enum Kind {
        case answer
        case decline

        var systemImageName: String {
            switch self {
            case .answer: return "phone.fill"
            case .decline: return "phone.down.fill"
            }
        }

        var color: Color {
            switch self {
            case .answer: return Color(.callGreen)
            case .decline: return Color(.callRed)
            }
        }
    }

    let kind: Kind
    /// ボタンの直径
    var size: CGFloat = 76
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: kind.systemImageName)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(kind.color, in: Circle())
        }
        .accessibilityLabel(kind == .answer ? "answer" : "decline")
    }
}

/// 電話の相手の名前（着信・通話中で共通）
struct CallerNameText: View {
    let name: String
    var status: String?

    var body: some View {
        VStack(spacing: 8) {
            Text(name)
                .font(.system(size: 40, weight: .regular))
            if let status {
                Text(status)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
    }
}

#Preview {
    ZStack {
        CallBackground()
        VStack {
            CallerNameText(name: "ずんだもん", status: "着信")
            Spacer()
            HStack(spacing: 120) {
                CallActionButton(kind: .decline) {}
                CallActionButton(kind: .answer) {}
            }
        }
        .padding(.vertical, 80)
    }
}
