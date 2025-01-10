import SwiftUI

struct AlarmDetailTimePickerTemp: UIViewRepresentable {
    var hour: Binding<Int>
    var minute: Binding<Int>

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: UIViewRepresentableContext<AlarmDetailTimePickerTemp>) -> UIPickerView {
        let picker = UIPickerView()
        picker.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator

        return picker
    }

    func updateUIView(_ view: UIPickerView, context: UIViewRepresentableContext<AlarmDetailTimePickerTemp>) {
        view.selectRow(hour.wrappedValue, inComponent: 0, animated: false)
        view.selectRow(minute.wrappedValue, inComponent: 1, animated: false)
    }

    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
        var parent: AlarmDetailTimePickerTemp

        init(_ pickerView: AlarmDetailTimePickerTemp) {
            parent = pickerView
        }

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 2
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            if component == 0 {
                return 24
            } else {
                return 60
            }
        }

        func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
            return 48
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            return String(format: "%02d", row)
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            if component == 0 {
                parent.hour.wrappedValue = row
            } else {
                parent.minute.wrappedValue = row
            }
        }
    }
}
