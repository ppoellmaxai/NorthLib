//
//  HttpSession.swift
//
//  Created by Norbert Thies on 16.05.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import UIKit

public extension URLRequest {
  /// Access request specific HTTP headers
  subscript(hdr: String) -> String? {
    get { return self.value(forHTTPHeaderField: hdr) }
    set { setValue(newValue, forHTTPHeaderField: hdr) }
  }
} // URLRequest


public extension URLResponse {
  /// Access response specific HTTP headers
  subscript(hdr: String) -> String? {
    get { 
      guard let resp = self as? HTTPURLResponse else { return nil }
      return resp.allHeaderFields[hdr] as? String
    }
  }
}  // URLResponse


/// Notifications sent for downloaded data
extension Notification.Name {
  public static let httpSessionDownload = NSNotification.Name("httpSessionDownload")
}


/** 
 A HttpSession uses Apple's URLSession to communicate with a remote
 server via HTTP(S). 
 
 Every HttpSession supports one or more HTTP(S) connections at the
 same time using the HttpConnection class.
 */
open class HttpSession: NSObject, URLSessionDelegate, URLSessionTaskDelegate,
  URLSessionDownloadDelegate, URLSessionDataDelegate, DoesLog {
  
  /// Error(s) that may be returned via Result<>
  public enum NetworkError: Swift.Error {
    case invalidURL(String)
    
    public var localizedDescription: String {
      switch self {
        case .invalidURL(let url): return "Invalid URL: \(url)"
      }
    }
  }
  
  /// Dictionary of background completion handlers 
  public static var bgCompletionHandlers: [String:()->()] = [:]
  
  // Optional name of (background) session
  fileprivate var name: String
  
  /// Session configuration
  public var config: URLSessionConfiguration { return session.configuration }
  
  /// URLSession
  public var session: URLSession!
  
  /// URLSessionTask
  public var task: URLSessionTask?
  
  // Closure to call upon GET/POST methods
  fileprivate var dataClosure: ((Result<Data?,Error>)->())?
  
  // Closure to call upon other methods
  fileprivate var finishedClosure: ((Error?)->())?
  
  // Data received via GET/POST
  fileprivate var data: Data?
  
  // Pathname of file downloading data to
  fileprivate var filename: String?

  // HTTP header to send with HTTP request
  public var header: [String:String] = [:]
  
  /// Set isInteractive to true if user is waiting for completion
  public var isInteractive: Bool {
    get { return self.config.networkServiceType == .responsiveData }
    set { self.config.networkServiceType = newValue ? .responsiveData : .background }
  }
  
  /// Set allowMobile to true to enable up/download on mobile networks
  public var allowMobile: Bool {
    get { return self.config.allowsCellularAccess }
    set { self.config.allowsCellularAccess = newValue }
  }
   
  /// Set waitForAvailability to true if a connection should wait for network availability
  public var waitForAvailability: Bool {
    get { return self.config.waitsForConnectivity }
    set { self.config.waitsForConnectivity = newValue }
  }
  
  /// Set doCache to true to enable caching
  public var doCache: Bool {
    get { return config.urlCache != nil ? true : false }
    set { 
      if newValue {
        config.urlCache = URLCache.shared
        config.requestCachePolicy = .useProtocolCachePolicy
      }
      else {
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
      }
    }
  }
  
  // notification handler called upon termination
  @objc fileprivate func onTermination() {
    debug("will shortly been terminated")
  }
  
  // notification handler called when loosing focus
  @objc fileprivate func onBackground() {
    debug("will go to background")
  }
  
  // Use a unique name to identify this session
  public init(name: String, isBackground: Bool = false) {
    self.name = name
    let config = isBackground ? 
      URLSessionConfiguration.background(withIdentifier: name) : 
      URLSessionConfiguration.default
    if isBackground {
      config.networkServiceType = .background
      config.isDiscretionary = true
    }
    else {
      config.networkServiceType = .responsiveData
      config.isDiscretionary = false
    }
    config.httpCookieStorage = HTTPCookieStorage.shared
    config.httpCookieAcceptPolicy = .onlyFromMainDocumentDomain
    config.httpShouldSetCookies = true
    config.urlCredentialStorage = URLCredentialStorage.shared
    config.sessionSendsLaunchEvents = true
    config.httpAdditionalHeaders = [:]
    config.waitsForConnectivity = true
    super.init()
    self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    doCache = false
    let nc = NotificationCenter.default
    nc.addObserver(self, selector: #selector(onBackground), 
      name: UIApplication.willResignActiveNotification, object: nil)
    nc.addObserver(self, selector: #selector(onTermination), 
      name: UIApplication.willTerminateNotification, object: nil)
  }
  
  // Factory method producing a background session
  static public func background(_ name: String) -> HttpSession {
    return HttpSession(name: name, isBackground: true)
  }
  
  // produce URLRequest from String url
  fileprivate func request(url: String) -> Result<URLRequest,Error> {
    guard let rurl = URL(string: url) else { 
      return .failure(error(NetworkError.invalidURL(url))) 
    }
    var req = URLRequest(url: rurl)
    for (key,val) in header {
      req[key] = val
    }
    return .success(req)
  }
  
  public func get(_ url: String, from: Int = 0, closure: @escaping(Result<Data?,Error>)->()) {
    let res = request(url: url)
    guard var req = try? res.get() else { closure(.failure(res.error()!)); return }
    req.httpMethod = "GET"
    if from != 0 { req["Range"] = "bytes=\(from)-" }
    task = session.dataTask(with: req)
    dataClosure = closure
    data = nil
    task!.resume()
  }
  
  // Notify completion of download
  fileprivate func notifyDownload(_ error: Error? = nil) {
    let nc = NotificationCenter.default
    let info: [String:Any] = [
      "error"   : error as Any,
      "url"     : self.task?.originalRequest?.url?.absoluteString as Any,
      "filename": self.filename as Any,
      "data"    : self.data as Any,
      "request" : self.task?.originalRequest as Any,
      "response": self.task?.response as Any
    ]
    nc.post(name: Notification.Name.httpSessionDownload, object: self, userInfo: info)   
  }
  
  // TODO: - HttpSession.download
  /**
   downloads data from an URL to a file, the closure is called for every
   ammount of data received from the remote host.
   
   Unlike HttpSession.get this method writes all data received to a file. While 
   data is received, the given closure (if given) will be called for every chunk
   of data got from the remote site.
  */
  func download(url: String, from: Int = 0, closure: ((Result<Data?,Error>)->())? = nil) {
  }

  
  // MARK: - URLSessionDelegate Protocol
  
  // Is called when all tasks are finished or cancelled
  public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
    logIf(error)
    debug("Session finished or cancelled")
  }
  
  // Background processing complete - call background completion handler
  public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    log("Background session '\(name)' finished")
    if let closure = HttpSession.bgCompletionHandlers[name] {
      // completion handler must be called on main queue
      DispatchQueue.main.async { closure() }
      HttpSession.bgCompletionHandlers[name] = nil
    }
  }
  
  // Authentication info is requested
  public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, 
      completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    debug("Session authentication challenge received: \(challenge.protectionSpace)")
    completionHandler(.performDefaultHandling, nil)
  }
  
  // MARK: - URLSessionTaskDelegate Protocol
  
  // Task has finished data transfer
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError err: Swift.Error?) {
    debug("Task finished data transfer")
    if let t = self.task { t.cancel() }
    var res: Result<Data?,Error>
    if err != nil { res = .failure(error(err!)) }
    else { res = .success(self.data) }
    if let closure = dataClosure { closure(res) }
    if let closure = finishedClosure { closure(err) }
    self.task = nil
    self.data = nil
    self.header = [:]
  }
  
  // Server requests "redirect" (not in background)
  public func urlSession(_ session: URLSession, task: URLSessionTask, 
                         willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, 
                         completionHandler: @escaping (URLRequest?) -> Void) {
    debug("Redirect to \(request.url?.absoluteString ?? "[unknown]") received")
    completionHandler(request)
  }
  
  // Upload: data sent to server
  public func urlSession(_ session: URLSession, task: URLSessionTask, 
                         didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    debug("Upload data: \(bytesSent) bytes sent, \(totalBytesSent) total bytes sent, \(totalBytesExpectedToSend) total size")
  }
  
  // Upload data: need more data
  public func urlSession(_ session: URLSession, task: URLSessionTask, 
                         needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
    debug("Upload data: need more data")
  }
  
  // Task authentication challenge received
  public func urlSession(_ session: URLSession, task: URLSessionTask, 
                         didReceive challenge: URLAuthenticationChallenge, 
                         completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    debug("Task authentication challenge received")
  }
  
  // Delayed background task is ready to run
  public func urlSession(_ session: URLSession, task: URLSessionTask, 
                         willBeginDelayedRequest request: URLRequest, 
                         completionHandler: @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
    debug("Delayed background task is ready to run")
    completionHandler(.continueLoading, nil)
  }
  
  // Task is waiting for network availability (may be reflected in the UI)
  public func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
    debug("Task is waiting for network availability")
  }
  
  // Task metrics received
  public func urlSession(_ session: URLSession, task: URLSessionTask, 
                         didFinishCollecting metrics: URLSessionTaskMetrics) {
    debug("Task metrics received")
  }
  
  // MARK: - URLSessionDownloadDelegate Protocol
  
  // Download has been finished
  public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, 
                         didFinishDownloadingTo location: URL) {
    debug("Download complete in: \(location)")
  }
  
  // Paused download has been resumed
  public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, 
                         didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
    debug("Resume paused Download")
  }
  
  // Data received and written to file
  public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, 
                         didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    debug("Data received: \(bytesWritten) bytes written to file")
  }
  
  // MARK: - URLSessionDataDelegate Protocol
  
  // Data received
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    debug("Data received: \(data.count) bytes")
    if self.data != nil { self.data!.append(data) }
    else { self.data = data }
  }
  
  // Data task was converted to download task
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, 
                         didBecome downloadTask: URLSessionDownloadTask) {
    debug("Data task converted to download task")
  }
  
  // Data task was converted to stream task
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, 
                         didBecome streamTask: URLSessionStreamTask) {
    debug("Data task converted to stream task")
  }
  
  // Initial reply from server received
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, 
    didReceive response: URLResponse, completionHandler: 
    @escaping (URLSession.ResponseDisposition) -> Void) {
    debug("Initial reply from server received: \((response as! HTTPURLResponse).statusCode)")
    completionHandler(.allow)
  }
  
  // Caching policy requested
  public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, 
                         willCacheResponse proposedResponse: CachedURLResponse, completionHandler: 
    @escaping (CachedURLResponse?) -> Void) {
    debug("Caching policy requested")
    completionHandler(proposedResponse)
  }

} // HttpSession
