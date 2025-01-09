import Foundation

enum AlarmDetailViewSheetItem: Identifiable, Hashable {
    var id: Self {
        return self
    }

    case timeDeffarenceList
    case voiceList(Chara)
}
