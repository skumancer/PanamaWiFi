//
//  ViewController.swift
//  PanamaWiFi
//
//  Created by Ricardo Chavarria on 3/30/15.
//  Copyright (c) 2015 Admios. All rights reserved.
//

import UIKit
import ArcGIS

class ViewController: UITableViewController, AGSMapViewTouchDelegate, AGSMapViewLayerDelegate, AGSQueryTaskDelegate {
 
    let networksURL = NSURL(string: "http://services.arcgis.com/YWS4hN3n25AVAsTm/arcgis/rest/services/GEORED507_AIG_Red_Nacional_Internet/FeatureServer/0")
    let establishmentsURL = NSURL(string: "http://services.arcgis.com/doh7A7RjAthUwbzt/arcgis/rest/services/AIG_Wifi_Comercios/FeatureServer/0")
    
    lazy var mapView : AGSMapView = {
        let view = AGSMapView()
        view.enableWrapAround()
        view.touchDelegate = self
        view.layerDelegate = self
        
        let url = NSURL(string: "http://services.arcgisonline.com/arcgis/rest/services/World_Street_Map/MapServer")
        
        // Verify internet connection, if we have one, use a dynamic layer, otherwise use a cached/offline one
        let tiledLayer = AGSTiledMapServiceLayer(URL: url)
        let networksLayer = AGSFeatureLayer(URL: self.networksURL, mode: .OnDemand)
        let establishmentsLayer = AGSFeatureLayer(URL: self.establishmentsURL, mode: .OnDemand)
        
        view.addMapLayer(tiledLayer)
        view.addMapLayer(networksLayer, withName: "WiFi")
        view.addMapLayer(establishmentsLayer, withName: "Establishments")
        
        return view
    } ()
    
    var queryTask : AGSQueryTask?
    var query : AGSQuery?
    var featureSet : AGSFeatureSet?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tableView.setParallaxHeaderView(mapView, mode: .TopFill, height: self.view.frame.height)
        
        registerAsObserver()
        
        queryTask = AGSQueryTask(URL: networksURL)
        queryTask?.delegate = self
        
        query = AGSQuery()
        query?.outFields = ["*"]
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if !mapView.loaded {
            SVProgressHUD.showWithStatus("Loading...")
        }
        
        mapView.releaseHardwareResourcesWhenBackgrounded = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
        mapView.releaseHardwareResourcesWhenBackgrounded = true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if let details = segue.destinationViewController as? SiteDetailsViewController {
            if let cell = sender as? MapPointsCell {
                details.feature = cell.feature
            }
        }
    }
    
    
    // mark - Scroll view
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        self.tableView.shouldPositionParallaxHeader()
    }
    
    
    // mark - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let set = featureSet {
            return set.features.count
        }
        
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
    let cell = self.tableView.dequeueReusableCellWithIdentifier("POICell", forIndexPath: indexPath) as MapPointsCell
        
        if let feature = featureSet?.features[indexPath.row] as? AGSGraphic {
        
            cell.feature = feature
            
            // Each layer has a different type of name key
            if feature.hasAttributeForKey("SITIO") {
                cell.textLabel?.text = feature.attributeAsStringForKey("SITIO")
            } else if feature.hasAttributeForKey("LUGAR") {
                cell.textLabel?.text = feature.attributeAsStringForKey("LUGAR")
            }
            
            if feature.hasAttributeForKey("DIRECCION") {
                cell.detailTextLabel?.text = feature.attributeAsStringForKey("DIRECCION")
            }
        }
        
        return cell
    }
    
    // mark - AGSLocationDisplay
    
    func registerAsObserver() {
        self.mapView.locationDisplay.addObserver(self, forKeyPath: "location", options: .New, context: nil)
    }
    
    override func observeValueForKeyPath(keyPath: (String!), ofObject object: (AnyObject!), change: ([NSObject : AnyObject]!), context: UnsafeMutablePointer<()>) {
        if keyPath == "location" {
        }
    }
    
    // mark - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView!, didEndTapAndHoldAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, graphics: [NSObject : AnyObject]!) {
        
        SVProgressHUD.showInfoWithStatus("Searching...")
        
        // Create an envelope that is (2 * extends)m in radius (extends m in each direction from center)
        let extends = 500.0
        let center = mappoint
        let area = AGSEnvelope(xmin: center.x - extends, ymin: center.y - extends, xmax: center.x + extends, ymax: center.y + extends, spatialReference: mappoint.spatialReference)
        query?.geometry = area
        query?.spatialRelationship = AGSSpatialRelationship.Contains
        queryTask?.executeWithQuery(query)
    }
    
    // mark - AGSMapViewLayerDelegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        
        SVProgressHUD.dismiss()
        
        mapView.locationDisplay.startDataSource()
        mapView.locationDisplay.autoPanMode = .Default
    }
    
    // mark - AGSQueryTaskDelegate
    
    func queryTask(queryTask: AGSQueryTask!, operation op: NSOperation!, didExecuteWithFeatureSetResult featureSet: AGSFeatureSet!) {
        
        SVProgressHUD.dismiss()
        
        self.featureSet = featureSet
        self.tableView.reloadData()
        
        if self.featureSet?.features.count > 0 {
            self.tableView.setParallaxHeaderView(mapView, mode: .TopFill, height: 400)
        }
        else {
            self.tableView.setParallaxHeaderView(mapView, mode: .TopFill, height: self.view.frame.height)
        }
    }
    
    func queryTask(queryTask: AGSQueryTask!, operation op: NSOperation!, didFailWithError error: NSError!) {
        println("Querry error \(error.description)")
        
        SVProgressHUD.showErrorWithStatus("Couldn't complete query");
    }
}
