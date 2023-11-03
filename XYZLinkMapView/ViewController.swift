//
//  ViewController.swift
//  XYZLinkMapView
//
//  Created by 大大东 on 2023/11/2.
//

import Cocoa

class ViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let res = FileParser.parse(file: URL(fileURLWithPath: "/Users/dadadongl/Desktop/UniTok-LinkMap-normal-arm64.txt"))
        print("")
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
