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
      availableClosure?()
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

// MARK: -
open class ZoomedImageView: UIView, ZoomedImageViewSpec {
  private var initiallyCenteredImage = false
  private var orientationClosure = OrientationClosure()
  public private(set) var scrollView: UIScrollView = UIScrollView()
  public private(set) var imageView: UIImageView = UIImageView()
  public private(set) var optionalImage: OptionalImage
  public private(set) var xButton: Button<CircledXView> = Button<CircledXView>()
  public private(set) var spinner: UIActivityIndicatorView = UIActivityIndicatorView()
  public private(set) lazy var menu = ContextMenu(view: imageView)
  
  public required init(optionalImage: OptionalImage) {
    self.optionalImage = optionalImage
    super.init(frame: CGRect.zero)
    setup()
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
  
  override public func layoutSubviews() {
    super.layoutSubviews()
    //Wenn 1:1 war dann nichts sonnst center? reset zoom
    if initiallyCenteredImage == false {
      initiallyCenteredImage = true
      centerImageInScrollView(animated: false)
    } else if scrollView.zoomScale != 1.0 {
      centerImageInScrollView(animated: false)
    }
  }
}

// MARK: Handler
extension ZoomedImageView{
  @objc func handleDoubleTap(sender : Any) {
    guard let tapR = sender as? UITapGestureRecognizer else {
      return
    }
    //Do not allow zoom on preview image
    if optionalImage.isAvailable == false {
      return
    }
    //Zoom Out if current zoom is maximum zoom
    if scrollView.zoomScale == scrollView.maximumZoomScale {
      
      scrollView.setZoomScale(scrollView.minimumZoomScale,
                              animated: true)
      scrollView.isScrollEnabled = false
      centerImageInScrollView(animated: true)
      
    }
      //Otherwise Zoom Out in to tap loacation
    else {
      let tapLocation = tapR.location(in: tapR.view)
      let newCenter = imageView.convert(tapLocation, from: scrollView)
      let zoomRect = CGRect(origin: newCenter, size: CGSize(width: 1, height: 1))
      scrollView.zoom(to: zoomRect,
                      animated: true)
      scrollView.isScrollEnabled = true
    }
  }
}

// MARK: Setup
extension ZoomedImageView{
  
  func setup() {
    setupScrollView()
    setupXButton()
    setupSpinner()
    setupGestureRecognizer()
    setupImage()
    orientationClosure.onOrientationChange(closure: {
      self.handleOrientationChange()
    })
  }
  
  func setupImage() {
    if optionalImage.isAvailable, let detailImage = optionalImage.image {
      setImage(detailImage)
    }
    else {
      //show waitingImage if detailImage is not available yet
      setImage(optionalImage.waitingImage)
      
      //img is bigger/smaller //center max width /scale factor???
      optionalImage.whenAvailable {
        if let img = self.optionalImage.image {
          self.setImage(img)
          self.scrollView.isScrollEnabled = false
          let zoom = self.minimalZoomFactorFor(self.scrollView.frame.size, img.size)
          self.scrollView.minimumZoomScale = zoom
          self.scrollView.zoomScale = zoom
          self.centerImageInScrollView(animated: false)
        }
      }
    }
  }
  
  func setupScrollView() {
    imageView.contentMode = .scaleAspectFit
    scrollView.delegate = self
    scrollView.maximumZoomScale = 1.0
    scrollView.zoomScale = 1.0
    
    scrollView.addSubview(imageView)
    addSubview(scrollView)
    
    NorthLib.pin(scrollView, to: self)
  }
  
  // Sets up the gesture recognizer that receives double taps to auto-zoom
  func setupGestureRecognizer() {
    let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                   action: #selector(handleDoubleTap))
    gestureRecognizer.numberOfTapsRequired = 2
    scrollView.addGestureRecognizer(gestureRecognizer)
  }
}

// MARK: Helper
extension ZoomedImageView{
  func setImage(_ image: UIImage) {
    imageView.image = image
    imageView.frame = CGRect(origin: CGPoint.zero, size: image.size)
    scrollView.contentSize = image.size
  }
  
  func centerImageInScrollView(animated:Bool) {
    let imageSize = imageView.frame.size
    let centerOffsetX = (imageSize.width - scrollView.frame.size.width) / 2
    let centerOffsetY = (imageSize.height - scrollView.frame.size.height) / 2
    let centerPoint = CGPoint(x: centerOffsetX, y: centerOffsetY)
    scrollView.setContentOffset(centerPoint, animated: animated)
  }
  
  func minimalZoomFactorFor(_ parent: CGSize, _ child: CGSize) -> CGFloat{
    let xZf = parent.width / (child.width > 0 ? child.width : 1)
    let yZf = parent.height / (child.height > 0 ? child.height : 1)
    return min(xZf, yZf)
  }
  
  func handleOrientationChange() {
    if let img = self.optionalImage.image {
      //After Rotation if there is a detailImage, set new minimumZoomScale
      self.scrollView.minimumZoomScale
        = self.minimalZoomFactorFor (self.scrollView.frame.size, img.size)
      //remove the condition if zoomScale should be adjusted after each rotation
      //attend: the current zoomScale will be lost than!
      if self.scrollView.zoomScale < self.scrollView.minimumZoomScale {
        self.scrollView.setZoomScale(self.scrollView.minimumZoomScale,
                                     animated: true)
      }
    }
  }
}

// MARK: UIScrollViewDelegate
extension ZoomedImageView: UIScrollViewDelegate{
  public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }
  
  public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    //prevent Image aligned on top-left after pinch zoom out
    if scrollView.frame.size.width > scrollView.contentSize.width
      || scrollView.frame.size.height > scrollView.contentSize.height {
      centerImageInScrollView(animated: true)
    }
    //ensure scrolling is enabled due pinch-zoom
    scrollView.isScrollEnabled = true
  }
}
