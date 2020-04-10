/**
 BottomSheet.playground:
 A demonstration of the BottomSheet class which is used to slide a
 view controller into another view controller from the bottom.
 
 The view controllers involved are:
   - MainVC
     contains a log view (to show debug messages) and a tap
     recognizer. A tap in this view will slide in the second 
     view controller SliderVC.
   - SliderVC
     This view controller contains as an example for a simple
     UI element a Picker (a UIPickerView derivate) which prints
     debug messages to the log view.
 
 SliderVC is moved vertically using a pan gesture recognizer. If moved
 below 50% of its maximal height it is removed when the pan finishes 
 there. If the pan ends at more than 50% the SliderVC is extended to
 its maximum size.
 The maximum size of SliderVC is determined by
   SliderVC.view.intrinsicContentSize.height
 If that value is <= 0, the maximum height is set to 80% of MainVCs 
 height.
 */

import PlaygroundSupport
import UIKit
import NorthLib

/// The VC to slide into, simply providing a ViewLogger
class MainVC: UIViewController {
  var viewLogger = Log.ViewLogger()
  override func loadView() {
    let view = UIView()
    view.backgroundColor = .white
    view.addSubview(viewLogger.logView)
    viewLogger.logView.pinToView(view)
    Log.append(logger: viewLogger)
    Log.minLogLevel = .Debug
    self.view = view
  }
}

/// A simple view to populate the VC to slide
class TestView: UIView {
  /// This defines the width (for horizontal sliders)
  /// or height for vertical sliders
  override var intrinsicContentSize: CGSize {
     return CGSize(width: 200, height: 600)
  }
  /// A single picker as the only content
  var picker = Picker()
  var textInput = UITextField()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .white
    addSubview(picker)
    addSubview(textInput)
    picker.items = ["one","two","three","four"]
    picker.onSelection { i in 
      self.debug("\(i): \(self.picker.items[i])")
    }
    picker.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
    textInput.pinWidth(150)
    pin(textInput.centerX, to: self.centerX)
    pin(textInput.top, to: picker.bottom, dist: 10)
    textInput.placeholder = "ID"
    textInput.borderStyle = .bezel
  }
  
  required init?(coder: NSCoder) { super.init(coder: coder) }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    picker.center = self.center
  }
}

/// The VC to slide into MainVC
class SliderVC: UIViewController {
  override func loadView() {
    let view = TestView()
    self.view = view
  }
}

let sliderVC = SliderVC()
let mainVC = MainVC()

mainVC.preferredContentSize = CGSize.init(width: 768,height: 1024)
PlaygroundPage.current.liveView = mainVC

let slider = BottomSheet(slider: sliderVC, into: mainVC)
//let slider = VerticalSheet(slider: sliderVC, into: mainVC, fromBottom: false)
slider.color = UIColor.white
slider.handleColor = UIColor.gray
mainVC.viewLogger.logView.onTap {_ in
  slider.open()
  delay(seconds: 2) { slider.slideUp(100) }
  delay(seconds: 4) { slider.slideDown(100) }
}
Log.debug("\nTap to display bottom sheet\n\n")
Log.debug("Coverage: \(slider.coverage)")
