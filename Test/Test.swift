//
//  Test.swift
//
//  Created by Norbert Thies on 30.08.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import XCTest
extension XCTestCase: DoesLog {}

@testable import NorthLib

class EtcTests: XCTestCase {
  override func setUp() { super.setUp() }  
  override func tearDown() { super.tearDown() }

  func testTmppath() {
    let p1 = tmppath(), p2 = tmppath(), p3 = tmppath()
    print(p1, p2, p3)
    XCTAssertNotEqual(p1, p2)
    XCTAssertNotEqual(p2, p3)
  } 
  
  func testArray() {
    let a1 = [1,2,3,4,5,6,7,8,9,10]
    XCTAssertEqual(a1.rotated(1), [2,3,4,5,6,7,8,9,10,1])
    XCTAssertEqual(a1.rotated(-1), [10,1,2,3,4,5,6,7,8,9])
    XCTAssertEqual(a1.rotated(2), [3,4,5,6,7,8,9,10,1,2])
    XCTAssertEqual(a1.rotated(-2), [9,10,1,2,3,4,5,6,7,8])
  }
  
} // class EtcTests

class MathTests: XCTestCase {  
  override func setUp() { super.setUp() }  
  override func tearDown() { super.tearDown() }
  
  func testRemainder() {
    XCTAssertFalse(1.000001 =~ 1.000002)
    XCTAssertTrue((3.6 % 0.5) =~ 0.1)
    XCTAssertTrue((3.6 /~ 0.5) =~ 7.0)
  }
  
  func testLog() {
    let a: Double = 4
    XCTAssertTrue(a.log(base: 2) =~ 2.0)
  }
  
  func testGcd() {
    XCTAssertEqual(gcd(2,3), 1)
    XCTAssertEqual(gcd([]), 1)
    XCTAssertEqual(gcd([3]), 3)
    XCTAssertEqual(gcd([2,3]), 1)
    XCTAssertEqual(gcd([2,4,8]), 2)
    XCTAssertEqual(gcd([8,16,4]), 4)
  }
  
} // class MathTests

class StringTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    print("nodename: \(Utsname.nodename)")
    print("sysname:  \(Utsname.sysname)")
    print("release:  \(Utsname.release)")
    print("version:  \(Utsname.version)")
    print("machine:  \(Utsname.machine)")
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testQuote() {
    var s = "a \"test\"\n and a \\ followed by \r, \t"
    XCTAssertEqual(s.quote(), "\"a \\\"test\\\"\\n and a \\\\ followed by \\r, \\t\"")
    XCTAssertEqual(s,s.quote().dequote())
    s = "number: "
    s += 14
    XCTAssertEqual(s,"number: 14")
  }
  
  func testIndent() {
    let s = "This is a string"
    XCTAssertEqual(s.indent(by:0), s)
    XCTAssertEqual(s.indent(by:1), " This is a string")
    XCTAssertEqual(s.indent(by:2), "  This is a string")    
    XCTAssertEqual(s.indent(by:3), "   This is a string")  
  }
  
  func testGroupMatches() {
    let s = "12:18:22 17:30:45"
    let re = #"(\d+):(\d+):(\d+)"#
    let ret = s.groupMatches(regexp:re)
    XCTAssertEqual(ret[0], ["12:18:22", "12", "18", "22"])
    XCTAssertEqual(ret[1], ["17:30:45", "17", "30", "45"])
    XCTAssertEqual("<123> <456>".groupMatches(regexp: #"<(\d+)>"#), [["<123>", "123"], ["<456>", "456"]])
    XCTAssertEqual("<123>".groupMatches(regexp: #"<(1(\d+))>"#), [["<123>", "123", "23"]])
  }

  func testMultiply() {
    XCTAssertEqual("abc" * 3, "abcabcabc")
    XCTAssertEqual("abc" * 0, "")
    XCTAssertEqual("abc" * 1, "abc")
    XCTAssertEqual(3 * "abc", "abc" * 3)
  }
  
}

class UsTimeTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testIsoConversion() {
    XCTAssertEqual(UsTime(iso: "2019-10-09 13:44:56").toString(), "2019-10-09 13:44:56.000000")
    XCTAssertEqual(UsTime(iso: "2019-10-09 13:44:56.123").toString(), "2019-10-09 13:44:56.123000")
    XCTAssertEqual(UsTime(iso: "2019-10-09 13:44:56.123", tz: "Europe/London").toString(tz: "Europe/London"),
                   "2019-10-09 13:44:56.123000")
    XCTAssertEqual(UsTime(iso: "2019-10-09").toString(), "2019-10-09 12:00:00.000000")
  }
  
}

class ZipTests: XCTestCase {
  
  var zipStream: ZipStream = ZipStream()
  var nerrors: Int = 0
  
  override func setUp() {
    super.setUp()
    Log.minLogLevel = .Debug
    self.zipStream.onFile { (name, data) in
      print( "file \(name!) with \(data!.count) bytes content found" )
      switch name! {
      case "a.txt": 
        if data!.md5 != "3740129b68388b4f41404d93ae27a79c" {
          print( "error: md5 sum doesn't match" )
          self.nerrors += 1
        }
      case "b.txt": 
        if data!.md5 != "abeecdc0f0a02c2cd90a1555622a84a4" {
          print( "error: md5 sum doesn't match" )
          self.nerrors += 1
        }
      default:
        print( "error: unexpected file" )
        self.nerrors += 1
      }
    }    
  }
  
  override func tearDown() {
    super.tearDown()
  }
    
  func testZipStream() {
    let bundle = Bundle( for: type(of: self) )
    guard let testPath = bundle.path(forResource: "test", ofType: "zip")
      else { return }
    guard let fd = FileHandle(forReadingAtPath: testPath)
      else { return }
    var data: Data
    repeat {
      data = fd.readData(ofLength: 10)
      if data.count > 0 {
        self.zipStream.scanData(data)
      }
    } while data.count > 0
    XCTAssertEqual(self.nerrors, 0)
    self.zipStream = ZipStream()
    nerrors = 0
  }
  
} // class ZipTests

class DefaultsTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    Log.minLogLevel = .Debug
    Defaults.suiteName = "taz"
    Defaults.Notification.addObserver { (key, val, scope) in
      print("Notification: \(key)=\"\(val ?? "nil")\" in scope \"\(scope ?? "nil")\"")
    }
    let iPhoneDefaults: [String:String] = [
      "key1" : "iPhone-value1",
      "key2" : "iPhone-value2"
    ]
    let iPadDefaults: [String:String] = [
      "key1" : "iPad-value1",
      "key2" : "iPad-value2"
    ]
    Defaults.singleton.setDefaults(values: Defaults.Values(scope: "iPhone", values: iPhoneDefaults))
    Defaults.singleton.setDefaults(values: Defaults.Values(scope: "iPad", values: iPadDefaults))
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testDefaults() {
    let dfl = Defaults.singleton
    dfl[nil,"test"] = "non scoped"
    dfl["iPhone","test"] = "iPhone"
    dfl["iPad","test"]   = "iPad"
    XCTAssertEqual(dfl[nil,"test"], "non scoped")
    Defaults.print()
    if Device.isIphone {
      XCTAssertEqual(dfl["test"], "iPhone")
      XCTAssertEqual(dfl["key1"], "iPhone-value1")
      XCTAssertEqual(dfl["key2"], "iPhone-value2")
    }
    else if Device.isIpad {
      XCTAssertEqual(dfl["test"], "iPad")      
      XCTAssertEqual(dfl["key1"], "iPad-value1")
      XCTAssertEqual(dfl["key2"], "iPad-value2")
    }
  }

} // class DefaultsTest

class KeychainTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    Log.minLogLevel = .Debug
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testKeychain() {
    let kc = Keychain.singleton
    if let pw = kc["geheim"] { print("geheim = \"\(pw)\"") }
    kc["geheim"] = "huhu"
    XCTAssertEqual(kc["geheim"], "huhu")      
    kc["geheim"] = nil
    XCTAssertNil(kc["geheim"])
    kc["geheim"] = "fiffi"
  }

} // class DefaultsTest
class FileTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    Log.minLogLevel = .Debug
    print("homePath:       \(Dir.homePath)")
    print("documentsPath:  \(Dir.documentsPath)")
    print("inboxPath:      \(Dir.inboxPath)")
    print("appSupportPath: \(Dir.appSupportPath)")
    print("cachePath:      \(Dir.cachePath)")
    print("tmpPath:        \(Dir.tmpPath)")
  }
  
  override func tearDown() {
    super.tearDown()
    Dir("\(Dir.tmpPath)/a").remove()
  }
  
  func testFile() {
    let d = Dir("\(Dir.tmpPath)/a")
    let d1 = Dir("\(Dir.tmpPath)/a/b.1")
    let d2 = Dir("\(Dir.tmpPath)/a/c.2")
    d.remove()
    XCTAssert(!d1.exists)
    XCTAssert(!d2.exists)
    d1.create(); d2.create()
    XCTAssert(d1.exists)
    XCTAssert(d1.isDir)
    XCTAssert(!d1.isFile)
    XCTAssert(!d1.isLink)
    let dirs = d.scan(isAbs: false)
    XCTAssert(dirs.count == 2)
    XCTAssert(dirs.contains("b.1"))
    XCTAssert(dirs.contains("c.2"))
    d1.remove()
    XCTAssert(!d1.exists)
    XCTAssert(d1.basename == "b.1")
    XCTAssert(d1.dirname == d.path)
    XCTAssert(d1.progname == "b")
    XCTAssert(d1.extname == "1")
    var f = File("\(d2.path)/test")
    File.open(path: f.path, mode: "a") { file in
      file.writeline("a test")
    }
    File.open(path: f.path, mode: "r") { file in
      let str = file.readline()
      XCTAssert(str == "a test\n")
    }
    let dpath = "\(d1.path)/new"
    let fpath = "\(dpath)/test"
    Dir(dpath).create()
    f.move(to: fpath)
    f = File(fpath)
    XCTAssert(f.exists)
    XCTAssert(f.isFile)
  }
  
} // FileTests
