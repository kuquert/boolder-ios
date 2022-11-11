//
//  SavedProblems.swift
//  Boolder
//
//  Created by Nicolas Mondollot on 11/11/2022.
//  Copyright © 2022 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct SavedProblemsView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: Favorite.entity(), sortDescriptors: []) var favorites: FetchedResults<Favorite>
    @FetchRequest(entity: Tick.entity(), sortDescriptors: []) var ticks: FetchedResults<Tick>
    
    @Binding var tabSelection: ContentView.Tab
    let mapState: MapState
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(groupedFavoriteProblemsKeys, id: \.self) { (area: Area) in
                        Section(header: Text(area.name)) {
                            ForEach(groupedFavoriteProblems[area]!.sorted(by: \.grade)) { problem in
                                Button {
                                    tabSelection = .map
                                    mapState.selectAndPresentAndCenterOnProblem(problem)
                                } label: {
                                    HStack {
                                        ProblemCircleView(problem: problem)
                                        
                                        Text(problem.nameWithFallback)
                                        
                                        Spacer()
                                        
                                        Text(problem.grade.string)
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .modify {
                    if #available(iOS 15, *) {
                        $0.headerProminence(.increased)
                    }
                    else {
                        $0
                    }
                }
            }
            .navigationTitle("Mes voies")
        }
    }
    
    var groupedFavoriteProblems : Dictionary<Area?, [Problem]> {
        Dictionary(grouping: favoriteProblems, by: { (problem: Problem) in
            Area.load(id: problem.areaId)
        })
    }
    
    var groupedFavoriteProblemsKeys : [Area] {
        groupedFavoriteProblems.keys.compactMap{$0}.sorted()
    }
    
    var favoriteProblems: [Problem] {
        favorites.map { f in
            Problem.load(id: Int(f.problemId))
        }.compactMap { $0 }
    }
}

//struct SavedProblems_Previews: PreviewProvider {
//    static var previews: some View {
//        SavedProblemsView()
//    }
//}
