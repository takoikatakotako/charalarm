import Foundation

enum AlarmDetailViewSheetItem: Identifiable, Hashable {
    var id: Self {
        return self
    }

    case timeDifferenceList
    case voiceList(Chara)
}
