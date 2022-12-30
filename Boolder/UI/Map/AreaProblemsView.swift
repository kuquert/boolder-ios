//
//  AreaProblemsView.swift
//  Boolder
//
//  Created by Nicolas Mondollot on 30/12/2022.
//  Copyright © 2022 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct AreaProblemsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    let viewModel: AreaViewModel
    @Binding var appTab: ContentView.Tab
    
    @State private var searchText = ""
    
    var body: some View {
        List {
            Section {
                ForEach(filteredProblems) { problem in
                    Button {
//                        presentationMode.wrappedValue.dismiss()
                        viewModel.mapState.presentAreaView = false
                        appTab = .map
                        viewModel.mapState.selectAndPresentAndCenterOnProblem(problem)
                    } label: {
                        HStack {
                            ProblemCircleView(problem: problem)
                            Text(problem.nameWithFallback)
                            Spacer()
                            if(problem.featured) {
                                Image(systemName: "heart.fill").foregroundColor(.pink)
                            }
                            Text(problem.grade.string)
                        }
                        .foregroundColor(.primary)
                    }
                }
                
            }
        }
        .modify {
            if #available(iOS 16, *) {
                $0.searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Nom de voie")).autocorrectionDisabled()
            }
            else {
                $0
            }
        }
        .navigationTitle("Voies")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var filteredProblems: [Problem] {
        if searchText.count > 0 {
            // TODO: rewrite in SQL to improve performance
            return viewModel.problems.filter { cleanString($0.name ?? "").contains(cleanString(searchText)) }
        }
        else
        {
            return viewModel.problems
        }
    }
    
    func cleanString(_ str: String) -> String {
        str.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current) // .alphanumeric
    }
}

//struct AreaProblemsView_Previews: PreviewProvider {
//    static var previews: some View {
//        AreaProblemsView()
//    }
//}
