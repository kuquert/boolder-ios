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
    @Binding var selectedProblem: Problem
    @Binding var presentProblemDetails: Bool
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @FetchRequest(entity: Favorite.entity(), sortDescriptors: []) var favorites: FetchedResults<Favorite>
    @FetchRequest(entity: Tick.entity(), sortDescriptors: []) var ticks: FetchedResults<Tick>
    
    var body: some View {
        List {
 
            ForEach(groupedProblemsKeys, id: \.self) { (circuitColor: Circuit.CircuitColor) in
                // FIXME: simplify the code by using a tableview footer when/if it becomes possible
                // NB: we want a footer view (or bottom inset?) to be able to show the FabFilters with no background when user scrolls to the bottom of the list
                Section(
                    header: Text(circuitColor.longName()).font(.title2).bold().foregroundColor(.primary).padding(.bottom, 8).textCase(.none),
                    footer: Rectangle().fill(Color.clear).frame(width: 1, height: (circuitColor == groupedProblemsKeys.last) ? 120 : 0, alignment: .center)
                    ) {
                        ForEach(groupedProblems[circuitColor]!) { (problem: Problem) in


                        Button(action: {
                            selectedProblem = problem
                            presentProblemDetails = true
                        }) {
                            HStack {
                                ProblemCircleView(problem: problem)
                                
                                Text(problem.nameWithFallback())
                                    .foregroundColor(.primary)

                                Spacer()

                                if isFavorite(problem: problem) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(Color.yellow)
                                }

                                if isTicked(problem: problem) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color.appGreen)
                                }

                                Text(problem.grade.string)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .listStyle(GroupedListStyle())
        .animation(.easeInOut(duration: 0))
    }
    
    var groupedProblems : Dictionary<Circuit.CircuitColor, [Problem]> {
        Dictionary(grouping: dataStore.sortedProblems, by: { (problem: Problem) in
            problem.circuitColor ?? Circuit.CircuitColor.offCircuit
        })
    }
    
    var groupedProblemsKeys : [Circuit.CircuitColor] {
        groupedProblems.keys.sorted()
    }
    
    func cleanString(_ str: String) -> String {
        str.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current).alphanumeric
    }
    
    func isFavorite(problem: Problem) -> Bool {
        favorites.contains { (favorite: Favorite) -> Bool in
            return Int(favorite.problemId) == problem.id
        }
    }
    
    func isTicked(problem: Problem) -> Bool {
        ticks.contains { (tick: Tick) -> Bool in
            return Int(tick.problemId) == problem.id
        }
    }
}

extension String {
    var alphanumeric: String {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted).joined().lowercased()
    }
}

struct ProblemListView_Previews: PreviewProvider {
    static let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    static var previews: some View {
        NavigationView {
            ProblemListView(selectedProblem: .constant(Problem()), presentProblemDetails: .constant(false))
                .navigationBarTitle("Rocher Canon", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(DataStore())
        .environment(\.managedObjectContext, context)
    }
}
