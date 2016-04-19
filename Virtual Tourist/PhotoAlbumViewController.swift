//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/11/16.
//  Copyright © 2016 flp. All rights reserved.
//

import CoreData
import UIKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    var pin: Pin!
    let fc = FlickrClient.sharedInstance()
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.  You can see how the array
    // works by searchign through the code for 'selectedIndexes'
    var selectedIndexes = [NSIndexPath]()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
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
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show the navigation bar
        self.navigationController!.navigationBarHidden = false
        
        if pin.photos.isEmpty {
            
            fc.searchFlickrPhotos(Double(pin.coordinate.latitude), longitude: Double(pin.coordinate.longitude), numPhotos: 12) { (urls, error) in
                if let error = error {
                    print("error: \(error)")
                } else {
                    _ = urls.map() { (url: String) -> Photo in
                        let photoDictionary: [String : AnyObject] = [
                            Photo.Keys.FlickrURL: url,
                            Photo.Keys.ImagePath: ""
                        ]
                        
                        let photo = Photo(dictionary: photoDictionary, context: self.sharedContext)
                        photo.pin = self.pin
                        
                        return photo
                    }
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                    print("got photos!")
                    // Update the collection on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        self.collectionView.reloadData()
                    }
                }
            }
            
        }
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
    
    // MARK: CoreData
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // MARK: Configure Cell
    
    func configureCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let image = UIImage(named: "placeholder")!
        cell.backgroundView = UIImageView(image: image)
        cell.indicator.color = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        cell.indicator.center = cell.center
        cell.indicator.startAnimating()
        cell.layoutIfNeeded()
        
        if photo.imagePath != "" {
            // Image file for this photo is already downloaded. Display it
        } else {
            // Image file is missing. Display a placeholder image
            let image = UIImage(named: "placeholder")!
            cell.backgroundView = UIImageView(image: image)
            cell.indicator.color = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
            cell.indicator.center = cell.center
            cell.indicator.startAnimating()
            cell.layoutIfNeeded()
            
            // Download image data and save it
            self.fc.downloadPhoto(photo.flickrURL) { (imageData, error) in
                
                if let error = error {
                    print("error downloading image at \(photo.flickrURL): \(error)")
                    return
                }
                
                let flickrImage = UIImage(data: imageData)!
                
                dispatch_async(dispatch_get_main_queue()) {
                    cell.backgroundView = UIImageView(image: flickrImage)
                    cell.indicator.stopAnimating()
                    cell.indicator.hidden = true
                }
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
        
        return cell
    }
    
//    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
//        
//        let photo = self.pin.photos[indexPath.row]
//        if photo.imagePath != "" {
//            // Image file for this photo is already downloaded. Display it
//            let fullPath = self.getDocumentsFileURL(photo.imagePath)
//            if let image = self.loadImage(fullPath.path!) {
////                print("image already exists for this photo, reading from \(fullPath)")
//                performUIUpdatesOnMain {
//                    cell.backgroundView = UIImageView(image: image)
//                    cell.indicator.stopAnimating()
//                    cell.indicator.hidden = true
//                }
//            } else {
//                print("no image at \(photo.imagePath)")
//            }
//        } else {
//            // Image file is missing. Display a placeholder picture while the picture is downloaded
//            let image = UIImage(named: "placeholder")!
//            cell.backgroundView = UIImageView(image: image)
//            cell.indicator.color = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
//            cell.indicator.center = cell.center
//            cell.indicator.startAnimating()
//            cell.layoutIfNeeded()
//            
//            self.fc.downloadPhoto(photo.flickrURL) { (imageData, error) in
//                if let error = error {
//                    print("error: \(error)")
//                    return
//                } else {
//                    let flickrImage = UIImage(data: imageData)!
//                    let filename = NSUUID().UUIDString
//                    let fileURL = self.getDocumentsFileURL(filename)
////                    print("saving image to \(fileURL)")
//                    if self.saveImage(flickrImage, path: fileURL.path!) {
//                        photo.imagePath = filename
//                        CoreDataStackManager.sharedInstance().saveContext()
//                    } else {
//                        print("failure saving image")
//                    }
//                    
//                    performUIUpdatesOnMain {
//                        cell.backgroundView = UIImageView(image: flickrImage)
//                        cell.indicator.stopAnimating()
//                        cell.indicator.hidden = true
//                    }
//                }
//            }
//        }
//        
//        return cell
//    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        // TODO
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
    
    // MARK: Image loading and storing - should go someplace else probably
    
    func loadImage(path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }
    
    func saveImage(image: UIImage, path: String) -> Bool {
        let jpgImageData = UIImageJPEGRepresentation(image, 1.0)
        let result = jpgImageData!.writeToFile(path, atomically: true)
        
        return result
    }
    
    func getDocumentsFileURL(filename: String) -> NSURL {
        let documentsDirectoryURL:NSURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(filename)
        
        return fullURL
    }

}
