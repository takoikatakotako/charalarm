import Foundation

enum AlarmListViewSheetItem: Identifiable, Hashable {
    var id: Self {
        return self
    }
    case alarmDetailForCreate
    case alarmDetailForEdit(Alarm)
}
