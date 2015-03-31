//
//  SiteDetailsViewController.swift
//  PanamaWiFi
//
//  Created by Ricardo Chavarria on 3/31/15.
//  Copyright (c) 2015 Admios. All rights reserved.
//

import UIKit
import ArcGIS

class SiteDetailsViewController: UITableViewController {

    var feature : AGSGraphic?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.blueColor()
        self.navigationController?.navigationBar.barStyle = UIBarStyle.Black
        
        if let f = feature? {
            if f.hasAttributeForKey("SITIO") {
                self.title = f.attributeAsStringForKey("SITIO")
            } else if f.hasAttributeForKey("LUGAR") {
                self.title = f.attributeAsStringForKey("LUGAR")
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let attributes = feature?.allAttributes() {
            return attributes.count
        }
        
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DetailsCell", forIndexPath: indexPath) as UITableViewCell

        if let attributes = feature?.allAttributes() {
            
            let keyAtIndexPath = Array(attributes.keys)[indexPath.row] as String
            cell.detailTextLabel?.text = keyAtIndexPath
            
            //detail text is the value associated with the key above
            if let detailValue: AnyObject = attributes[keyAtIndexPath] {
                //figure out if the value is a NSDecimalNumber or NSString
                if detailValue is String {
                    //value is a NSString, just set it
                    cell.textLabel?.text = detailValue as? String
                }
                else if detailValue is NSNumber {
                    //value is a NSDecimalNumber, format the result as a double
                    cell.textLabel?.text = String(format: "%.2f", Double(detailValue as NSNumber))
                }
                else {
                    //not a NSDecimalNumber or a NSString,
                    cell.textLabel?.text = "N/A"
                }
            }
        }
        
        return cell
    }
}
