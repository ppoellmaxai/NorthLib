/**
 Carousel.playground:
 A demonstration of the CarouselView class which is a CollectionView acting like a carousel
*/ 

import PlaygroundSupport
import UIKit
import NorthLib

/// A simple view to populate Carousel
class TestView: UIView, Touchable {
  var label = UILabel()
  var recognizer = TapRecognizer()
  
  init(frame: CGRect, n: Int) {
    super.init(frame: frame)
    label.text = "\(n)"
    let col: UIColor = [.red, .green, .yellow][n%3]
    backgroundColor = col
    addSubview(label)
    pin(label.centerX, to: self.centerX)
    pin(label.centerY, to: self.centerY)
    isUserInteractionEnabled = true
    onTap {_ in self.debug(self.label.text) }
  }
  
  required init?(coder: NSCoder) { super.init(coder: coder) }
}

/// Main view controller with a logView
class MainVC: UIViewController {
  var viewLogger = Log.ViewLogger()
  var carousel = CarouselView()
  
  override func loadView() {
    let view = UIView()
    view.backgroundColor = .white
    view.addSubview(viewLogger.logView)
    viewLogger.logView.pinToView(view)
    Log.append(logger: viewLogger)
    Log.minLogLevel = .Debug
    viewLogger.logView.onTap {_ in
      self.carousel.isHidden = !self.carousel.isHidden
    }
    view.addSubview(carousel)
    pin(carousel.left, to: view.left)
    pin(carousel.right, to: view.right)
    pin(carousel.centerY, to: view.centerY)
    carousel.pinHeight(400)
    carousel.backgroundColor = .lightGray
    carousel.roundedCorners = true
    carousel.scrollFromLeftToRight = true
    carousel.viewProvider { (i, oview) in
      TestView(frame: CGRect(), n: i+1)
    }
    carousel.onDisplay { idx in 
      if (idx % 7) == 0 { self.carousel.count += 10 }
    }
    self.view = view
  }
  
  override func viewWillAppear(_ animated: Bool) {
    carousel.count = 10
    carousel.index = 0
  }
}

let mainVC = MainVC()
PlaygroundPage.current.liveView = mainVC
//delay(seconds:5) { mainVC.carousel.index = 4 }

