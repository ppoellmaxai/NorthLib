//
//  ConcreteButtons.swift
//
//  Created by Norbert Thies on 20.07.16.
//  Copyright © 2016 Norbert Thies. All rights reserved.
//
//  This file implements some buttons and switches that may be used in Interface
//  Builder. At least up until 2019 it's not possible to use generic views, therefore
//  concrete classes must be used.
//

import UIKit


@IBDesignable
public class BookmarkSwitch: SwitchControl {
  var buttonView: BookmarkView { return super.view as! BookmarkView }
  init( frame: CGRect ) { super.init( view: BookmarkView(), frame: frame ) }
  convenience init( width: CGFloat = 30, height: CGFloat = 30 ) {
    self.init( frame: CGRect(x: 0, y: 0, width: width, height: height) )
  }
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.view = BookmarkView(frame:self.bounds)
    setup()
  }
}

@IBDesignable
public class SelectionButton: ButtonControl {
  var buttonView: SelectionView { return super.view as! SelectionView }
  init( frame: CGRect ) { super.init( view: SelectionView(), frame: frame ) }
  convenience init( width: CGFloat = 30, height: CGFloat = 30 ) {
    self.init( frame: CGRect(x: 0, y: 0, width: width, height: height) )
  }
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.view = SelectionView(frame:self.bounds)
    setup()
  }
}

@IBDesignable
public class ExportButton: ButtonControl {
  var buttonView: ExportView { return super.view as! ExportView }
  init( frame: CGRect ) { super.init( view: ExportView(), frame: frame ) }
  convenience init( width: CGFloat = 30, height: CGFloat = 30 ) {
    self.init( frame: CGRect(x: 0, y: 0, width: width, height: height) )
  }
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.view = ExportView(frame:self.bounds)
    setup()
  }
}

@IBDesignable
public class ImportButton: ButtonControl {
  var buttonView: ImportView { return super.view as! ImportView }
  init( frame: CGRect ) { super.init( view: ImportView(), frame: frame ) }
  convenience init( width: CGFloat = 30, height: CGFloat = 30 ) {
    self.init( frame: CGRect(x: 0, y: 0, width: width, height: height) )
  }
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.view = ImportView(frame:self.bounds)
    setup()
  }
}
