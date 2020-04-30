//
//  WebView.swift
//
//  Created by Norbert Thies on 01.08.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit
import WebKit

/// A JSCall-Object describes a native call from JavaScript to Swift
open class JSCall: DoesLog {
  
  /// name of the NativeBridge object
  public var bridgeObject = ""
  /// name of the method called
  public var method = ""
  /// callback ID
  public var callback: Int?
  /// array of arguments
  public var args: [Any]?
  /// WebView object receiving the call
  public weak var webView: WebView?
  
  /// A new JSCall object is created using a WKScriptMessage
  public init(_ msg: WKScriptMessage) throws {
    if let dict = msg.body as? Dictionary<String,Any> {
      bridgeObject = msg.name
      if let m = dict["method"] as? String {
        method = m
        callback = dict["callback"] as? Int
        args = dict["args"] as? [Any]
      }
      else { throw exception( "JSCall without name of method" ) }
    }
    else { throw exception( "JSCall without proper message body" ) }
  }
  
  // TODO: implement callback to return value to JS callback function
  
} // class JSCall

/// A JSBridgeObject describes a JavaScript object containing
/// methods that are passed to native functions
open class JSBridgeObject: DoesLog {
  
  /// Dictionary of JS function names to native closures
  public var functions: [String:(JSCall)->()] = [:]
  
  /// calls a native closure
  public func call(_ jscall: JSCall) {
    if let f = functions[jscall.method] {
      debug( "From JS: '\(jscall.bridgeObject).\(jscall.method)' called" )
      f(jscall)
    }
    else {
      error( "From JS: undefined function '\(jscall.bridgeObject).\(jscall.method)' called" )
    }
  }
  
} // class JSBridgeObject

extension WKNavigationAction: ToString {
  
  public func navtype2a() -> String {
    switch self.navigationType {
    case .backForward:     return "backForward"
    case .formResubmitted: return "formResubmitted"
    case .formSubmitted:   return "formSubmitted"
    case .linkActivated:   return "linkActivated"
    case .other:           return "other"
    case .reload:          return "reload"
    default:               return "[undefined]"
    }
  }
  
  public func toString() -> String {
    return "WebView Navigation: \(navtype2a())\n  \(request.toString())"
  }
  
}

open class WebView: WKWebView, WKScriptMessageHandler, UIScrollViewDelegate {

  /// JS NativeBridge objects
  public var bridgeObjects: [String:JSBridgeObject] = [:]
  
  /// Directory which local web pages may access for resources
  public var baseDir: String?
  public var baseUrl: URL? { 
    if let d = baseDir { return URL(fileURLWithPath: d) } 
    else { return nil } 
  }
  /// The original URL to load
  public var originalUrl: URL?
  
  // The closure to call when content scrolled more than _scrollRatio
  private var whenScrolledClosure: ((CGFloat)->())?
  private var scrollRatio: CGFloat = 0
  
  /// Define closure to call when web content has been scrolled
  public func whenScrolled( minRatio: CGFloat, _ closure: @escaping (CGFloat)->() ) {
    scrollRatio = minRatio
    whenScrolledClosure = closure
  }
  
  // The closure to call when some dragging (scrolling) has been done
  private var whenDraggedClosure: ((CGFloat)->())?

  /// Define closure to call when web content has been dragged, the value passed
  /// is the number of points scrolled down divided by the content's height
  public func whenDragged(closure: @escaping (CGFloat)->()) {
    whenDraggedClosure = closure
  }
  
  // content y offset at start of dragging
  private var startDragging: CGFloat?
  
  /// Define closure to call when the end of the web content will become 
  /// visible
  public func atEndOfContent(closure: @escaping (Bool)->()) {
    atEndOfContentClosure = closure
  }
  
  // end of content closure
  private var atEndOfContentClosure: ((Bool)->())?
  
  /// Returns true if the end of the content is visible
  /// (in vertical direction)
  public var isAtEndOfContent: Bool {
    return isAtEndOfContent(offset: scrollView.contentOffset.y)
  }

  /// Returns true if at a given offset the end of the content is visible
  /// (in vertical direction)
  public func isAtEndOfContent(offset: CGFloat) -> Bool {
    let end = scrollView.contentSize.height
    return (offset + bounds.size.height) >= end
  }
  
  /// jsexec executes the passed string as JavaScript expression using
  /// evaluateJavaScript, if a closure is given, it is only called when
  /// there is no error.
  public func jsexec(_ expr: String, closure: ((Any?)->Void)?) {
    self.evaluateJavaScript(expr) {
      [weak self] (retval, error) in
      if let err = error {
        self?.error("JavaScript error: " + err.localizedDescription)
      }
      else {
        if let callback = closure {
          callback(retval)
        }
      }
    }
  }
  
  /// calls a native closure
  public func call(_ jscall: JSCall) {
    if let bo = bridgeObjects[jscall.bridgeObject] {
      bo.call(jscall)
    }
    else {
      error("From JS: undefined bridge object '\(jscall.bridgeObject) used")
    }
  }
  
  @discardableResult
  public func load(url: URL) -> WKNavigation? {
    if isLoading { stopLoading() }
    self.originalUrl = url
    if url.isFileURL {
      debug("load: \(url.lastPathComponent)")
      var base = self.baseUrl
      if base == nil { base = url.deletingLastPathComponent() }
      return loadFileURL(url, allowingReadAccessTo: base!)
    }
    else {
      let request = URLRequest(url: url)
      return load(request)
    }
  }
  
  @discardableResult
  public func load(_ string: String) -> WKNavigation? {
    if let url = URL(string: string) {
      return load(url: url)
    }
    else { return nil }
  }
  
  @discardableResult
  public func load(html: String) -> WKNavigation? {
    return loadHTMLString(html, baseURL: baseUrl)
  }
  
  public func setup() {
  }
  
  override public init(frame: CGRect, configuration: WKWebViewConfiguration? = nil) {
    var config = configuration
    if config == nil { config = WKWebViewConfiguration() }
    super.init(frame: frame, configuration: config!)
    setup()
  }
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  public func scrollToTop() {
    scrollView.setContentOffset(CGPoint(x:0, y:0), animated: false)
  }
  
  // MARK: - WKScriptMessageHandler protocol
  public func userContentController(_ userContentController: WKUserContentController,
                                    didReceive message: WKScriptMessage) {
    if let jsCall = try? JSCall( message ) {
      call( jsCall)
    }
  }

  // MARK: - UIScrollViewDelegate protocol
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//      if let sd = startDragging {
//        if scrollView.isDragging {
//          let scrolled = sd-scrollView.contentOffset.y
//          let ratio = scrolled / scrollView.bounds.size.height
//          //debug("scrolled: \(scrolled), ratio = \(ratio)")
//        }
//      }
//  }
//
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    startDragging = scrollView.contentOffset.y
  }

  public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if let sd = startDragging {
      let scrolled = sd-scrollView.contentOffset.y
      let ratio = scrolled / scrollView.bounds.size.height
      if let closure = whenScrolledClosure, abs(ratio) >= scrollRatio {
        closure(ratio)
      }
    }
    startDragging = nil
    if let closure = whenDraggedClosure {
      let ratio = scrollView.contentOffset.y / scrollView.contentSize.height
      closure(ratio)
    }
  }
  
  // When dragging stops, check whether the end of content is visible  
  public func scrollViewWillEndDragging(_ scrollView: UIScrollView, 
    withVelocity velocity: CGPoint, 
    targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    if let closure = atEndOfContentClosure {
      let offset = targetContentOffset.pointee.y
      closure(isAtEndOfContent(offset: offset))
    }
  }

  
} // class WebView

/**
 An embedded WebView with a button at the bottom which is displayed when the 
 WebView has been scrolled to its vertical end. In addition a cross (or X) button 
 can be displayed using the "onX"-Method to define a closure that is called when 
 the X-Button has been pressed.
 */
open class ButtonedWebView: UIView {
  
  public class LabelButton: UIView, Touchable {
    public var tapRecognizer = TapRecognizer()
    public var label = UILabel()
    private var bwv: ButtonedWebView!
    public var text: String? { 
      get { label.text }
      set { label.text = newValue; bwv.adaptLayoutConstraints() }     
    }
    public var textColor: UIColor {
      get { label.textColor }
      set { label.textColor = newValue }
    }
    public var font: UIFont {
      get { label.font }
      set { label.font = newValue }
    }
    public var hasContent: Bool { text != nil }
    init(bwv: ButtonedWebView) {
      self.bwv = bwv
      super.init(frame: CGRect())
      self.addSubview(label)
      self.isUserInteractionEnabled = true
      label.backgroundColor = .clear
      pin(label.centerX, to: self.centerX)
      pin(label.centerY, to: self.centerY)
      pinHeight(50)
      pinWidth(250)
    }    
    required init?(coder: NSCoder) { super.init(coder: coder) }
  } 
  
  public var webView = WebView()
  /// The label acting as a button
  public lazy var buttonLabel = LabelButton(bwv: self)
  /// The X-Button (may be used to close the webview)
  public lazy var xButton = Button<CircledXView>()
  /// Distance between button and bottom as well as button and webview
  public var buttonMargin: CGFloat = 8 { didSet { adaptLayoutConstraints() } }
  private var isButtonVisible = false
  
  private var buttonBottomConstraint: NSLayoutConstraint?
  private var webViewBottomConstraint: NSLayoutConstraint?
  
  private var tapClosure: ((String)->())?
  private var xClosure: (()->())?
  
  /// This closure is called when the buttonLabel has been pressed
  public func onTap(closure: @escaping (String)->()) { tapClosure = closure }
  /// This closure is called when the X-Button has been pressed
  public func onX(closure: @escaping ()->()) {
    xClosure = closure
    xButton.isHidden = false
    xButton.onPress {_ in
      self.xClosure?()
    }
  }
  
  private func adaptLayoutConstraints() {
    let willShow = buttonLabel.hasContent && isButtonVisible
    let buttonDist = willShow ? -buttonMargin : buttonLabel.frame.height
    let webViewDist = willShow ? -buttonMargin : 0
    buttonBottomConstraint?.isActive = false
    webViewBottomConstraint?.isActive = false
    buttonBottomConstraint = pin(buttonLabel.bottom, to: self.bottom, dist: buttonDist)
    webViewBottomConstraint = pin(webView.bottom, to: buttonLabel.top, dist: webViewDist)
    layoutIfNeeded()
  }  
  
  private func adaptLayout(animated: Bool = false) {
    if animated {
      UIView.animate(seconds: 0.5) { [weak self] in 
        self?.adaptLayoutConstraints()
      }
    } 
    else { adaptLayoutConstraints() }
  }
  
  private func setup() {
    self.backgroundColor = .white
    self.addSubview(webView)
    self.addSubview(buttonLabel)
    self.addSubview(xButton)
    pin(webView.top, to: self.top)
    pin(webView.left, to: self.left)
    pin(webView.right, to: self.right)
    pin(buttonLabel.centerX, to: self.centerX)
    pin(xButton.right, to: self.right, dist: -15)
    pin(xButton.top, to: self.top, dist: 50)
    xButton.pinHeight(35)
    xButton.pinWidth(35)
    xButton.color = .black
    xButton.buttonView.isCircle = true
    xButton.buttonView.circleColor = UIColor.rgb(0xdddddd)
    xButton.buttonView.color = UIColor.rgb(0x707070)
    xButton.buttonView.innerCircleFactor = 0.5
    xButton.isHidden = true
    webView.atEndOfContent { [weak self] isAtEnd in
      guard let self = self else { return }
      if self.isButtonVisible != isAtEnd {
        self.isButtonVisible = isAtEnd
        self.adaptLayout(animated: true)
      }
    }
    buttonLabel.onTap { recog in self.tapClosure?(self.buttonLabel.text!) }
  }
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }
  
  public override func layoutSubviews() {
    adaptLayoutConstraints()
  }
}
