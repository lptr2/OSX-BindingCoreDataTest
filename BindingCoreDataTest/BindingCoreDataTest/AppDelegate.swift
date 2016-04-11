
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!
	@IBOutlet weak var booksArrayController: NSArrayController!
	

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		
		// In this sample App we are working with bindings. Bindings are configured directly working on
		// CoreData. Apple's Core Data Programming Guide expresses:
		//		"SQLite store does not work with sorting"
		// In Interface Builder of Xcode there is no mechnism to telling the data getting loaded sorted into
		// NSArrayController. To sort content for some specifications they suggest to load and resorting it
		// MANUALLY ! This is working through outlet booksArrayController from .xib file.
		//
		// Next two lines telling outlet to sort for name field.
		let sort = NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
		booksArrayController.sortDescriptors = [sort]	// it modifies that sortDescriptor of tableView
		
		
	}

	func applicationWillTerminate(aNotification: NSNotification) {
	}

	
	// Having Core Data stack here in AppDelegate is SICK !
	// Anyways for current purpose thing is ok.

	// MARK: - Core Data stack

	lazy var applicationDocumentsDirectory: NSURL = {
	    let urls = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
	    let appSupportURL = urls[urls.count - 1]
	    return appSupportURL.URLByAppendingPathComponent("com.globalconres.BindingCoreDataTest")
	}()

	lazy var managedObjectModel: NSManagedObjectModel = {
	    let modelURL = NSBundle.mainBundle().URLForResource("MyModel", withExtension: "momd")!
	    return NSManagedObjectModel(contentsOfURL: modelURL)!
	}()

	lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
	    let fileManager = NSFileManager.defaultManager()
	    var failError: NSError? = nil
	    var shouldFail = false
	    var failureReason = "There was an error creating or loading the application's saved data."

	    do {
	        let properties = try self.applicationDocumentsDirectory.resourceValuesForKeys([NSURLIsDirectoryKey])
	        if !properties[NSURLIsDirectoryKey]!.boolValue {
	            failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
	            shouldFail = true
	        }
	    } catch  {
	        let nserror = error as NSError
	        if nserror.code == NSFileReadNoSuchFileError {
	            do {
	                try fileManager.createDirectoryAtPath(self.applicationDocumentsDirectory.path!, withIntermediateDirectories: true, attributes: nil)
	            } catch {
	                failError = nserror
	            }
	        } else {
	            failError = nserror
	        }
	    }
	    
	    // Create the coordinator and store
	    var coordinator: NSPersistentStoreCoordinator? = nil
	    if failError == nil {
	        coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
	        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CocoaAppCD.storedata")

			// mod (rs)
			print("CoreData location: \(url)")
			
			do {  // default datastore is using a XML store !!!
	            try coordinator!.addPersistentStoreWithType(NSXMLStoreType, configuration: nil, URL: url, options: nil)
	        } catch {
	            failError = error as NSError
	        }
	    }
	    
	    if shouldFail || (failError != nil) {
	        var dict = [String: AnyObject]()
	        dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
	        dict[NSLocalizedFailureReasonErrorKey] = failureReason
	        if failError != nil {
	            dict[NSUnderlyingErrorKey] = failError
	        }
	        let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
	        NSApplication.sharedApplication().presentError(error)
	        abort()
	    } else {
	        return coordinator!
	    }
	}()

	lazy var managedObjectContext: NSManagedObjectContext = {
	    let coordinator = self.persistentStoreCoordinator
	    var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
	    managedObjectContext.persistentStoreCoordinator = coordinator
	    return managedObjectContext
	}()

	// MARK: - Core Data Saving and Undo support

	@IBAction func saveAction(sender: AnyObject!) {
	    if !managedObjectContext.commitEditing() {
	        NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing before saving")
	    }
	    if managedObjectContext.hasChanges {
	        do {
	            try managedObjectContext.save()
	        } catch {
	            let nserror = error as NSError
	            NSApplication.sharedApplication().presentError(nserror)
	        }
	    }
	}

	func windowWillReturnUndoManager(window: NSWindow) -> NSUndoManager? {
	    // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
	    return managedObjectContext.undoManager
	}

	func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
	    // Save changes in the application's managed object context before the application terminates.
	    
	    if !managedObjectContext.commitEditing() {
	        NSLog("\(NSStringFromClass(self.dynamicType)) unable to commit editing to terminate")
	        return .TerminateCancel
	    }
	    
	    if !managedObjectContext.hasChanges {
	        return .TerminateNow
	    }
	    
	    do {
	        try managedObjectContext.save()
	    } catch {
	        let nserror = error as NSError
	        // Customize this code block to include application-specific recovery steps.
	        let result = sender.presentError(nserror)
	        if (result) {
	            return .TerminateCancel
	        }
	        
	        let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
	        let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
	        let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
	        let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
	        let alert = NSAlert()
	        alert.messageText = question
	        alert.informativeText = info
	        alert.addButtonWithTitle(quitButton)
	        alert.addButtonWithTitle(cancelButton)
	        
	        let answer = alert.runModal()
	        if answer == NSAlertFirstButtonReturn {
	            return .TerminateCancel
	        }
	    }
	    // If we got here, it is time to quit.
	    return .TerminateNow
	}

}

