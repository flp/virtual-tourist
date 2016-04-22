//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Franklin Pearsall on 4/11/16.
//  Copyright © 2016 flp. All rights reserved.
//

extension FlickrClient {
    
    // MARK: Constants
    struct Constants {
        static let APIKey = "56292861cc46675393db7889dbeafe39"
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
        
        static let MaxPhotos = 200 // must be <= 500 per flickr's API
    }
    
    // MARK: Parameter Keys
    struct ParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Page = "page"
        static let PerPage = "per_page"
        static let Sort = "sort"
    }
    
    // MARK: Parameter Values
    struct ParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
        static let Interestingness = "interestingness-desc"
    }
    
    // MARK: Response Keys
    struct ResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: Response Values
    struct ResponseValues {
        static let OKStatus = "ok"
    }
    
}