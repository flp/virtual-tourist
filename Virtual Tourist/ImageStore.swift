//
//  ImageStore.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/18/16.
//  Copyright © 2016 flp. All rights reserved.
//

import UIKit

class ImageStore {
    
    func getImageWithID(identifier: String) -> UIImage? {
        return UIImage(contentsOfFile: self.getDocumentsFileURLForImageID(identifier).path!)
    }
    
    func saveImage(image: UIImage?, identifier: String) {
        if image == nil {
            // TODO delete?
            return
        }
        
        self.storeImage(image!, url: self.getDocumentsFileURLForImageID(identifier))
    }
    
    private func storeImage(image: UIImage, url: NSURL) -> Bool {
        let jpgImageData = UIImageJPEGRepresentation(image, 1.0)
        return jpgImageData!.writeToURL(url, atomically: true)
    }
    
    private func getDocumentsFileURLForImageID(identifier: String) -> NSURL {
        let documentsDirectoryURL:NSURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> ImageStore {
        struct Singleton {
            static var sharedInstance = ImageStore()
        }
        return Singleton.sharedInstance
    }
    
}
