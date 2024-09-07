//
//  Problem.swift
//  Boolder
//
//  Created by Nicolas Mondollot on 09/05/2020.
//  Copyright © 2020 Nicolas Mondollot. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import SQLite

struct Problem : Identifiable {
    let id: Int
    let name: String?
    let nameEn: String?
    let nameSearchable: String?
    let grade: Grade
    let coordinate: CLLocationCoordinate2D
    let steepness: Steepness
    let sitStart: Bool
    let areaId: Int
    let circuitId: Int?
    let circuitColor: Circuit.CircuitColor?
    let circuitNumber: String
    let bleauInfoId: String?
    let featured: Bool
    let popularity: Int?
    let parentId: Int?
    let variantType: String?
    let startParentId: Int?
    
    // TODO: remove
    static let empty = Problem(id: 0, name: "", nameEn: "", nameSearchable: "", grade: Grade.min, coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), steepness: .other, sitStart: false, areaId: 0, circuitId: nil, circuitColor: .offCircuit, circuitNumber: "", bleauInfoId: nil, featured: false, popularity: 0, parentId: nil, variantType: nil, startParentId: 0)
    
    var zIndex: Double {
        if let popularity = popularity {
            Double(popularity)
        }
        else {
            Double(id) / 100000
        }
    }
    
    var circuitUIColor: UIColor {
        circuitColor?.uicolor ?? UIColor.gray
    }
    
    var circuitUIColorForPhotoOverlay: UIColor {
        circuitColor?.uicolorForPhotoOverlay ?? UIColor.gray
    }
    
    var localizedName: String {
        if NSLocale.websiteLocale == "fr" {
            return name ?? ""
        }
        else {
            return nameEn ?? ""
        }
    }
    
    func circuitNumberComparableValue() -> Double {
        if let int = Int(circuitNumber) {
            return Double(int)
        }
        else {
            if let int = Int(circuitNumber.dropLast()) {
                return 0.5 + Double(int)
            }
            else {
                return 0
            }
        }
    }
    
    // Same logic exists server side: https://github.com/nmondollot/boolder/blob/145d1b7fbebfc71bab6864e081d25082bcbeb25c/app/models/problem.rb#L99-L105
    var variants: [Problem] {
        if let parent = parent {
            return parent.variants
        }
        else {
            return [self] + children
        }
    }

    // TODO: rename and move to Line
    func lineFirstPoint() -> Line.PhotoPercentCoordinate? {
        guard let line = line else { return nil }
        guard let coordinates = line.coordinates else { return nil }
        guard let firstPoint = coordinates.first else { return nil }
        
        return firstPoint
    }
    
    var topoId: Int? {
        line?.topoId
    }
    
    var topo: Topo? {
        guard let topoId = topoId else { return nil }
        
        return Topo(id: topoId, areaId: areaId)
    }
    
    var onDiskPhoto: UIImage? {
        topo?.onDiskPhoto
    }
    
    func isFavorite() -> Bool {
        favorite() != nil
    }
    
    func favorite() -> Favorite? {
        favorites().first { (favorite: Favorite) -> Bool in
            return Int(favorite.problemId) == id
        }
    }
    
    func isTicked() -> Bool {
        tick() != nil
    }
    
    func tick() -> Tick? {
        ticks().first { (tick: Tick) -> Bool in
            return Int(tick.problemId) == id
        }
    }
}

// MARK: SQLite
extension Problem {
    static let id = Expression<Int>("id")
    static let areaId = Expression<Int>("area_id")
    static let name = Expression<String?>("name")
    static let nameEn = Expression<String?>("name_en")
    static let nameSearchable = Expression<String?>("name_searchable")
    static let grade = Expression<String>("grade")
    static let steepness = Expression<String>("steepness")
    static let circuitNumber = Expression<String?>("circuit_number")
    static let circuitColor = Expression<String?>("circuit_color")
    static let circuitId = Expression<Int?>("circuit_id")
    static let bleauInfoId = Expression<String?>("bleau_info_id")
    static let parentId = Expression<Int?>("parent_id")
    static let variantType = Expression<String?>("variant_type")
    static let startParentId = Expression<Int?>("start_parent_id")
    static let latitude = Expression<Double>("latitude")
    static let longitude = Expression<Double>("longitude")
    static let sitStart = Expression<Int>("sit_start")
    static let featured = Expression<Int>("featured")
    static let popularity = Expression<Int?>("popularity")
    
    static func load(id: Int) -> Problem? {
        do {
            let problems = Table("problems").filter(self.id == id)
            
            if let p = try SqliteStore.shared.db.pluck(problems) {
                return Problem(
                    id: id,
                    name: p[name],
                    nameEn: p[nameEn],
                    nameSearchable: p[nameSearchable],
                    grade: Grade(p[grade]),
                    coordinate: CLLocationCoordinate2D(latitude: p[latitude], longitude: p[longitude]),
                    steepness: Steepness(rawValue: p[steepness]) ?? .other,
                    sitStart: p[sitStart] == 1,
                    areaId: p[areaId],
                    circuitId: p[circuitId],
                    circuitColor: Circuit.CircuitColor.colorFromString(p[circuitColor]),
                    circuitNumber: p[circuitNumber] ?? "",
                    bleauInfoId: p[bleauInfoId],
                    featured: p[featured] == 1,
                    popularity: p[popularity],
                    parentId: p[parentId],
                    variantType: p[variantType],
                    startParentId: p[startParentId]
                )
            }
            
            return nil
        }
        catch {
            print (error)
            return nil
        }
    }
    
    static func search(_ text: String) -> [Problem] {
        let query = Table("problems")
            .order(popularity.desc)
            .filter(nameSearchable.like("%\(text.normalized)%"))
            .limit(20)
        
        do {
            return try SqliteStore.shared.db.prepare(query).map { p in
                Problem.load(id: p[id])
            }.compactMap{$0}
        }
        catch {
            print (error)
            return []
        }
    }
    
    // TODO: handle multiple lines
    var line: Line? {
        let lines = Table("lines")
            .filter(Line.problemId == id)
        
        do {
            if let l = try SqliteStore.shared.db.pluck(lines) {
                return Line.load(id: l[Line.id])
            }
            
            return nil
        }
        catch {
            print (error)
            return nil
        }
    }
    
    var otherProblemsOnSameTopo: [Problem] {
        guard let l = line else { return [] }
        
        let lines = Table("lines")
            .filter(Line.topoId == l.topoId)

        do {
            let problemsOnSameTopo = try SqliteStore.shared.db.prepare(lines).map { l in
                Self.load(id: l[Line.problemId])
            }
            
            return problemsOnSameTopo.compactMap{$0}.filter { p in
//                p.id != id // don't show itself
//                && (p.parentId == nil) // don't show anyone's children
//                && (p.id != parentId) // don't show problem's parent
                p.topoId == self.topoId // show only if it's on the same topo. TODO: clean up once we handle ordering of multiple lines
            }
            .filter{$0.line?.coordinates != nil}
        }
        catch {
            print (error)
            return []
        }
    }
    
    // TODO: move to Topo
    var startGroups: [StartGroup] {
        var groups = [StartGroup]()
        
        otherProblemsOnSameTopo.forEach { p in
            let group = groups.first{$0.overlaps(with: p)}
            
            if let group = group {
                group.addProblem(p)
            }
            else {
                groups.append(StartGroup(problem: p))
            }
        }
        
        return groups
    }
    
    func distance(from: Problem) -> Double {
        if let a = from.lineFirstPoint(), let b = self.lineFirstPoint() {
            let dx = a.x - b.x
            let dy = a.y - b.y
            return sqrt(dx*dx + dy*dy)
        }
        else {
            return 1.0
        }
    }
    
    var startChildren: [Problem] {
        let problems = Table("problems")
            .filter(Problem.startParentId == id)
//            .filter(Problem.parentId == nil)
        
        do {
            return try SqliteStore.shared.db.prepare(problems).map { problem in
                Self.load(id: problem[Problem.id])
            }.compactMap{$0}
        }
        catch {
            print (error)
            return []
        }
    }
    
    var startParent: Problem? {
        guard let startParentId = startParentId else { return nil }
        
        return Self.load(id: startParentId)
    }
    
    var startVariants: [Problem] {
        if let parent = startParent {
            return parent.startVariants
        }
        else {
            return Array([self]) + startChildren
        }
    }
    
//    var startVariantsWithoutSelf: [Problem] {
//        Array(Set(startVariants).subtracting([self]))
//    }
    
    var startVariantIndex: Int? {
        startVariants.firstIndex(of: self)
    }
    
    var nextStartVariant: Problem? {
        if let index = startVariantIndex {
            return startVariants[(index + 1) % startVariants.count]
        }
        
        return nil
    }
    
    
    var children: [Problem] {
        let problems = Table("problems")
            .filter(Problem.parentId == id)

        do {
            return try SqliteStore.shared.db.prepare(problems).map { problem in
                Self.load(id: problem[Problem.id])
            }.compactMap{$0}
        }
        catch {
            print (error)
            return []
        }
    }
    
    var parent: Problem? {
        guard let parentId = parentId else { return nil }
        
        return Self.load(id: parentId)
    }
    
    var next: Problem? {
        if let circuitNumberInt = Int(self.circuitNumber), let circuitId = circuitId {
            let nextNumber = String(circuitNumberInt + 1)
            
            let query = Table("problems")
                .filter(Problem.circuitId == circuitId)
                .filter(Problem.circuitNumber == nextNumber)
            
            if let p = try! SqliteStore.shared.db.pluck(query) {
                return Problem.load(id: p[Problem.id])
            }
        }
        
        return nil
    }
    
    var previous: Problem? {
        if let circuitNumberInt = Int(self.circuitNumber), let circuitId = circuitId {
            let previousNumber = String(circuitNumberInt - 1)
            
            let query = Table("problems")
                .filter(Problem.circuitId == circuitId)
                .filter(Problem.circuitNumber == previousNumber)
            
            if let p = try! SqliteStore.shared.db.pluck(query) {
                return Problem.load(id: p[Problem.id])
            }
        }
        
        return nil
    }
}

// MARK: CoreData
extension Problem {
    func favorites() -> [Favorite] {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let request: NSFetchRequest<Favorite> = Favorite.fetchRequest()
        request.sortDescriptors = []
        
        do {
            return try context.fetch(request)
        } catch {
            fatalError("Failed to fetch favorites: \(error)")
        }
    }
    
    func ticks() -> [Tick] {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let request: NSFetchRequest<Tick> = Tick.fetchRequest()
        request.sortDescriptors = []
        
        do {
            return try context.fetch(request)
        } catch {
            fatalError("Failed to fetch ticks: \(error)")
        }
    }
}

extension Problem: CustomStringConvertible {
    var description: String {
        return "Problem \(id)"
    }
}

extension Problem : Hashable {
    static func == (lhs: Problem, rhs: Problem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


class StartGroup: Identifiable {
    private(set) var problems: [Problem]

    init(problem: Problem) {
        self.problems = [problem]
    }

    func overlaps(with problem: Problem) -> Bool {
        return problems.contains { p in
            p.distance(from: problem) < 0.04
        }
    }

    func addProblem(_ problem: Problem) {
        if overlaps(with: problem) {
            problems.append(problem)
        }
    }

    func description() -> String {
        return problems.map { $0.localizedName }.joined(separator: ", ")
    }
    
//    var problemsWithoutVariants: [Problem] {
//        problems.filter { $0.parentId == nil }
//    }
    
    func next(after: Problem) -> Problem? {
        if let index = problems.firstIndex(of: after) {
            return problems[(index + 1) % problems.count]
        }
        
        return nil
    }
}
