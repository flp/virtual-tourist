//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/11/16.
//  Copyright © 2016 flp. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
    
    var session = NSURLSession.sharedSession()
    
    func searchFlickrPhotos(latitude: Double, longitude: Double, numPhotos: Int, completionHandlerForURLs: (urls: [String]!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        func sendError(error: String) {
            let userInfo = [NSLocalizedDescriptionKey : error]
            completionHandlerForURLs(urls: nil, error: NSError(domain: "searchFlickrPhotos", code: 1, userInfo: userInfo))
        }
        
        if numPhotos > Constants.MaxPhotos {
            sendError("Maximum number of photos exceed.")
            return NSURLSessionDataTask()
        }
        
        /* 1. Set the parameters */
        let methodParameters = [
            ParameterKeys.Method: ParameterValues.SearchMethod,
            ParameterKeys.APIKey: Constants.APIKey,
            ParameterKeys.BoundingBox: self.bboxString(latitude, longitude: longitude),
            ParameterKeys.SafeSearch: ParameterValues.UseSafeSearch,
            ParameterKeys.Extras: ParameterValues.MediumURL,
            ParameterKeys.Format: ParameterValues.ResponseFormat,
            ParameterKeys.NoJSONCallback: ParameterValues.DisableJSONCallback,
            ParameterKeys.PerPage: String(Constants.MaxPhotos),
            ParameterKeys.Sort: ParameterValues.Interestingness
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = NSURLRequest(URL: self.flickrURLFromParameters(methodParameters))
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                sendError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[ResponseKeys.Status] as? String where stat == ResponseValues.OKStatus else {
                sendError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[ResponseKeys.Photos] as? [String:AnyObject] else {
                sendError("Cannot find keys '\(ResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard var photosArray = photosDictionary[ResponseKeys.Photo] as? [[String: AnyObject]] else {
                sendError("Cannot find key '\(ResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            var urls = [String]()
            
            if photosArray.isEmpty {
                completionHandlerForURLs(urls: urls, error: nil)
                return
            }
            
            // Collect image urls
            // pick numPhotos randomly from photosArray
            for _ in 1...numPhotos {
                let randIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                let randPhoto = photosArray.removeAtIndex(randIndex)
                if let imageUrlString = randPhoto[ResponseKeys.MediumURL] as? String {
                    urls.append(imageUrlString)
                }
            }
            
            completionHandlerForURLs(urls: urls, error: nil)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
        
    }
    
    func downloadPhoto(var imageURL: String, completionHandlerForImageData: (data: NSData!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        let session = NSURLSession.sharedSession()
        
        let request = NSURLRequest(URL: NSURL(string: imageURL)!)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func sendError(error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForImageData(data: nil, error: NSError(domain: "downloadPhoto", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            completionHandlerForImageData(data: data, error: nil)
        }
        
        task.resume()

        return task
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
        let minimumLon = max(longitude - Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.APIScheme
        components.host = Constants.APIHost
        components.path = Constants.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
    // MARK: Shared Instance
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }

}