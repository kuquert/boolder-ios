//
//  ProblemListView.swift
//  Boolder
//
//  Created by Nicolas Mondollot on 25/04/2020.
//  Copyright © 2020 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct ProblemListView: View {
    @EnvironmentObject var dataStore: DataStore
    @Binding var selectedProblem: ProblemAnnotation
    @Binding var presentProblemDetails: Bool
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: Favorite.entity(), sortDescriptors: []) var favorites: FetchedResults<Favorite>
    @FetchRequest(entity: Tick.entity(), sortDescriptors: []) var ticks: FetchedResults<Tick>
    
    var body: some View {
        List {
            ForEach(dataStore.groupedAnnotationsKeys, id: \.self) { (circuit: Circuit.CircuitType) in
                // FIXME: simplify the code by using a tableview footer when/if it becomes possible
                // NB: we want a footer view (or bottom inset?) to be able to show the FabFilters with no background when user scrolls to the bottom of the list
                Section(
                    header: Text("Circuit \(Circuit(circuit).name)").font(.title).bold().foregroundColor(Color(.label)).padding(.top, (circuit == self.dataStore.groupedAnnotationsKeys.first) ? 32 : 0),
                    footer: Rectangle().fill(Color.clear).frame(width: 1, height: (circuit == self.dataStore.groupedAnnotationsKeys.last) ? 120 : 0, alignment: .center)
                    ) {
                    ForEach(self.dataStore.groupedAnnotations[circuit]!, id: \.self) { (problem: ProblemAnnotation) in
                        
                        Button(action: {
                            self.selectedProblem = problem
                            self.presentProblemDetails = true
                        }) {
                            HStack {
                                CircuitNumberView(number: problem.displayLabel, color: problem.displayColor())
                                
                                Text(problem.name ?? "Sans nom")
                                    .foregroundColor(problem.name != nil ? Color(.label) : Color.gray)
                                
                                Spacer()
                                
                                if self.isFavorite(problem: problem) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(Color.yellow)
                                }
                                
                                if self.isTicked(problem: problem) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.green)
                                }
                                
                                Text(problem.grade?.string ?? "")
                            }
                        }
                        .foregroundColor(Color(.label))
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .animation(.easeInOut(duration: 0))
    }
    
    func isFavorite(problem: ProblemAnnotation) -> Bool {
        favorites.contains { (favorite: Favorite) -> Bool in
            return Int(favorite.problemId) == problem.id
        }
    }
    
    func isTicked(problem: ProblemAnnotation) -> Bool {
        ticks.contains { (tick: Tick) -> Bool in
            return Int(tick.problemId) == problem.id
        }
    }
}

struct ProblemListView_Previews: PreviewProvider {
    static let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    static var previews: some View {
        NavigationView {
            ProblemListView(selectedProblem: .constant(ProblemAnnotation()), presentProblemDetails: .constant(false))
                .navigationBarTitle("Rocher Canon", displayMode: .inline)
        }
        .environmentObject(DataStore.shared)
        .environment(\.managedObjectContext, self.context)
    }
}
