//
//  ViewController.swift
//  SafariBookmarkEraser
//
//  Created by gikoha on 2022/03/25.
//
// 起動前に 環境設定のセキュリティ＆プライバシーから、フルディスクアクセス>SafariBookmarkEraserをチェックする必要があります

import Cocoa

struct URLList {
    var title : String
    var url : String
    var result : String
    var accessible : Bool
    var check : Bool
    var uuid : String
}

class ViewController: NSViewController,NSTableViewDelegate,NSTableViewDataSource,CatchProtocol
{

    var bookmarks: [URLList] = []
    @IBOutlet weak var myTableView: NSTableView!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var saveButton: NSButton!
    
    var finished: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        (NSApplication.shared.delegate as! AppDelegate).vc = self

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return bookmarks.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MyTableCell"), owner: self) as? CustomCellView
        cell?.titleField.stringValue = bookmarks[row].title
        cell?.urlField.stringValue = bookmarks[row].url
        cell?.resultField.stringValue = bookmarks[row].result
        if bookmarks[row].check == true
        {
            cell?.checkBox.state = NSControl.StateValue.on
        }
        else
        {
            cell?.checkBox.state = NSControl.StateValue.off
        }

        cell?.row = row             // you can't set tag because read only
        cell?.delegate = self       // for catchSelect/Print method
        return cell

    }
    
    func catchRemoveButton(row: Int)
    {
        // delegate method: clicked Remove button in row
        self.bookmarks[row].check = !self.bookmarks[row].check
        self.myTableView.reloadData()
    }
    
    func parseChildren(array: NSArray)
    {
        for v1 in array
        {
            let v1d = v1 as! NSDictionary
            let type = v1d.object(forKey: "WebBookmarkType") as! String
            if type == "WebBookmarkTypeLeaf"
            {
                let titled = v1d.value(forKey: "URIDictionary") as! NSDictionary
                let title = titled.value(forKey: "title") as! String
                let urls = v1d.value(forKey: "URLString") as! String
                let uuid = v1d.value(forKey: "WebBookmarkUUID") as! String
                //WebBookmarkTypeListなら再帰的に..
                let oneurl = URLList(title:title, url:urls, result:"", accessible: false, check: true, uuid: uuid)
                bookmarks.append(oneurl)
            }
            else if type == "WebBookmarkTypeList"
            {
                // bookmark folder
                
                // let title = v1d.value(forKey: "Title") as! NSString
                if let hasChildren = v1d.object(forKey:"Children")
                {
                    parseChildren(array: hasChildren as! NSArray)
                }
            }
            
        }
    }
    
    func parseChildrenAsSave(array: NSMutableArray) -> Bool
    {
        var removearray: [Int] = []
        for (index,v1) in array.enumerated()
        {

            let v1d = v1 as! NSMutableDictionary
            let type = v1d.object(forKey: "WebBookmarkType") as! String
            if type == "WebBookmarkTypeLeaf"
            {
                let uuid = v1d.value(forKey: "WebBookmarkUUID") as! String
                
                for b in bookmarks
                {
                    if b.check == true && b.uuid == uuid
                    {
                        // mark as "delete"; cannot delete within for loop
                        removearray.append(index)
                        break
                    }
                }
            }
            else if type == "WebBookmarkTypeList"
            {
                // let title = v1d.value(forKey: "Title") as! NSString
                if let hasChildren = v1d.object(forKey:"Children")
                {
                    // folder; recursive
                    if parseChildrenAsSave(array: hasChildren as! NSMutableArray)
                    {
                        v1d.setValue(hasChildren, forKey: "Children")
                    }
                }
            }
            
        }
        
        if removearray.count > 0
        {
            let removeset = IndexSet(removearray)
            array.removeObjects(at: removeset)
            return true  // array changed
        }
        
        return false  // array unchanged
    }
    
    func accessURL(row: Int)
    {
        let request = URLRequest(url: URL(string: bookmarks[row].url)!)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)

        session.dataTask(with: request) { (data, response, error) in
            
            if error == nil, let response = response as? HTTPURLResponse
            {
                if response.statusCode >= 400
                {   // 404 Not found.. etc
                    self.bookmarks[row].result = String(response.statusCode)
                    self.bookmarks[row].accessible = false
                }
                else
                {
                    self.bookmarks[row].result = "OK"
                    self.bookmarks[row].accessible = true
                }
            }
            else
            {
                let errmsg = (error! as NSError).localizedDescription
                self.bookmarks[row].result = errmsg
                self.bookmarks[row].accessible = false
            }
            self.bookmarks[row].check = !self.bookmarks[row].accessible
            
            // show progress bar; one session finished
            DispatchQueue.main.async
            {   // GUI parts runs only in main thread
                self.progressBar.doubleValue = (self.progressBar.doubleValue)+1
                if self.progressBar.doubleValue >= self.progressBar.maxValue
                {
                    self.saveButton.isEnabled = true
                }
                self.myTableView.reloadData()
            }

        }.resume()
    }
    
    @IBAction func saveButton(_ sender: Any)
    {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let sourceURL = homeURL.appendingPathComponent("Library/Safari/Bookmarks.plist")
        var plist : NSMutableDictionary = [:]
        
        do
        {
            plist = try NSMutableDictionary(contentsOf: sourceURL,
                                      error:())
        }
        catch
        {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "This program needs full disk access for accessing Safari's Bookmark.plist\n"
            + "(Set System Prefs > Security & Privacy > Privacy > Full Disk Access)"
            alert.addButton(withTitle: "OK")
            let _ = alert.runModal()
            return
        }
        
        for(key,value) in plist
        {
            if key as! String == "Children"
            {
                if parseChildrenAsSave(array: value as! NSMutableArray)
                {
                    plist.setValue(value, forKey: "Children")
                }
                
            }
        }
        let destURL = homeURL.appendingPathComponent("Desktop/Bookmarks.plist")
        try! plist.write(to: destURL)
    }
    
    @IBAction func startButton(_ sender: Any)
    {
        bookmarks = []
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let sourceURL = homeURL.appendingPathComponent("Library/Safari/Bookmarks.plist")
        _ = sourceURL.startAccessingSecurityScopedResource()
        
        var plist : NSMutableDictionary = [:]
        do
        {
            plist = try NSMutableDictionary(contentsOf: sourceURL,
                                            error:())
        }
        catch
        {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.messageText = "This program needs full disk access for accessing Safari's Bookmark.plist\n"
                + "(Set System Prefs > Security&Privacy > Privacy > FullDiskAccess)"
            alert.addButton(withTitle: "OK")
            let _ = alert.runModal()
            return
        }
        sourceURL.stopAccessingSecurityScopedResource()
        
        for(key,value) in plist
        {
            if key as! String == "Children"
            {
                parseChildren(array: value as! NSArray)

            }
        }
        // select all
        myTableView.reloadData()
        progressBar.minValue = 0
        progressBar.maxValue =  Double(bookmarks.count)
        progressBar.doubleValue = 0
        finished = 0
        for i in 0..<bookmarks.count
        {
            // add progress bar
            accessURL(row: i)
        }
    }

}

