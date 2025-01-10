import SwiftUI

struct AlarmDetailTimeDeffarenceSelecter: View {
    @Binding var timeDeffarence: Decimal
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    private let cityList: [TimeDifference] = [
        TimeDifference(city: "ロンドン", timeDifference: 0),
        TimeDifference(city: "マドリード", timeDifference: 1),
        TimeDifference(city: "パリ", timeDifference: 1),
        TimeDifference(city: "ローマ", timeDifference: 1),
        TimeDifference(city: "ベルリン", timeDifference: 1),
        TimeDifference(city: "カイロ", timeDifference: 2),
        TimeDifference(city: "アテネ", timeDifference: 2),
        TimeDifference(city: "ヨハネスブルグ", timeDifference: 2),
        TimeDifference(city: "リヤド", timeDifference: 3),
        TimeDifference(city: "テヘラン", timeDifference: 3.5),
        TimeDifference(city: "ドバイ", timeDifference: 4),
        TimeDifference(city: "カブール", timeDifference: 4.5),
        TimeDifference(city: "カラチ", timeDifference: 5),
        TimeDifference(city: "デリー", timeDifference: 5.5),
        TimeDifference(city: "ダッカ", timeDifference: 6),
        TimeDifference(city: "ヤンゴン", timeDifference: 6.5),
        TimeDifference(city: "バンコク", timeDifference: 7),
        TimeDifference(city: "シンガポール", timeDifference: 8),
        TimeDifference(city: "香港", timeDifference: 8),
        TimeDifference(city: "北京", timeDifference: 8),
        TimeDifference(city: "台北", timeDifference: 8),
        TimeDifference(city: "東京", timeDifference: 9),
        TimeDifference(city: "ソウル", timeDifference: 9)
    ]

    var body: some View {
        List(cityList) { city in
            Button {
                timeDeffarence = city.timeDifference
                presentationMode.wrappedValue.dismiss()
            } label: {
                VStack(alignment: .leading) {
                    Text(city.city)
                    Text(city.title)
                }
            }
        }
    }
}

struct TimeDifference: Identifiable {
    var id: String {
        return city
    }

    var title: String {
        let op: String = (timeDifference >= 0) ? "+" : "-"
        return "GMT \(op) \(abs(timeDifference))"
    }

    let city: String
    let timeDifference: Decimal
}
