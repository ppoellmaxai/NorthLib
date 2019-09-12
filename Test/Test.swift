//
//  Test.swift
//
//  Created by Norbert Thies on 30.08.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import XCTest
extension XCTestCase: DoesLog {}

@testable import NorthLib

class MathTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testRemainder() {
    XCTAssertFalse(1.000001 =~ 1.000002)
    XCTAssertTrue((3.6 % 0.5) =~ 0.1)
    XCTAssertTrue((3.6 /~ 0.5) =~ 7.0)
  }
  
} // class MathTests

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
