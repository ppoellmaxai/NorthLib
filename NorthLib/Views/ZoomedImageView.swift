//
//  ZoomedImageView.swift
//  NorthLib
//
//  Created by Ringo Müller on 27.05.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import Foundation

public class OptionalImageItem: OptionalImage{
  private var availableClosure: (()->())?
  public var image: UIImage?{
    didSet {
      self.availableClosure?()
    }
  }
  public var waitingImage: UIImage

  public func whenAvailable(closure: @escaping ()->()) {
    availableClosure = closure
  }

  public required init(waitingImage: UIImage) {
    self.waitingImage = waitingImage
  }
}

open class ZoomedImageView: UIView, UIScrollViewDelegate, ZoomedImageViewSpec {
  public private(set) var scrollView: UIScrollView = UIScrollView()
  public private(set) var imageView: UIImageView = UIImageView()
  public private(set) var optionalImage: OptionalImage
  public private(set) var xButton: Button<CircledXView> = Button<CircledXView>()
  public private(set) var spinner: UIActivityIndicatorView = UIActivityIndicatorView()
  public private(set) lazy var menu = ContextMenu(view: imageView)
  
  public required init(optionalImage: OptionalImage) {
    self.optionalImage = optionalImage
    super.init(frame: CGRect.zero)
    self.setup()
  }
  
  override public init(frame: CGRect) {
    fatalError("init(frame:) has not been implemented");
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented");
  }
  
  public func addMenuItem(title: String, icon: String, closure: @escaping (String) -> ()) {
    menu.addMenuItem(title: title, icon: icon, closure: closure)
  }
  
  public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
      return imageView
  }
  
  // Handles a double tap by either resetting the zoom or zooming to where was tapped
  @objc func handleDoubleTap(sender : Any) {
      guard let gestureRecognizer = sender as? UITapGestureRecognizer else {
        return
      }
    
    //Do not allow zoom on preview image
    if self.optionalImage.isAvailable == false {
      return
    }
    if scrollView.zoomScale == 1 {
      print("zoom Out")
//      let targetRect = zoomRectForScale(1, center: CGPoint.zero)
//      let targetRect2 = CGRect(origin: CGPoint(x:0.0, y:-216.3125), size: targetRect.size)
//      scrollView.rect
//       scrollView.zoom(to: targetRect2, animated: true)
//     scrollView.setZoomScale(<#T##scale: CGFloat##CGFloat#>, animated: <#T##Bool#>)
//     scrollView.setContentOffset(centerPoint, animated: animated)
      //works but ugly
      scrollView.zoom(to: zoomRectForScale(1, center: gestureRecognizer.location(in: gestureRecognizer.view)), animated: true)
        self.centerImageInScrollView(animated: true)
      } else {
        print("zoom In")
        scrollView.setZoomScale(1, animated: true)
      }
  }
  
  
  func centerImageInScrollView(animated:Bool) {
//    let size = imageView.image?.size ?? CGSize.zero//too big real img size
    let size = imageView.frame.size
    let centerOffsetX
      = (size.width - scrollView.frame.size.width) / 2
    let centerOffsetY
      = (size.height - scrollView.frame.size.height) / 2
    let centerPoint = CGPoint(x: centerOffsetX, y: centerOffsetY)
    print(">>>>> Center\nSV.size: ", scrollView.frame.size, " SV.ContentSize: ", size, " SV.CenterPoint: ", centerPoint, "\n ")
    scrollView.setContentOffset(centerPoint, animated: animated)
    printSizesFrom("after centerImageInScrollView")
    
//    self.imageView.setNeedsLayout()
//    self.imageView.layoutIfNeeded()
//    
//    self.scrollView.setNeedsLayout()
//    self.scrollView.layoutIfNeeded()
    
  }
  
  func printSizesFrom(_ from: String){
    print(">>>>> ", from,
          "\nSV.size: ", scrollView.frame.size,
          " SV.contentSize: ", scrollView.contentSize,
          " SV.zoomScale: ", scrollView.zoomScale,
          " imageView.frame: ", imageView.frame,
          " SV.contentOffset: ", scrollView.contentOffset)
  }
  
  // Calculates the zoom rectangle for the scale
  func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
      var zoomRect = CGRect.zero
      zoomRect.size.height = imageView.frame.size.height / scale
      zoomRect.size.width = imageView.frame.size.width / scale
      let newCenter = convert(center, from: imageView)
      zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
      zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
      print("zoomRectForScale: ", zoomRect)
      return zoomRect
  }
  
  // Sets up the gesture recognizer that receives double taps to auto-zoom
  func setupGestureRecognizer() {
      let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                     action: #selector(handleDoubleTap))
      gestureRecognizer.numberOfTapsRequired = 2
      self.scrollView.addGestureRecognizer(gestureRecognizer)
  }
  
  
  private func initialZoomFactor(parent: CGSize, child: CGSize) -> CGFloat{
    let xZF = parent.width / max(1, child.width)
    let yZF = parent.height / max(1, child.height)
    return min(xZF, yZF)
  }
  
  func setupScrollView() {
    imageView.contentMode = .scaleAspectFit
    
    scrollView.delegate = self
    scrollView.minimumZoomScale = 0.1//Needs to be calculated
    scrollView.maximumZoomScale = 1.0
    scrollView.zoomScale = 1.0
    
    scrollView.addSubview(imageView)
    self.addSubview(scrollView)
    NorthLib.pin(imageView, to: scrollView)

    NorthLib.pin(scrollView, to: self)
  }
  
  private func setup() {
    setupScrollView()
    self.setupXButton()
    self.onX {
      self.printSizesFrom("onX Button")
      self.centerImageInScrollView(animated: false)
    }
    
    self.setupSpinner()
    self.setupGestureRecognizer()
    
    if !self.optionalImage.isAvailable {
      
      //show waitingImage if detailImage is not available yet
      imageView.image = optionalImage.waitingImage
     
      //img is bigger/smaller //center max width /scale factor???
      self.optionalImage.whenAvailable {
        if let img = self.optionalImage.image {
          self.imageView.image = img
          self.spinner.stopAnimating()
          self.scrollView.pinchGestureRecognizer?.isEnabled = true
          self.scrollView.zoomScale = 0.16171875
                    
          self.imageView.setNeedsLayout()
          self.imageView.layoutIfNeeded()
          
          self.scrollView.setNeedsLayout()
           self.scrollView.layoutIfNeeded()
          
          self.setNeedsLayout()
          self.layoutIfNeeded()
          
          self.centerImageInScrollView(animated: true)
        }
      }
    }
    else {
        imageView.image = optionalImage.image
    }
  }
  
  var inited = false
  
  override public func layoutSubviews() {
    print("layout subviews")
    super.layoutSubviews()
    //Wenn 1:1 war dann nichts sonnst center? reset zoom
    if inited == false {
      inited = true
      self.imageView.setNeedsLayout()
      self.imageView.layoutIfNeeded()
      
      self.scrollView.setNeedsLayout()
       self.scrollView.layoutIfNeeded()
      self.centerImageInScrollView(animated: false)
    } else if scrollView.zoomScale != 1.0 {
      print("show not 1:1 zoomed, do center")
      self.centerImageInScrollView(animated: false)
    }

    
    
  }
}
