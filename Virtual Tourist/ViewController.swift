//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/4/16.
//  Copyright © 2016 flp. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class ViewController: UIViewController {
    
    let savedMKCRArray = "Saved MKCR Array Key"
    let fc = FlickrClient.sharedInstance()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Read saved coordinate region from NSUserDefaults
        if let array = self.readSavedMapPosition() {
            let mkcr = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: array[0], longitude: array[1]), span: MKCoordinateSpan(latitudeDelta: array[2], longitudeDelta: array[3]))
            self.mapView.setRegion(mkcr, animated: true)
        } else {
            // If there is no saved coordinate region, center the map on San Francisco
            let center = CLLocationCoordinate2D(latitude: 37.783, longitude: -122.417)
            let span = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
            let initialRegion = MKCoordinateRegion(center: center, span: span)
            self.mapView.setRegion(initialRegion, animated: false)
        }
        
        // Set mapView's delegate
        self.mapView.delegate = self
        
        // Configure gesture recognizer
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(_:)))
        self.mapView.addGestureRecognizer(uilgr)
        
        // Add existing Pins from CoreData
        self.mapView.addAnnotations(self.fetchAllPins())
    }
    
    override func viewWillAppear(animated: Bool) {
        // Hide navigation bar
        self.navigationController!.navigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Pins
    
    func fetchAllPins() -> [Pin] {
        // Create the fetch request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch let error as NSError {
            print("Error in fetchAllPins(): \(error)")
            return [Pin]()
        }
    }
    
    func addAnnotation(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            let touchPoint = gestureRecognizer.locationInView(self.mapView)
            let coordinate = self.mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
            
            let pinDictionary: [String : AnyObject] = [
                Pin.Keys.Latitude: coordinate.latitude,
                Pin.Keys.Longitude: coordinate.longitude
            ]
            
            let pin = Pin(dictionary: pinDictionary, context: sharedContext)
            
            CoreDataStackManager.sharedInstance().saveContext()
            
            self.mapView.addAnnotation(pin)
        }
    }
    
    // MARK: Save and read map position from NSUserDefaults
    
    func saveMapPosition(mkcr: MKCoordinateRegion) {
        let defaults = NSUserDefaults.standardUserDefaults()
        let array = [mkcr.center.latitude, mkcr.center.longitude, mkcr.span.latitudeDelta, mkcr.span.longitudeDelta]
//        print("map position saved: \(array)")
        defaults.setObject(array, forKey: savedMKCRArray)
    }
    
    func readSavedMapPosition() -> [Double]? {
        let defaults = NSUserDefaults.standardUserDefaults()
        let array = defaults.objectForKey(savedMKCRArray) as? [Double]
//        print("map position read: \(array)")
        return array
    }

}

extension ViewController: MKMapViewDelegate {
 
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        return nil
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//        print("Map view region changed, saving new position")
        let currentRegion = mapView.region
        self.saveMapPosition(currentRegion)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let pin = view.annotation as! Pin
        
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        controller.pin = pin
        self.navigationController!.pushViewController(controller, animated: true)
        
        mapView.deselectAnnotation(pin, animated: false)
    }
    
}

