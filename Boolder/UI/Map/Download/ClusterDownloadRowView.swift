//
//  ClusterDownloadRowView.swift
//  Boolder
//
//  Created by Nicolas Mondollot on 24/07/2024.
//  Copyright © 2024 Nicolas Mondollot. All rights reserved.
//

import SwiftUI

struct ClusterDownloadRowView: View {
    @ObservedObject var clusterDownloader: ClusterDownloader
    let cluster: Cluster
    @Binding var handpickedDownload: Bool
    
    var body: some View {
        if clusterDownloader.allDownloaded {
            // nothing
        }
        else if clusterDownloader.downloadingOrQueued && !handpickedDownload {
            Section {
                Button {
                    clusterDownloader.stopDownloads()
                } label: {
                    HStack {
                        Image(systemName: "stop.circle").frame(height: 18)
                        Text("Téléchargement \(Int(Double(clusterDownloader.progress*100).rounded()))%")
                    }
                    .font(.title3.weight(.semibold))
                    .padding(.vertical, 8)
                }
                .buttonStyle(LargeButton())
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        else {
            Section {
                Button {
                    // TODO: launch area downloads at the same time or no?
                    // TODO: handle priority?
                    handpickedDownload = false // move logic to ClusterDownloader
                    clusterDownloader.start()
                } label: {
                    HStack {
                        Image(systemName: "icloud.and.arrow.down").frame(height: 18)
                        Text("Télécharger")
                        //                        .font(.body.weight(.semibold))
                        //                        .padding(.vertical)
                    }
                    .font(.title3.weight(.semibold))
                    .padding(.vertical, 8)
                    
                }
                .buttonStyle(LargeButton())
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
        
    }
}

//#Preview {
//    ClusterDownloadRowView()
//}
