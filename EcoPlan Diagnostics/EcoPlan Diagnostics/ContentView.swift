//
//  ContentView.swift
//  EcoPlan Diagnostics
//
//  Created by Artem Paskevichyan on 08.03.2022.
//

import SwiftUI


struct AppObserver {
    private static let enteranceKey: String = "Entrance"
    var firstEntrance: Bool {
        return !UserDefaults.standard.bool(forKey: AppObserver.enteranceKey)
    }
    
    func changeState() {
        UserDefaults.standard.set(true, forKey: AppObserver.enteranceKey)
    }
}



struct ContentView: View {
    @State var bluetoothViewModel = BluetoothViewModel()
    @State var appObserver = AppObserver()
    @State var showErrors = true
    
    var body: some View {
        NavigationView {
            if appObserver.firstEntrance {
                EntryView(viewModel: bluetoothViewModel, observerViewModel: appObserver)
            } else {
                ConnectionView(viewModel: bluetoothViewModel)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
