//
//  ImageStore.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/18/16.
//  Copyright © 2016 flp. All rights reserved.
//

import UIKit

class ImageStore {
    
    class func loadImage(path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }
    
    class func saveImage(image: UIImage, path: String) -> Bool {
        let jpgImageData = UIImageJPEGRepresentation(image, 1.0)
        let result = jpgImageData!.writeToFile(path, atomically: true)
        
        return result
    }
    
    class func getDocumentsFileURL(filename: String) -> NSURL {
        let documentsDirectoryURL:NSURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(filename)
        
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
