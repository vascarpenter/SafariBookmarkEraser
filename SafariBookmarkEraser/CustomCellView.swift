//
//  CustomCellView.swift
//  SafariBookmarkEraser
//
//  Created by gikoha on 2022/03/25.
//

import Cocoa

protocol CatchProtocol {
    func catchRemoveButton(row:Int)
}

class CustomCellView: NSTableCellView
{
    var delegate: CatchProtocol?

    @IBOutlet weak var titleField: NSTextField!
    @IBOutlet weak var urlField: NSTextField!
    @IBOutlet weak var resultField: NSTextField!
    @IBOutlet weak var checkBox: NSButton!
    var row: Int=0

    @IBAction func removeButtonPushed(_ sender: NSButton) {
        delegate?.catchRemoveButton(row: self.row)
    }

    override func draw(_ dirtyRect: NSRect)
    {
        super.draw(dirtyRect)

        // Drawing code here.
    }
}

