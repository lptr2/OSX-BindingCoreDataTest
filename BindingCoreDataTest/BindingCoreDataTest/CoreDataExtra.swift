
import Foundation
import CoreData

var managedObjectContext : NSManagedObjectContext?

/// Just took this from original APL documentation Core Data Programming Guide. This converts a datastore from XML to SQLite
func convertXML_toSQLiteStore() -> Bool {

	guard let psc = managedObjectContext!.persistentStoreCoordinator else {
		fatalError("Failed to load persistent store")
	}
	let oldURL = NSURL(fileURLWithPath: "oldURL")
	let newURL = NSURL(fileURLWithPath: "newURL")
	guard let xmlStore = psc.persistentStoreForURL(oldURL) else {
		fatalError("Failed to reference old store")
	}
	do {
		try psc.migratePersistentStore(xmlStore, toURL: newURL, options:nil, withType:NSSQLiteStoreType)
	} catch {
		fatalError("Failed to migrate store: \(error)")
	}
	
	return true
}

/// If you are using the SQLite store, you can use a fetch limit to minimize the working set of managed objects in memory
func ifUsingSQLite_setFetchlimit() {
	let request = NSFetchRequest()
	request.fetchLimit = 100
}