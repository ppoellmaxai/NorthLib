//
//  Test.swift
//
//  Created by Norbert Thies on 30.08.19.
//  Copyright © 2019 Norbert Thies. All rights reserved.
//

import XCTest
@testable import NorthLib

class MathTests: XCTestCase, DoesLog {
  
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
  
}

class ZipTests: XCTestCase, DoesLog {
  
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
  
}
