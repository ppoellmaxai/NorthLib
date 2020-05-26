//
//  Specifications.swift
//
//  Created by Norbert Thies on 25.05.20.
//  Copyright © 2020 Norbert Thies, Ringo Müller. All rights reserved.
//

import UIKit

/// An Image with a smaller "Waiting Image"
public protocol OptionalImage {
  /// The main image to display
  var image: UIImage { get }
  /// An alternate image to display when the main image is not yet available
  var waitingImage: UIImage { get }
  /// Returns true if 'image' is available
  var isAvailable: Bool { get }
  /// Defines a closure to call when the main image becomes available
  func whenAvailable(closure: @escaping ()->())
}

/**
 A ZoomedImageView presents an Image in an ImageView that is scrollable
 and zoomable.
 
 It consists of an ImageView managed by a ScrollView and an additional x-shaped
 button which may be used to terminate the ImageView. The button is only visible
 when a closure is defined that is called when the button has been pressed.
 
 The ImageView displays an OptionalImage. If the main image is available, zooming
 and scrolling of that image is enabled. Initially the image is sized and 
 positioned so that it is completely visible but couldn't be enlarged without 
 cropping a part of the image. If the main image is not available, the waiting image 
 is displayed without being zoomable or scrollable and a spinner is shown in
 the centre of the view.
 
 If the main image is displayed a double tap either enlarges the image so that
 its resolution matches the resolution of the screen or (if already enlarged) 
 it is shrinked to its initial size and position.
 */
public protocol ZoomedImageViewSpec where Self: UIView
  /* Self: UIContextMenuInteractionDelegate */ {
  /// The scrollview managing the ImageView
  var scrollView: UIScrollView { get }
  /// The Imageview displaying either the main or the waiting image
  var imageView: UIImageView { get }
  /// The image to display
  var optionalImage: OptionalImage { get }
  /// The X-Button (may be used to close the ZoomedImageView)
  var xButton: Button<CircledXView> { get }
  // Spinner indicating activity if !OptionalImage.isAvailable
  var spinner: UIActivityIndicatorView { get }
  /// The context menu to display
  var menu: ContextMenu { get }
  
  /// Initialize with optional image, displays the main image if available.
  /// Otherwise the waiting image is displayed and via 'whenAvailable' a closure
  /// is defined to replace the waiting image with the main image (when it is available)
  init(optionalImage: OptionalImage)
  
  /// Define closure to call when the X-Button is pressed
  func onX(closure: @escaping ()->())
}

public extension ZoomedImageViewSpec {
  
  /// This closure is called when the X-Button has been pressed
  func onX(closure: @escaping ()->()) {
    xButton.isHidden = false
    xButton.onPress {_ in closure() }
  }
  
  /// Setup the xButton
  func setupXButton() {
    xButton.pinHeight(35)
    xButton.pinWidth(35)
    xButton.color = .black
    xButton.buttonView.isCircle = true
    xButton.buttonView.circleColor = UIColor.rgb(0xdddddd)
    xButton.buttonView.color = UIColor.rgb(0x707070)
    xButton.buttonView.innerCircleFactor = 0.5
    self.addSubview(xButton)
    pin(xButton.right, to: self.right, dist: -15)
    pin(xButton.top, to: self.top, dist: 50)
    xButton.isHidden = true
  }
  
  /// Setup the spinner
  func setupSpinner() {
    if #available(iOS 13, *) { 
      spinner.style = .large 
      spinner.color = .black
    }
    else { spinner.style = .whiteLarge }
    spinner.hidesWhenStopped = true
    addSubview(spinner)
    pin(spinner.centerX, to: self.centerX)
    pin(spinner.centerY, to: self.centerY)
    self.bringSubviewToFront(spinner)
  }
    
} // ZoomedImageViewSpec
