//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/11/16.
//  Copyright © 2016 flp. All rights reserved.
//

import CoreData
import UIKit

class Photo: NSManagedObject {
    
    struct Keys {
        static let FlickrURL = "flickr_url"
        static let ImageID = "image_id"
    }
    
    @NSManaged var id: NSNumber
    @NSManaged var flickrURL: String
    @NSManaged var imageID: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(flickrURL: String, context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.flickrURL = flickrURL
        self.imageID = "vt_image_ " + NSUUID().UUIDString
    }
    
    var image: UIImage? {
        
        get {
            return ImageStore.sharedInstance().getImageWithID(imageID)
        }
        
        set {
            ImageStore.sharedInstance().saveImage(newValue, identifier: self.imageID)
        }
    }
    
    override func prepareForDeletion() {
        self.image = nil
    }
    
}