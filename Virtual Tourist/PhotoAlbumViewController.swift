//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/11/16.
//  Copyright © 2016 flp. All rights reserved.
//

import CoreData
import UIKit

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    var pin: Pin!
    let flickrClient = FlickrClient.sharedInstance()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(animated: Bool) {
        // Show the navigation bar
        self.navigationController!.navigationBarHidden = false
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
        
        // If there are no items in the collection view, setting the collection view's layout
        // causes a divide-by-zero error. Calling reloadData() beforehand seems to fix the issue.
        self.collectionView.reloadData()
        self.collectionView.collectionViewLayout = layout
    }
    
    // MARK: UICollectionView methods
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.pin.photos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCollectionViewCell", forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        let photo = self.pin.photos[indexPath.row]
        if photo.imagePath != "" {
            // Image file for this photo is already downloaded. Display it
            let fullPath = self.getDocumentsFileURL(photo.imagePath)
            if let image = self.loadImage(fullPath.path!) {
//                print("image already exists for this photo, reading from \(fullPath)")
                performUIUpdatesOnMain {
                    cell.backgroundView = UIImageView(image: image)
                    cell.indicator.stopAnimating()
                    cell.indicator.hidden = true
                }
            } else {
                print("no image at \(photo.imagePath)")
            }
        } else {
            // Image file is missing. Display a placeholder picture while the picture is downloaded
            let image = UIImage(named: "placeholder")!
            cell.backgroundView = UIImageView(image: image)
            cell.indicator.color = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
            cell.indicator.center = cell.center
            cell.indicator.startAnimating()
            cell.layoutIfNeeded()
            
            self.flickrClient.downloadPhoto(photo.flickrURL) { (imageData, error) in
                if let error = error {
                    print("error: \(error)")
                    return
                } else {
                    let flickrImage = UIImage(data: imageData)!
                    let filename = NSUUID().UUIDString
                    let fileURL = self.getDocumentsFileURL(filename)
//                    print("saving image to \(fileURL)")
                    if self.saveImage(flickrImage, path: fileURL.path!) {
                        photo.imagePath = filename
                        CoreDataStackManager.sharedInstance().saveContext()
                    } else {
                        print("failure saving image")
                    }
                    
                    performUIUpdatesOnMain {
                        cell.backgroundView = UIImageView(image: flickrImage)
                        cell.indicator.stopAnimating()
                        cell.indicator.hidden = true
                    }
                }
            }
        }
        
        return cell
    }
    
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
