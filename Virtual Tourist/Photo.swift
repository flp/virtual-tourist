//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/11/16.
//  Copyright © 2016 flp. All rights reserved.
//

import CoreData

class Photo: NSManagedObject {
    
    struct Keys {
        static let FlickrURL = "flickr_url"
        static let ImagePath = "image_path"
    }
    
    @NSManaged var id: NSNumber
    @NSManaged var flickrURL: String
    @NSManaged var imagePath: String
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        flickrURL = dictionary[Keys.FlickrURL] as! String
        imagePath = dictionary[Keys.ImagePath] as! String
        
    }
    
}