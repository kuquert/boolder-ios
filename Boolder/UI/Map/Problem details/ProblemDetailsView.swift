//
//  ProblemDetailsView.swift
//  Boolder
//
//  Created by Nicolas Mondollot on 25/04/2020.
//  Copyright © 2020 Nicolas Mondollot. All rights reserved.
//

import SwiftUI
import MapKit

struct ProblemDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var odrManager: ODRManager
    @Environment(\.openURL) var openURL
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: Favorite.entity(), sortDescriptors: []) var favorites: FetchedResults<Favorite>
    @FetchRequest(entity: Tick.entity(), sortDescriptors: []) var ticks: FetchedResults<Tick>
    
    @Binding var problem: Problem
    @State private var areaResourcesDownloaded = false
    
    @State private var presentSaveActionsheet = false
    @State private var presentSharesheet = false
    
    @State private var lineDrawPercentage: CGFloat = .zero
    
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                TopoView(
                    problem: $problem,
                    lineDrawPercentage: $lineDrawPercentage,
                    areaResourcesDownloaded: $areaResourcesDownloaded
                )
                .zIndex(10)
                
                infos
                
                actionButtons
            }
        }
        
        .onAppear{
            odrManager.requestResources(tags: Set(["area-\(problem.areaId)"]), onSuccess: {
                areaResourcesDownloaded = true
                
            }, onFailure: { error in
                print("On-demand resource error")
                
                // FIXME: implement UI, log errors
                switch error.code {
                case NSBundleOnDemandResourceOutOfSpaceError:
                    print("You don't have enough space available to download this resource.")
                case NSBundleOnDemandResourceExceededMaximumSizeError:
                    print("The bundle resource was too big.")
                case NSBundleOnDemandResourceInvalidTagError:
                    print("The requested tag does not exist.")
                default:
                    print(error.description)
                }
            })
        }
    }
    
    var infos: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(problem.nameWithFallback)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .minimumScaleFactor(0.5)
                        
                        Spacer()
                        
                        Text(problem.grade.string)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 4)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    
                    if problem.steepness != .other {
                        HStack(alignment: .firstTextBaseline) {
                            Image(problem.steepness.imageName)
                                .frame(minWidth: 16)
                            Text(problem.steepness.localizedName)
                            
                        }
                        .font(.body)
                        .foregroundColor(Color(UIColor(.black).lighter(0.3)))
                    }
                    
                    if(problem.sitStart) {
                        if problem.steepness != .other {
                            Text("•")
                                .font(.body)
                                .foregroundColor(Color(UIColor(.black).lighter(0.3)))
                        }
                        Text("problem.sit_start")
                            .font(.body)
                            .foregroundColor(Color(UIColor(.black).lighter(0.3)))
                    }
                    
                    Spacer()
                    
                    if isFavorite() {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color.yellow)
                    }
                    
                    if isTicked() {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Color.appGreen)
                    }
                }
            }
        }
        .padding(.top, 0)
        .padding(.horizontal)
        //        .layoutPriority(1) // without this the imageview prevents the title from going multiline
        
    }
    
    var actionButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .center, spacing: 16) {
                
                if problem.bleauInfoId != nil && problem.bleauInfoId != "" {
                    Button(action: {
                        openURL(URL(string: "https://bleau.info/a/\(problem.bleauInfoId ?? "").html")!)
                    }) {
                        HStack(alignment: .center, spacing: 8) {
                            Image(systemName: "info.circle")
                            Text("Bleau.info").fixedSize(horizontal: true, vertical: true)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(Pill(fill: true))
                }
                
                Button(action: {
                    presentSaveActionsheet = true
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "bookmark")
                        Text("problem.action.save").fixedSize(horizontal: true, vertical: true)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(Pill())
                .actionSheet(isPresented: $presentSaveActionsheet) {
                    ActionSheet(title: Text("problem.action.save"), buttons: [
                        .default(Text(isFavorite() ? "problem.action.favorite.remove" : "problem.action.favorite.add")) {
                            toggleFavorite()
                        },
                        .default(Text(isTicked() ? "problem.action.untick" : "problem.action.tick")) {
                            toggleTick()
                        },
                        .cancel()
                    ])
                }
                
                Button(action: {
                    presentSharesheet = true
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("problem.action.share").fixedSize(horizontal: true, vertical: true)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(Pill())
                .sheet(isPresented: $presentSharesheet,
                       content: {
                    ActivityView(activityItems: [boolderURL] as [Any], applicationActivities: nil) }
                )
                
                Button(action: {
                    if let url = mailToURL {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "text.bubble")
                        Text("problem.action.report").fixedSize(horizontal: true, vertical: true)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                }
                .buttonStyle(Pill())
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
    }
    
    var variants: some View {
        VStack(alignment: .leading, spacing: 4) {
            if(problem.variants.count > 0) {
                
                Divider()
                
                ForEach(problem.variants) { variant in
                    
                    Button(action: {
                        switchToProblem(variant)
                        
                    }, label: {
                        HStack {
                            Text(variant.nameWithFallback)
                                .lineLimit(2)
                            Spacer()
                            Text(variant.grade.string)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                        .frame(height: 44)
                    })
                    
                    Divider()
                }
            }
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    var boolderURL: URL {
        URL(string: "https://www.boolder.com/\(NSLocale.websiteLocale)/p/\(String(problem.id))")!
    }
    
    var mailToURL: URL? {
        let recipient = "hello@boolder.com"
        let subject = "Feedback".stringByAddingPercentEncodingForRFC3986() ?? ""
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        
        let body = [
            "",
            "",
            "------",
            "Problem #\(String(problem.id)) - \(problem.nameWithFallback)",
            "Boolder \(appVersion ?? "") (\(buildNumber ?? ""))",
            "iOS \(UIDevice.current.systemVersion)",
        ]
            .map{$0.stringByAddingPercentEncodingForRFC3986() ?? ""}
            .joined(separator: "%0D%0A")
        
        return URL(string: "mailto:\(recipient)?subject=\(subject)&body=\(body)")
    }
    
    // FIXME: this code is duplicated from TopoView.swift => make it DRY
    
    func switchToProblem(_ newProblem: Problem) {
        lineDrawPercentage = 0.0
        problem = newProblem
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            animate { lineDrawPercentage = 1.0 }
        }
    }
    
    func animate(action: () -> Void) {
        withAnimation(Animation.easeInOut(duration: 0.5)) {
            action()
        }
    }
    
    // MARK: Ticks and favorites
    
    func isFavorite() -> Bool {
        favorite() != nil
    }
    
    func favorite() -> Favorite? {
        favorites.first { (favorite: Favorite) -> Bool in
            return Int(favorite.problemId) == problem.id
        }
    }
    
    func toggleFavorite() {
        if isFavorite() {
            deleteFavorite()
        }
        else {
            createFavorite()
        }
    }
    
    func createFavorite() {
        let favorite = Favorite(context: managedObjectContext)
        favorite.id = UUID()
        favorite.problemId = Int64(problem.id)
        favorite.createdAt = Date()
        
        do {
            try managedObjectContext.save()
        } catch {
            // handle the Core Data error
        }
    }
    
    func deleteFavorite() {
        guard let favorite = favorite() else { return }
        managedObjectContext.delete(favorite)
        
        do {
            try managedObjectContext.save()
        } catch {
            // handle the Core Data error
        }
    }
    
    func isTicked() -> Bool {
        tick() != nil
    }
    
    func tick() -> Tick? {
        ticks.first { (tick: Tick) -> Bool in
            return Int(tick.problemId) == problem.id
        }
    }
    
    func toggleTick() {
        if isTicked() {
            deleteTick()
        }
        else {
            createTick()
        }
    }
    
    func createTick() {
        let tick = Tick(context: managedObjectContext)
        tick.id = UUID()
        tick.problemId = Int64(problem.id)
        tick.createdAt = Date()
        
        do {
            try managedObjectContext.save()
        } catch {
            // handle the Core Data error
        }
    }
    
    func deleteTick() {
        guard let tick = tick() else { return }
        managedObjectContext.delete(tick)
        
        do {
            try managedObjectContext.save()
        } catch {
            // handle the Core Data error
        }
    }
}

// https://useyourloaf.com/blog/how-to-percent-encode-a-url-string/
extension String {
    func stringByAddingPercentEncodingForRFC3986() -> String? {
        let unreserved = "-._~/?"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)
        return addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)
    }
}


//struct ProblemDetailsView_Previews: PreviewProvider {
//    static let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//
//    static var previews: some View {
//        ProblemDetailsView(problem: .constant(dataStore.problems.first!))
//            .environment(\.managedObjectContext, context)
//    }
//}

