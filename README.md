# Virtual Tourist
Virtual Tourist is an iOS app that lets you explore the world from the comfort of your couch.

This app is a portfolio project from Udacity's "iOS Persistence and Core Data" course.

Simply drop a pin by tapping and holding at a location of interest.

![alt tag](Screenshots/map.png)

Tapping a pin downloads interesting Flickr photos that are associated with the latitude and longitude of the location. Photos are displayed as they finish downloading.

![alt tag](Screenshots/progress.png)

Specific photos can be selected for deletion one at a time, or you can grab a new collection altogether.

![alt tag](Screenshots/delete.png)

Data is persisted with CoreData. When the app is terminated and reopened, previously entered pins will be redrawn on the map. Image files for the photos are stored in the Documents directory so that image data is only ever downloaded once and instead accessed from the filesystem on subsequent views.
