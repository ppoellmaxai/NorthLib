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
  private var _whenScrolled: ((CGFloat)->())?
  private var _scrollRatio: CGFloat = 0
  
  /// Define closure to call when web content has been scrolled
  public func whenScrolled( minRatio: CGFloat, _ closure: @escaping (CGFloat)->() ) {
    _scrollRatio = minRatio
    _whenScrolled = closure
  }
  
  // The closure to call when some dragging (scrolling) has been done
  private var _whenDragged: ((CGFloat)->())?

  /// Define closure to call when web content has been dragged, the value passed
  /// is the number of points scrolled down divided by the content's height
  public func whenDragged(closure: @escaping (CGFloat)->()) {
    _whenDragged = closure
  }
  
  // content y offset at start of dragging
  private var startDragging: CGFloat?
  
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
  
  override public init(frame: CGRect, configuration: WKWebViewConfiguration) {
    super.init(frame: frame, configuration: configuration)
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
      if let closure = _whenScrolled, abs(ratio) >= _scrollRatio {
        closure(ratio)
      }
    }
    startDragging = nil
    if let closure = _whenDragged {
      let ratio = scrollView.contentOffset.y / scrollView.contentSize.height
      closure(ratio)
    }
  }
  
} // class WebView
