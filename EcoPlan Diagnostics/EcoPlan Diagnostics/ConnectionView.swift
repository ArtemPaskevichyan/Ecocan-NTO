//
//  ConnectionView.swift
//  EcoPlan Diagnostics
//
//  Created by Artem Paskevichyan on 08.03.2022.
//

import SwiftUI

struct ConnectionView: View {
    @StateObject var viewModel: BluetoothViewModel
    @State var selectedDevice = UUID()
    
    var fakeData = [
        DeviceData(name: "AirPods", id: UUID()),
        DeviceData(name: "Trash", id: UUID()),
        DeviceData(id: UUID())
    ]
    
    var body: some View {
        ZStack {
            if viewModel.manager.state == .poweredOn {
                Form {
                    Picker("Диагностируемые устройства", selection: $selectedDevice) {
                        ForEach(viewModel.devicesArrayMatches) { device in
                            Text(device.name!)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    Picker("Другие устройства", selection: $selectedDevice) {
                        ForEach(viewModel.devicesArrayElse) { device in
                            Text(device.name ?? device.id.uuidString)
                        }
                    }
                    .pickerStyle(.inline)
                }
            } else {
                List {
                    Text("Включите Bluetooth для обнаружения и диагностики устйроств")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .listRowBackground(Color.clear)
                    
                }
                
            }
        }
        .navigationTitle("Устройства")
        .toolbar {
            HStack {
                if viewModel.isScannig {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(width: 30, height: 30)
                } else {
                    Button {
                        viewModel.getDevicesList()
                    } label: {
                        Label("Update", systemImage: "arrow.clockwise")
                            .labelStyle(.iconOnly)
                    }
                    .frame(width: 30, height: 30)
                }
                
                
                Button {
                    
                } label: {
                    NavigationLink {
                        LoginView(bluetoothViewModel: viewModel, deviceId: selectedDevice)
                    } label: {
                        Text("Далее")
                            .bold()
                    }

                }
                .disabled(viewModel.devicesArray.filter { $0.id == self.selectedDevice}.count == 0)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.getDevicesList()
        }
    }
}

struct ConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectionView(viewModel: BluetoothViewModel())
    }
}
