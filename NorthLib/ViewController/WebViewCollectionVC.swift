//
//  WebViewCollectionVC.swift
//
//  Created by Norbert Thies on 06.08.18.
//  Copyright © 2018 Norbert Thies. All rights reserved.
//

import UIKit
import WebKit

/// An URL with a waiting view that is to display if the URL is not yet available
public protocol WebViewUrl {
  var url: URL { get }
  var isAvailable: Bool { get }
  func whenAvailable(closure: @escaping ()->())
  func waitingView() -> UIView?
}

/// An optional WebView using a "waiting view" as long as the web contents is not available
struct OptionalWebView: OptionalView {
  
  var url: WebViewUrl
  var webView: WebView?
  
  var isAvailable: Bool { return url.isAvailable }
  func whenAvailable(closure: @escaping () -> ()) { url.whenAvailable(closure: closure) }
  var waitingView: UIView? { return url.waitingView() }
  var mainView: UIView { return webView ?? UndefinedView() }
  func loadView() { if isAvailable { webView?.load(url: url.url) } }
  
  init(vc: WebViewCollectionVC, url: WebViewUrl) {
    self.url = url
    let webConfiguration = WKWebViewConfiguration()
    self.webView = WebView(frame: .zero, configuration: webConfiguration)
    guard let webView = self.webView else { return }
    webView.uiDelegate = vc
    webView.navigationDelegate = vc
    webView.allowsBackForwardNavigationGestures = false
    webView.scrollView.isDirectionalLockEnabled = true
    webView.scrollView.showsHorizontalScrollIndicator = false
    webView.baseDir = vc.baseDir
    webView.whenScrolled(minRatio: 0.05) { [weak vc] ratio in
      vc?.didScroll(ratio: ratio)
    }
  }
  
} // OptionalWebView

/// A very simple file based WebViewUrl
public struct FileUrl: WebViewUrl {
  public var url: URL
  public var path: String { return url.path }
  public var isAvailable: Bool { return File(path).exists }
  public func whenAvailable(closure: ()->()) {}
  public func waitingView() -> UIView? { return nil }
  public init(path: String) { self.url = URL(fileURLWithPath: path) }
}

/// A WebViewCollectionVC manages a hoizontal collection of web views
open class WebViewCollectionVC: PageCollectionVC, WKUIDelegate,
  WKNavigationDelegate {
    
  /// The list of URLs to display in WebViews
  public var urls: [WebViewUrl] = []
  public var baseDir: String?
  public var current: WebViewUrl? { 
    if let i = index { return urls[i] }
    else { return nil }
  }
  fileprivate var initialUrl: URL?
  
  public var currentWebView: WebView? { return currentView as? WebView }
  
  // The closure to call when link is pressed
  private var _whenLinkPressed: ((URL,URL)->())?
  
  /// Define closure to call when link is pressed
  public func whenLinkPressed( _ closure: @escaping (URL,URL)->() ) {
    _whenLinkPressed = closure
  }
  
  // The closure to call when the webview has been scrolled more than 5%
  private var _whenScrolled: ((CGFloat)->())?
  
  /// Define closure to call when more than 5% has b een scrolled
  public func whenScrolled(_ closure: ((CGFloat)->())?) {
    _whenScrolled = closure
  }
  
  /// Scroll of WebView detected
  public func didScroll(ratio: CGFloat) { 
    guard let closure = _whenScrolled else { return }
    closure(ratio)
  }
  
  public func displayUrls(urls: [WebViewUrl]? = nil) {
    if let urls = urls { self.urls = urls }
    self.count = self.urls.count
    if let iurl = initialUrl {
      initialUrl = nil
      gotoUrl(url: iurl)
    }
  }
  
//  public func displayFiles(path: String, files: [String]) {
//    urls = []
//    for f in files {
//      let url = FileUrl(path: path + "/" + f)
//      urls.append(url)
//    }
//    self.count = urls.count
//  }
//  
//  public func displayFiles( path: String, files: String... ) {
//    displayFiles(path: path, files: files)
//  }
  
  public func gotoUrl(url: URL) {
    if urls.count == 0 { self.initialUrl = url; return }
    var idx = 0
    debug("searching for: \(url.lastPathComponent)")
    for u in urls {
      if u.url == url { 
        self.index = idx 
        debug("found at index: \(idx)")
        return 
      }
      idx += 1
    }
    debug("not found")
  }
  
  public func gotoUrl(_ url: String) {
    let url = URL(fileURLWithPath: url)
    gotoUrl(url: url)
  }
  
  public func gotoUrl(path: String, file: String) { 
    gotoUrl(path + "/" + file)
  }
  
  open override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.white
    inset = 0
    viewProvider { [weak self] (index) in
      guard let this = self else { return UIView() }
      return OptionalWebView(vc: this, url: this.urls[index])
    }
  }
  
  public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//    if let wview = webView as? WebView {
//      debug("Webview loaded: \(wview.url?.lastPathComponent ?? "[undefined URL]")")
//    }
  }
  
   public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
//     if let wview = webView as? WebView {
//       debug("Webview loading: \(wview.url?.lastPathComponent ?? "[undefined URL]")")
//     }
   }
  
  public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, 
                      withError err: Error) {
    if let wview = webView as? WebView {
      error("WebView Error on \"\(wview.originalUrl?.lastPathComponent ?? "[undefined URL]")\": \(err.description)")
    }
  }
  
  public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, 
                      withError err: Error) {
    if let wview = webView as? WebView {
      error("WebView Error on \"\(wview.originalUrl?.lastPathComponent ?? "[undefined URL]")\": \(err.description)")
    }
  }
  
  public func webView(_ webView: WKWebView, decidePolicyFor nav: WKNavigationAction,
                      decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    //debug("\(nav.toString())")
    if let url = nav.request.url {
      let type = nav.navigationType
      if type == .linkActivated {
        if let closure = _whenLinkPressed { 
          closure(webView.url!, url) 
          decisionHandler(.cancel)
          return
        }
      }
    }
    decisionHandler(.allow)
  }
  
  override public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//    debug(scrollView.contentOffset.toString())
//    if scrollView.contentOffset.x > 0
//      { scrollView.contentOffset = CGPoint(x: 0, y: scrollView.contentOffset.y) }
  }
  
  public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
               initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
    let ac = UIAlertController(title: "JavaScript", message: message,
               preferredStyle: UIAlertController.Style.alert)
    ac.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel) { _ in
      completionHandler() })
    self.present(ac, animated: true)
  }

}
