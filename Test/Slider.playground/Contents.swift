import UIKit
import PlaygroundSupport
import NorthLib

class TestVC: UIViewController {
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .red
        // Add subviews ...
        self.view = view
    }
}

class TestView: UIView {
  override var intrinsicContentSize: CGSize {
     return CGSize(width: 200, height: 400)
  }
}

class SliderVC: UIViewController {
  override func loadView() {
      let view = TestView()
      view.backgroundColor = .green
      // Add subviews ...
      self.view = view
  }
}

let sliderVC = SliderVC()
let testVC = TestVC()

PlaygroundPage.current.liveView = testVC

let slider = Slider(slider: sliderVC, into: testVC)
slider.open()
print("cs: \(slider.slider.view.intrinsicContentSize)")
