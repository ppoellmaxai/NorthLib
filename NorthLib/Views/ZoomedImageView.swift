//
//    
//  NorthLib
//
//  Created by Ringo Müller on 27.05.20.
//  Copyright © 2020 Norbert Thies. All rights reserved.
//

import UIKit

/// An Image with a smaller "Waiting Image"
public protocol OptionalImage {
  /// The main image to display
  var image: UIImage? { get set }
  /// An alternate image to display when the main image is not yet available
  var waitingImage: UIImage? { get set }
  /// Returns true if 'image' is available
  var isAvailable: Bool { get }
  /// Defines a closure to call when the main image becomes available
  func whenAvailable(closure: @escaping ()->())
  
  /// Define closure to call when the user is zooming beyond the resolution
  /// of the image. 'zoomFactor' defines the maximum zoom after which a higher
  /// resolution image is requested.
  func onHighResImgNeeded(zoomFactor: CGFloat,
                          closure: @escaping (@escaping (UIImage?) -> ()) -> ())

  /// Defines a closure to call when the user has tapped into the image.
  /// The coordinates passed to the closure are relative content size
  /// coordinates: 0 <= x,y <= 1
  func onTap(closure: @escaping (_ x: Double, _ y: Double)->())
}

extension OptionalImage {
  public var isAvailable: Bool { return image != nil }
}

open class OptionalImageItem: OptionalImage{
  private var availableClosure: (()->())?
  fileprivate var needHighRes:((@escaping (UIImage?)->()) -> ())? = nil
  fileprivate var onUpdatingClosureClosure: (()->())? = nil
  fileprivate var zoomFactorForRequestingHigherResImage : CGFloat = 1.0
  fileprivate var onImageTapClosure: ((_ x:Double, _ y:Double)->())? = nil
  
  public var waitingImage: UIImage?
  fileprivate var _image: UIImage?
  public var image: UIImage?{
    get { return _image }
    set {
      _image = newValue
      availableClosure?()
    }
  }
  
  func setImg(i:UIImage){
    _image = i
  }
  
  public required init(waitingImage: UIImage? = nil) {
    self.waitingImage = waitingImage
  }
}

// MARK: - OptionalImageItem Closures
extension OptionalImageItem{
  public func onHighResImgNeeded(zoomFactor: CGFloat,
                                 closure: @escaping (@escaping (UIImage?) -> ()) -> ()) {
    zoomFactorForRequestingHigherResImage = zoomFactor
    needHighRes = closure
    onUpdatingClosureClosure?()
  }
  
  public func whenAvailable(closure: @escaping ()->()) {
    availableClosure = closure
  }
  
  public func onTap(closure: @escaping (_ x: Double, _ y: Double)->()){
    onImageTapClosure = closure
    onUpdatingClosureClosure?()
  }
}

// MARK: -
open class ZoomedImageView: UIView, ZoomedImageViewSpec {
  private var zoomEnabled :Bool = true {
    didSet{
      self.scrollView.pinchGestureRecognizer?.isEnabled = zoomEnabled
    }
  }
  private var initiallyCentered = false
  private var lastLayoutSubviewsOrientationWasPortrait = false
  private var needUpdateScaleLimitAfterLayoutSubviews = true
  fileprivate var highResImageRequested: Bool = false
  private let imageTapRecognizer = UITapGestureRecognizer()
  private var orientationClosure = OrientationClosure()
  private var imageTapClosure : ((Double, Double) -> ())? = nil
  private var higherImageResolutionNeededClosure: (zoomFactor: CGFloat, closure: ()->UIImage?)? = nil
  public private(set) var scrollView: UIScrollView = UIScrollView()
  public private(set) var imageView: UIImageView = UIImageView()
  public private(set) var xButton: Button<CircledXView> = Button<CircledXView>()
  public private(set) var spinner: UIActivityIndicatorView = UIActivityIndicatorView()
  public private(set) lazy var menu = ContextMenu(view: imageView)
  
  public required init(optionalImage: OptionalImage) {
    self.optionalImage = optionalImage
    super.init(frame: CGRect.zero)
    setup()
  }
  
  public var optionalImage: OptionalImage{
    willSet {
      if let itm = optionalImage as? OptionalImageItem {
        itm.onUpdatingClosureClosure = nil
      }
    }
    didSet {
      updateImage()
      if let itm = optionalImage as? OptionalImageItem {
        itm.onUpdatingClosureClosure = { self.updateClosures() }
        self.highResImageRequested = false
      }
      updateClosures()
      initiallyCentered = false
      setScaleLimitsAndCenterIfNeeded()
    }
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
    lastLayoutSubviewsOrientationWasPortrait
      = UIDevice.current.orientation.isPortrait
    if needUpdateScaleLimitAfterLayoutSubviews {
      needUpdateScaleLimitAfterLayoutSubviews = false
      scrollView.pinchGestureRecognizer?.isEnabled = zoomEnabled
      setScaleLimitsAndCenterIfNeeded()
    }
  }
}

// MARK: - Image Tap
extension ZoomedImageView{
  public func onImageTap(closure: ((Double, Double) -> ())?) {
    if closure == nil {
      imageTapRecognizer.isEnabled = false
      return
    }
    imageTapRecognizer.numberOfTapsRequired = 1
    imageTapRecognizer.isEnabled = true
    imageTapRecognizer.addTarget(self, action: #selector(imageTapHandler))
    imageView.addGestureRecognizer(imageTapRecognizer)
    imageView.isUserInteractionEnabled = true
    imageTapClosure = closure
  }
  
  @objc func imageTapHandler(sender: UITapGestureRecognizer){
    let loc = sender.location(in: imageView)
    let size = imageView.frame.size
    guard let closure = imageTapClosure else { return }
    closure(Double(loc.x / (size.width / scrollView.zoomScale )),
            Double(loc.y / (size.height / scrollView.zoomScale )))
  }
}

// MARK: Double Tap
extension ZoomedImageView{
  @objc func handleDoubleTap(sender : Any) {
    guard let tapR = sender as? UITapGestureRecognizer else {
      return
    }
    
    if zoomEnabled == false {
      return
    }
    
    //Zoom Out if current zoom is maximum zoom
    if scrollView.zoomScale == scrollView.maximumZoomScale
      || scrollView.zoomScale >= 2 {
      scrollView.setZoomScale(scrollView.minimumZoomScale,
                              animated: true)
      centerImageInScrollView()
    }
    //Otherwise Zoom Out in to tap loacation
    else {
      let maxZoom = scrollView.maximumZoomScale
      if maxZoom > 2 { scrollView.maximumZoomScale = 2  }
      let tapLocation = tapR.location(in: tapR.view)
      let newCenter = imageView.convert(tapLocation, from: scrollView)
      let zoomRect = CGRect(origin: newCenter, size: CGSize(width: 1, height: 1))
      scrollView.zoom(to: zoomRect,
                      animated: true)
      scrollView.isScrollEnabled = true
      if maxZoom > 2 { scrollView.maximumZoomScale = maxZoom  }
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
    updateClosures()
    updateImage()
    orientationClosure.onOrientationChange(closure: {
      self.setScaleLimitsAndCenterIfNeeded()
    })
  }
  
  func updateImage() {
    if optionalImage.isAvailable, let detailImage = optionalImage.image {
      setImage(detailImage)
      zoomEnabled = true
      spinner.stopAnimating()
    }
    else {
      //show waitingImage if detailImage is not available yet
      if let img = optionalImage.waitingImage {
        setImage(img)
        zoomEnabled = false
      } else {
        //Due re-use its needed to unset probably existing old image
        imageView.image = nil
      }
      spinner.startAnimating()
      optionalImage.whenAvailable {
        if let img = self.optionalImage.image {
          self.setImage(img)
          self.zoomEnabled = true
          self.spinner.stopAnimating()
          //due all previewImages are not allowed to zoom,
          //exchanged image should be shown fully
          self.initiallyCentered = false
          self.setScaleLimitsAndCenterIfNeeded()
        }
      }
    }
  }
  
  func updateClosures() {
    guard let itm = optionalImage as? OptionalImageItem else { return }
    self.onImageTap(closure: itm.onImageTapClosure)
    self.scrollView.maximumZoomScale
      = itm.needHighRes == nil ? 1.0 : 10
  }
  
  func setupScrollView() {
    imageView.contentMode = .scaleAspectFit
    scrollView.delegate = self
    scrollView.maximumZoomScale = 1.0
    scrollView.zoomScale = 1.0
    ///prevent pinch/zoom smaller than min while pinch
    scrollView.bouncesZoom = false
    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.addSubview(imageView)
    addSubview(scrollView)
    NorthLib.pin(scrollView, to: self)
  }
  
  // Sets up the gesture recognizer that receives double taps to auto-zoom
  func setupGestureRecognizer() {
    let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                   action: #selector(handleDoubleTap))
    gestureRecognizer.numberOfTapsRequired = 2
    imageTapRecognizer.require(toFail: gestureRecognizer)
    scrollView.addGestureRecognizer(gestureRecognizer)
    gestureRecognizer.isEnabled = zoomEnabled
  }
}

// MARK: Helper
extension ZoomedImageView{
  func setImage(_ image: UIImage) {
    scrollView.zoomScale = 1.0//ensure contentsize is correct!
    imageView.image = image
    imageView.frame = CGRect(origin: CGPoint.zero, size: image.size)
    scrollView.contentSize = image.size
  }
  
  func updateImagewithHighResImage(_ image: UIImage) {
    guard let oldImg = imageView.image else {
      self.setImage(image)
      return
    }
    
    let oldZoomScale : CGFloat = scrollView.zoomScale
    let center = scrollView.contentOffset
    self.setImage(image)
    
    scrollView.minimumZoomScale
      = self.minimalZoomFactorFor (scrollView.frame.size, image.size)
    
    let newSc = oldImg.size.width * oldZoomScale / image.size.width
    scrollView.zoomScale = newSc
    scrollView.setContentOffset(center, animated: false)
  }
  
  /** Centers the Image in the ScrollView
   * using ScrollView's ContentOffset did not work if scrolling is enabled, image jumped to top/left
   * Solution using ScrollViews ContentInsets from: https://stackoverflow.com/a/35680604
   * simplified for our requirements
   */
  func centerImageInScrollView() {
    //Set Center by setting Insets
    guard let img = imageView.image else {
      return;
    }
    let contentSize = CGSize(width: img.size.width * scrollView.zoomScale,
                             height: img.size.height * scrollView.zoomScale)
    let screenSize  = scrollView.frame.size
    let offx = screenSize.width > contentSize.width ? (screenSize.width - contentSize.width) / 2 : 0
    let offy = screenSize.height > contentSize.height ? (screenSize.height - contentSize.height) / 2 : 0
    scrollView.contentInset = UIEdgeInsets(top: offy,
                                           left: offx,
                                           bottom: offy,
                                           right: offx)
    
    // The scroll view has zoomed, so you need to re-center the contents
    var scrollViewSize: CGSize{
      var size = scrollView.frame.size
      size.width -= 2*offx
      size.height -= 2*offy
      return size
    }
    
    // First assume that image center coincides with the contents box center.
    // This is correct when the image is bigger than scrollView due to zoom
    var imageCenter = CGPoint(x: scrollView.contentSize.width / 2.0,
                              y: scrollView.contentSize.height / 2.0)
    
    let center = CGPoint(x: scrollViewSize.width/2, y: scrollViewSize.height/2)
    
    //if image is smaller than the scrollView visible size - fix the image center accordingly
    if scrollView.contentSize.width < scrollViewSize.width {
      imageCenter.x = center.x
    }
    
    if scrollView.contentSize.height < scrollViewSize.height {
      imageCenter.y = center.y
    }
    imageView.center = imageCenter
  }
  
  func minimalZoomFactorFor(_ parent: CGSize, _ child: CGSize) -> CGFloat{
    let xZf = parent.width / (child.width > 0 ? child.width : 1)
    let yZf = parent.height / (child.height > 0 ? child.height : 1)
    return min(xZf, yZf, 1.0)
  }
  
  func setScaleLimitsAndCenterIfNeeded() {
    if lastLayoutSubviewsOrientationWasPortrait
      != UIDevice.current.orientation.isPortrait {
      //handle device rotation happen but layout not updated yet
      setNeedsLayout()
      layoutIfNeeded()
      needUpdateScaleLimitAfterLayoutSubviews = true
      return;
    }
    let isMinimumZoomScale = scrollView.zoomScale == scrollView.minimumZoomScale
    
    guard let img = imageView.image else {
      return
    }
    
    //after rotation there is a new minimumZoomScale
    scrollView.minimumZoomScale
      = minimalZoomFactorFor (scrollView.frame.size, img.size)
    //this new minimum needs to be set if current is smaller
    if scrollView.zoomScale < scrollView.minimumZoomScale {
      scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
    }
    
    if isMinimumZoomScale || initiallyCentered == false {
      scrollView.zoomScale = scrollView.minimumZoomScale
      self.centerImageInScrollView()
      initiallyCentered = true
    }
    //if Letterbox  minimum zoom scale is 1 ensure centeren Image
    if scrollView.frame.size.width > img.size.width * scrollView.zoomScale
      || scrollView.frame.size.height > img.size.height * scrollView.zoomScale {
      self.centerImageInScrollView()
    }
  }
}

// MARK: UIScrollViewDelegate
extension ZoomedImageView: UIScrollViewDelegate{
  public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return imageView
  }
  
  public func scrollViewDidZoom(_ scrollView: UIScrollView) {
    if scrollView.frame.size.width > scrollView.contentSize.width
      || scrollView.frame.size.height > scrollView.contentSize.height {
      centerImageInScrollView()
    }
   
    if let oImage = optionalImage as? OptionalImageItem,
      highResImageRequested == false,
      oImage.zoomFactorForRequestingHigherResImage <= scrollView.zoomScale,
      let requestHighResImage = oImage.needHighRes {
      highResImageRequested = true
      requestHighResImage({ image in
        if let img = image {
          self.updateImagewithHighResImage(img)
          self.highResImageRequested = false
          oImage._image = img
        }
      })
    }
  }
}
