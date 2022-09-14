//
//  SwiftUIView.swift
//  EcoPlan Diagnostics
//
//  Created by Artem Paskevichyan on 08.03.2022.
//

import SwiftUI

struct EntryView: View {
    @StateObject var viewModel: BluetoothViewModel
    @State var observerViewModel: AppObserver
    var subtitleTextFault = "Разрешите устройству подключаться к Bloetooth устройствам, чтобы уметь доступ к диагностике оборудования"
    var subtitleTextSucces = "Доступ предоставлен!"
    
    var body: some View {
        ZStack {
            VStack {
                Text("EcoPlan Diagnostics")
                    .font(.title2)
                
                Text(viewModel.hasAccess() ? subtitleTextSucces : subtitleTextFault)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            VStack {
                Spacer()
                if viewModel.hasAccess() {
                    Button {
                        
                    } label: {
                        NavigationLink() {
                            ConnectionView(viewModel: viewModel)
                                .onAppear {
                                    observerViewModel.changeState()
                                }
                        } label: {
                            Text("Продолжить")
                                .frame(maxWidth: .infinity, maxHeight: 40)
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    
                } else {
                    Button {
                        viewModel.redirectToSettings()
                    } label: {
                        Text("Предоставить доступ")
                            .frame(maxWidth: .infinity, maxHeight: 40)
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct EntryView_Previews: PreviewProvider {
    static var previews: some View {
        EntryView(viewModel: BluetoothViewModel(), observerViewModel: AppObserver())
    }
}
