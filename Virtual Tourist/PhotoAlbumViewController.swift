//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/11/16.
//  Copyright © 2016 flp. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    var pin: Pin!
    let fc = FlickrClient.sharedInstance()
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndices'
    var selectedIndices = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start the fetched results controller
        var error: NSError?
        do {
            try fetchedResultsController.performFetch()
        } catch let error1 as NSError {
            error = error1
        }
        
        if let error = error {
            print("Error performing initial fetch: \(error)")
        }
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        self.updateBottomButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show the navigation bar
        self.navigationController!.navigationBarHidden = false
        
        if pin.photos.isEmpty {
            self.fetchPhotos()
        }
        
        self.mapView.addAnnotation(pin)
        let region = MKCoordinateRegion(center: pin.coordinate, span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
        self.mapView.setRegion(region, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let layout = UICollectionViewFlowLayout()
        let space: CGFloat = 3.0
        layout.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
        let dimension = floor((self.collectionView.frame.size.width - (4 * space)) / 3.0)
        
        layout.minimumInteritemSpacing = space
        layout.minimumLineSpacing = space
        layout.itemSize = CGSizeMake(dimension, dimension)
        
        self.collectionView.collectionViewLayout = layout
    }
    
    // MARK: Bottom button
    
    func updateBottomButton() {
        if selectedIndices.count > 0 {
            bottomButton.title = "Delete Selected Photos"
            bottomButton.action = Selector("deleteSelectedPhotos:")
        } else {
            bottomButton.title = "New Collection"
            bottomButton.action = Selector("newCollection:")
        }
    }
    
    func newCollection(sender: AnyObject) {
        self.deleteAllPhotos()
        self.fetchPhotos()
    }
    
    func deleteSelectedPhotos(sender: AnyObject) {
        self.deleteSelectedPhotos()
    }
    
    // MARK: Photos
    
    func deleteSelectedPhotos() {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndices {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for photo in photosToDelete {
            sharedContext.deleteObject(photo)
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        selectedIndices = [NSIndexPath]()
        
        self.updateBottomButton()
    }
    
    func deleteAllPhotos() {
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        
        CoreDataStackManager.sharedInstance().saveContext()
        
        selectedIndices = [NSIndexPath]()
    }
    
    func fetchPhotos() {
        fc.searchFlickrPhotos(Double(pin.coordinate.latitude), longitude: Double(pin.coordinate.longitude), numPhotos: 12) { (urls, error) in
            if let error = error {
                print("error: \(error)")
            } else {
                print("fetched \(urls.count) photos")
                _ = urls.map() { (url: String) -> Photo in
                    
                    let photo = Photo(flickrURL: url, context: self.sharedContext)
                    photo.pin = self.pin
                    
                    return photo
                }
                
                CoreDataStackManager.sharedInstance().saveContext()
                
                // Update the collection on the main thread
                dispatch_async(dispatch_get_main_queue()) {
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    // MARK: CoreData
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // MARK: Configure Cell
    
    func configureCellSelection(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        if let _ = selectedIndices.indexOf(indexPath) {
            cell.colorPanel.alpha = 0.6
            cell.deleteImageView.alpha = 1.0
        } else {
            cell.colorPanel.alpha = 0
            cell.deleteImageView.alpha = 0
        }
    }
    
    func configureCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        if photo.image != nil {
            // Image file for this photo is already downloaded. Display it
            dispatch_async(dispatch_get_main_queue()) {
                cell.backgroundView = UIImageView(image: photo.image)
                cell.indicator.stopAnimating()
                cell.indicator.hidden = true
            }
        } else {
            // Image file is missing. Display a placeholder image
            let image = UIImage(named: "placeholder")!
            cell.backgroundView = UIImageView(image: image)
            cell.indicator.startAnimating()
            cell.indicator.hidden = false
            cell.layoutIfNeeded()
            
            // Download image data and save it
            print("downloading image")
            self.fc.downloadPhoto(photo.flickrURL) { (imageData, error) in
                
                if let error = error {
                    print("error downloading image at \(photo.flickrURL): \(error)")
                    return
                }
                
                let flickrImage = UIImage(data: imageData)!
                
                // Display image
                dispatch_async(dispatch_get_main_queue()) {
                    cell.backgroundView = UIImageView(image: flickrImage)
                    cell.indicator.stopAnimating()
                    cell.indicator.hidden = true
                }
                
                // Save image to file
                photo.image = flickrImage
            }
        }
    }
    
    // MARK: UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        print("number Of Cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        self.configureCellSelection(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        if let index = selectedIndices.indexOf(indexPath) {
            selectedIndices.removeAtIndex(index)
        } else {
            selectedIndices.append(indexPath)
        }
        
        self.configureCellSelection(cell, atIndexPath: indexPath)
        
        self.updateBottomButton()
    }
    
    // MARK: NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "flickrURL", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    // MARK: Fetched Results Controller Delegate
    
    // Whenever changes are made to Core Data the following three methods are invoked.
    
    // This first method is used to create three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Photo object that is added, deleted, or changed.
    // We store the index paths into the three arrays.
    func controller(controller: NSFetchedResultsController,
        didChangeObject anObject: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            switch type {
            case .Insert:
                print("Insert an item")
                // Here we are noting that a new Photo instance has been added to Core Data. We remember its index path
                // so that we can add a cell in "controllerDidChangeContent". Note that the "newIndexPath" parameter has
                // the index path that we want in this case
                insertedIndexPaths.append(newIndexPath!)
                break
            case .Delete:
                print("Delete an item")
                // Here we are noting that a Photo instance has been deleted from Core Data. We keep remember its index path
                // so that we can remove the corresponding cell in "controllerDidChangeContent". The "indexPath" parameter has
                // value that we want in this case.
                deletedIndexPaths.append(indexPath!)
                break
            case .Update:
                print("Update an item")
                // Here Core Data will notify us when a change has occurred. This can be useful if you want to respond to
                // changes that come about after data is downloaded. We will use this when an image is downloaded from
                // Flickr.
                updatedIndexPaths.append(indexPath!)
                break
            case .Move:
                print("Move an item. We don't expect to see this in this app.")
                break
            default:
                break
            }
            
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count + updatedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }

}
