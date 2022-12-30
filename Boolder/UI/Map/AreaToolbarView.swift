//
//  AreaToolbarView.swift
//  Boolder
//
//  Created by Nicolas Mondollot on 19/12/2022.
//  Copyright © 2022 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct AreaToolbarView: View {
    @ObservedObject var mapState: MapState
    @Binding var appTab: ContentView.Tab
    
    var body: some View {
        VStack {
            HStack {
                HStack {
                    Button {
                        mapState.selectedArea = nil
                        mapState.presentProblemDetails = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(Font.body.weight(.semibold))
                            .foregroundColor(Color(.secondaryLabel))
                            .padding(.horizontal, 16)
                        //                        .disabled(true)
                    }
                    
                    Spacer()
                    
                    Text(mapState.selectedArea?.name ?? "")
                        .lineLimit(1)
                        .truncationMode(.head)
                    //                    .frame(maxWidth: 400)
                        .padding(.vertical, 10)
                    //                    .padding(.horizontal, 25)
                        .onTapGesture {
                            mapState.presentProblemDetails = false
                            mapState.presentAreaView = true
                        }
                    //                    .background(Color.red)
                    
                    Button {
                        mapState.presentProblemDetails = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            mapState.presentAreaView = true
                        }
                    } label: {
                        Image(systemName: "info.circle")
                        //                        .background(Color.red)
                        //                        .foregroundColor(.green)
                        //                        .padding(.leading, 10)
                        //                        .disabled(true)
                    }
                    
                    Spacer()
                    
                    // quick hack to be able to center the text
                    Image(systemName: "chevron.left")
                        .font(Font.body.weight(.semibold))
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.horizontal, 16)
                        .opacity(0)
                    
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color(.secondaryLabel).opacity(0.5), radius: 5)
                
                .padding(.top, 8)
                .sheet(isPresented: $mapState.presentAreaView) {
                    NavigationView {
                        AreaView(viewModel: AreaViewModel(area: mapState.selectedArea!, mapState: mapState), appTab: $appTab)
                    }
                }

            }
            .padding(.horizontal)
            
//            if let circuit = mapState.selectedCircuit {
//                HStack {
//                    Button {
//                        mapState.unselectCircuit()
//                    } label: {
//                        Label(circuit.color.shortName, systemImage: "xmark")
//                    }
//
//                    Button {
//                        mapState.goToNextCircuitProblem()
//                    } label: {
//                        Label("Suivant", systemImage: "chevron.right")
//                    }
//                    .padding(.horizontal)
//
//                }
//                .padding(.horizontal)
//            }
            
            Spacer()
        }
    }
    
    var circuitBelongsToArea : Bool {
        guard let area = mapState.selectedArea else { return false }
        
        let areaViewModel = AreaViewModel(area: area, mapState: mapState)
        
        if let circuit = mapState.selectedCircuit {
            return areaViewModel.circuits.contains(where: { $0.id == circuit.id })
        }
        
        return false
    }
}

//struct AreaToolbarView_Previews: PreviewProvider {
//    static var previews: some View {
//        AreaToolbarView()
//    }
//}
