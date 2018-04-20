//
//  ViewController.swift
//  iOSAssignment
//
//  Created by Pratibha Bhandari on 20/04/18.
//  Copyright © 2018 Pratibha Bhandari. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var noDataFoundView: UIView!
    @IBOutlet weak var rightHeaderLabel: UILabel!
    @IBOutlet weak var leftHeaderLabel: UILabel!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var scanBarButton: UIBarButtonItem!
    
    @IBOutlet weak var tableView: UITableView!
    
    var metadataQuery: NSMetadataQuery = NSMetadataQuery()
    
    var items = [NSMetadataItem]();
    var sortedFilesArray = [NSMetadataItem]();
    var extensionsArray = [FileExtension]();
    
    var fileNumber = 1
    
    let scanStartText = "Start Scan"
    let scanStopText = "Stop Scan"

    
    fileprivate let coordinationQueue: OperationQueue = {
        let coordinationQueue = OperationQueue()

        coordinationQueue.name = "com.sample.iCloudApp.documentbrowser.coordinationQueue"

        return coordinationQueue
    }()
    
    fileprivate let workerQueue: OperationQueue = {
        let workerQueue = OperationQueue()
        
        workerQueue.name = "com.sample.iCloudApp.browserdatasource.workerQueue"
        
        workerQueue.maxConcurrentOperationCount = 1
        
        return workerQueue
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        setUpQuery()
        scanBarButton.title = scanStartText
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - IBActions
    
    /*
        Method to add new dummy files on iCloud
     */
    @IBAction func addClicked(_ sender: Any) {
        // Create a document with the default template.
            let fileName = "image\(fileNumber)"
            let fileExtension = "jpg"
            let templateURL = Bundle.main.url(forResource:fileName , withExtension:fileExtension)!
            
            coordinationQueue.addOperation {
                
                if FileManager.default.ubiquityIdentityToken == nil {
                    Alert.showBasicAlert(title: "iCloud is disabled", message: "Please enable iCloud Drive in Settings to use this app", vc: self)
                    
                } else {
                    let filemgr = FileManager.default
                    let url = filemgr.url(forUbiquityContainerIdentifier: nil)
                    guard url != nil else {
                        print("url is nil")
                        return
                    }
                    guard let baseURL = url?.appendingPathComponent("Documents").appendingPathComponent(fileName) else {
                        
                        Alert.showBasicAlert(title: "iCloud is disabled", message: "Please enable iCloud Drive in Settings to use this app", vc: self)
                        return
                    }
                    var target = baseURL.appendingPathExtension(fileExtension)
                    
                    /*
                     We will append this value to our name until we find a path that
                     doesn't exist.
                     */
                    var nameSuffix = 2
                    
                    /*
                     Find a suitable filename that doesn't already exist on disk.
                     Do not use `fileManager.fileExistsAtPath(target.path!)` because
                     the document might not have downloaded yet.
                     */
                    while (target as NSURL).checkPromisedItemIsReachableAndReturnError(nil) {
                        target = URL(fileURLWithPath: baseURL.path + "-\(nameSuffix).\(fileExtension)")
                        
                        nameSuffix += 1
                    }
                    
                    // Coordinate reading on the source path and writing on the destination path to copy.
                    let readIntent = NSFileAccessIntent.readingIntent(with: templateURL, options: [])
                    
                    let writeIntent = NSFileAccessIntent.writingIntent(with: target, options: .forReplacing)
                    
                    NSFileCoordinator().coordinate(with: [readIntent, writeIntent], queue: self.coordinationQueue) { error in
                        if error != nil {
                            return
                        }
                        
                        do {
                            try filemgr.copyItem(at: readIntent.url, to: writeIntent.url)
                            
                            try (writeIntent.url as NSURL).setResourceValue(true, forKey: URLResourceKey.hasHiddenExtensionKey)
                            self.fileNumber += 1
                            OperationQueue.main.addOperation {
                                Alert.showBasicAlert(title: "File added", message: "\(target.lastPathComponent) added on icloud.", vc: self)
                            }
                        }
                        catch {
                            fatalError("Unexpected error during trivial file operations: \(error)")
                        }
                    }
                }
        }
    }
    
    
    /*
     Method to fetch all files from iCloud
     */
    @IBAction func scanClicked(_ sender: Any) {
        updateScanning()
    }
    
    @IBAction func segmentsValueChanged(_ sender: UISegmentedControl) {
        
        self.tableView.reloadData()
    }
    
    func updateScanning() {
        if scanBarButton.title == scanStartText {
            scanBarButton.title = scanStopText
            SwiftLoader.show(title: "Start scanning...", animated: true)
            metadataQuery.start()
            
        } else {
            scanBarButton.title = scanStartText
            SwiftLoader.show(title: "Stop scanning...", animated: true)
            metadataQuery.stop()
            SwiftLoader.hide()
        }
    }
    
    //MARK: - Other Methods
    
    fileprivate func getSortedWithFiles() {
        // Create an ordered set of model objects.
        var array = items
        // Sort the array by filesize.
        array.sort { ($0.value(forAttribute: "kMDItemFSSize") as! NSNumber).intValue > ($1.value(forAttribute: "kMDItemFSSize") as! NSNumber).intValue }
        let arraySlice = array.prefix(10)
        sortedFilesArray = Array(arraySlice)
        
        //Getting Extensions data
        var counts = [String: Int]()
        for metadataItem in items {
            let nameKey = metadataItem.value(forAttribute: "kMDItemFSName") as! String
            let fileExtention = NSURL(string: nameKey)?.pathExtension
            if counts[fileExtention!] != nil {
                var size = counts[fileExtention!]!
                size += 1
                counts[fileExtention!] = size
            } else {
                counts[fileExtention!] = 1
            }
        }
        
        
        extensionsArray = []
        var extensionsTempArray = [FileExtension]()
        let keys = counts.keys
        for key in keys {
            let fileExtension = FileExtension()
            fileExtension.name = key
            fileExtension.occurrance = counts[key]!
            extensionsTempArray.append(fileExtension)
        }
        extensionsTempArray = extensionsTempArray.sorted(by: { $0.occurrance > $1.occurrance })
        
        
        let extensionArraySlice = extensionsTempArray.prefix(5)
        extensionsArray = Array(extensionArraySlice)
    }
    func setUpQuery() {
        metadataQuery = NSMetadataQuery()
        
        // Filter all documents.
        metadataQuery.predicate = NSPredicate(format: "%K LIKE '*'", NSMetadataItemFSNameKey)
        
        let sortDescriptor = NSSortDescriptor(key: NSMetadataItemFSNameKey, ascending: true)
        //means recent first
        let sortDescriptors = [sortDescriptor]
        metadataQuery.sortDescriptors = sortDescriptors
        
        /*
         Ask for both in-container documents and external documents so that
         the user gets to interact with all the documents she or he has ever
         opened in the application, without having to pull the document picker
         again and again.
         */
        metadataQuery.searchScopes = [
            NSMetadataQueryUbiquitousDocumentsScope,
            NSMetadataQueryAccessibleUbiquitousExternalDocumentsScope
        ]
        
        /*
         We supply our own serializing queue to the `NSMetadataQuery` so that we
         can perform our own background work in sync with item discovery.
         Note that the operationQueue of the `NSMetadataQuery` must be serial.
         */
        metadataQuery.operationQueue = workerQueue
        
        // Setting observers
        NotificationCenter.default.addObserver(self, selector: #selector(self.finishGathering(_:)), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: metadataQuery)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.queryProgressUpdated(_:)), name: NSNotification.Name.NSMetadataQueryGatheringProgress, object: metadataQuery)
        
    }

    // MARK: - Notifications
    
    // NSMetadataQueryGatheringProgress Notification
    @objc func queryProgressUpdated(_ notification: Notification) {
        self.metadataQuery.disableUpdates()
        _ = self.metadataQuery.results as! [NSMetadataItem]
        print("progressing... ")
        print("number of results: \(self.metadataQuery.results.count)")
        DispatchQueue.main.async {
            SwiftLoader.show(title: "Scanning...", animated: true)
        }
        self.metadataQuery.enableUpdates()
        
    }
    
    // NSMetadataQueryDidFinishGathering Notification
    @objc func finishGathering(_ notification: Notification) {
        print("finishGathering")
        metadataQuery.disableUpdates()
        
        items = metadataQuery.results as! [NSMetadataItem]
        
        
        DispatchQueue.main.async {
            self.getSortedWithFiles()
            SwiftLoader.show(title: "Scanning Completed...", animated: true)
            self.tableView.reloadData()
            SwiftLoader.hide()
            self.updateScanning()
            if self.items.count > 0 {
                self.noDataFoundView.isHidden = true
            } else {
                self.noDataFoundView.isHidden = false
            }
        }
        
        metadataQuery.enableUpdates()
    }
    
    // MARK: UITableView DataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmentControl.selectedSegmentIndex == 0 {
            if sortedFilesArray.count > 0  {
                self.leftHeaderLabel.text = "File Name"
                self.rightHeaderLabel.text = "File Size"
            } else {
                self.leftHeaderLabel.text = ""
                self.rightHeaderLabel.text = ""
            }
            return sortedFilesArray.count
        } else {
            if sortedFilesArray.count > 0  {
                self.leftHeaderLabel.text = "File Extension"
                self.rightHeaderLabel.text = "Frequency"
            }
            else {
                self.leftHeaderLabel.text = ""
                self.rightHeaderLabel.text = ""
            }
            return extensionsArray.count
        }
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        if segmentControl.selectedSegmentIndex == 0 {
            let cell : FileCellTableViewCell! = self.tableView.dequeueReusableCell(withIdentifier: "FileCell") as! FileCellTableViewCell
            
            let fileItem = sortedFilesArray[indexPath.row] as NSMetadataItem
            configureFileCell(cell: cell, fileItem: fileItem)
        
            return cell as FileCellTableViewCell
        } else {
            let cell : ExtensionTableViewCell! = self.tableView.dequeueReusableCell(withIdentifier: "ExtensionCell") as! ExtensionTableViewCell
            
            let fileExtensionItem: FileExtension = extensionsArray[indexPath.row]
            configureExtensionCell(cell: cell, fileExtensionItem: fileExtensionItem)
            
            return cell as ExtensionTableViewCell
        }
    }
    
    // configure file cell with data
    func configureFileCell(cell: FileCellTableViewCell, fileItem: NSMetadataItem) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.fileNameLabel.text = fileItem.value(forAttribute: "kMDItemFSName") as? String
        cell.fileSizeLabel.text = "\(fileItem.value(forAttribute: "kMDItemFSSize")!)"
    }
    // configure extension cell with data
    func configureExtensionCell(cell: ExtensionTableViewCell, fileExtensionItem: FileExtension) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.extensionLabel.text = fileExtensionItem.name
        cell.frequencyLabel.text = "\(fileExtensionItem.occurrance)"
    }
}

