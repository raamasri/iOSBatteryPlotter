import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        let sampleSnapshot = Snapshot(context: viewContext)
        sampleSnapshot.id = UUID()
        sampleSnapshot.date = Date()
        sampleSnapshot.health = 0.89
        sampleSnapshot.cycles = 542
        
        let sampleSession = Session(context: viewContext)
        sampleSession.id = UUID()
        sampleSession.startDate = Date().addingTimeInterval(-3600)
        sampleSession.endDate = Date()
        sampleSession.avgWatts = 18.5
        sampleSession.peakWatts = 22.1
        sampleSession.deltaPct = 45.0
        sampleSession.chargerType = "20W USB-C"
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BatteryModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func deleteAllData() {
        let context = container.viewContext
        
        let snapshotFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Snapshot")
        let sessionFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Session")
        
        let snapshotDelete = NSBatchDeleteRequest(fetchRequest: snapshotFetch)
        let sessionDelete = NSBatchDeleteRequest(fetchRequest: sessionFetch)
        
        do {
            try context.execute(snapshotDelete)
            try context.execute(sessionDelete)
            try context.save()
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }
}