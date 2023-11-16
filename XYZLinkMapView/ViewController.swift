//
//  ViewController.swift
//  XYZLinkMapView
//
//  Created by 大大东 on 2023/11/2.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var indicator: NSProgressIndicator!
    @IBOutlet var pathTextFiled: NSTextField!
    @IBOutlet var listView: NSOutlineView!
    @IBOutlet var startBtn: NSButton!

    private var parsedLinkMap: LinkMap?
    private var datas = [LinkMap.ObjectFile]()

    override func viewDidLoad() {
        super.viewDidLoad()

        indicator.isHidden = true
        listView.delegate = self
        listView.dataSource = self
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    private func loading(_ show: Bool) {
        if show {
            indicator.startAnimation(nil)
            indicator.isHidden = false
        } else {
            indicator.stopAnimation(nil)
            indicator.isHidden = true
        }
    }

    private func toast(_ text: String) {
        let v = NSText(frame: .zero)
        v.string = text
        v.textColor = NSColor.white
        v.font = NSFont.systemFont(ofSize: 20)
        v.backgroundColor = NSColor.black.withAlphaComponent(0.8)
        v.alignment = .center
        view.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        v.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        v.widthAnchor.constraint(equalToConstant: 200).isActive = true
        v.heightAnchor.constraint(equalToConstant: 40).isActive = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: DispatchWorkItem(block: {
            v.removeFromSuperview()
        }))
    }
}

extension ViewController {
    @IBAction func selectFileBtnAction(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.begin { [weak self] res in
            guard let self = self,
                  res == .OK,
                  let url = panel.urls.first,
                  let values = try? url.resourceValues(forKeys: [.isDirectoryKey]),
                  values.isDirectory == false
            else {
                return
            }

            self.pathTextFiled.stringValue = url.path
        }
    }

    @IBAction func startBtnAction(_ sender: NSButton) {
        guard pathTextFiled.stringValue.isEmpty == false else {
            self.toast("请先选择文件")
            return
        }

        loading(true)
        let url = URL(fileURLWithPath: self.pathTextFiled.stringValue)
        DispatchQueue.global().async {
            let res = FileParser.parse(file: url)
            DispatchQueue.main.async {
                self.loading(false)
                self.parsedLinkMap = res
                if let res = res {
                    self.datas = res.objectFiles.map { $0.value }
                    self.listView.reloadData()
                } else {
                    self.datas = []
                    self.toast("解析失败")
                }
            }
        }
    }
}

extension ViewController: NSOutlineViewDelegate, NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        // 返回指定 item 的子项数目
        if let item = item as? LinkMap.ObjectFile {
            return item.symbols.count
        }

        return datas.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        // 返回指定 item 的第 index 个子项
        if let item = item as? LinkMap.ObjectFile {
            return item.symbols[index]
        }

        return datas[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        // 检查 item 是否可以展开
        if let item = item as? LinkMap.ObjectFile {
            return item.symbols.isEmpty == false
        }
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        // 返回用于显示指定 item 的视图
        guard let tableColumn = tableColumn else { return nil }
        let reuseid = NSUserInterfaceItemIdentifier(rawValue: "cell")
        var cell = outlineView.makeView(withIdentifier: reuseid, owner: nil) as! NSTableCellView

        if let item = item as? LinkMap.ObjectFile {
            cell.textField?.stringValue = tableColumn.identifier.rawValue == "name" ? item.name : "\(item.size)"
        } else if let item = item as? LinkMap.ObjectFile.Symbol {
            cell.textField?.stringValue = tableColumn.identifier.rawValue == "name" ? item.text : "\(item.size)"
        }

        return cell
    }
}
