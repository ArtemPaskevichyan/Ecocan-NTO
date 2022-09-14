//
//  LoginView.swift
//  EcoPlan Diagnostics
//
//  Created by Artem Paskevichyan on 08.03.2022.
//

import SwiftUI

struct LoginView: View {
    @StateObject var bluetoothViewModel: BluetoothViewModel
    @State var deviceId: UUID
    @State var showId: Bool = false
    @State var showResponse: Bool = false
    @State var lockColor: Color = .secondary
    @State var showErrors = false
    @State var showAlert = false
    @State var actionSheetIsPresented = false
    
    @State var s0 = false
    @State var s1 = false
    @State var s2 = false
    
    @State var t0 = false
    @State var t1 = false
    @State var t2 = false
    
    @State var f0 = false
    @State var f1 = false
    @State var f2 = false
    
    var body: some View {
        ZStack {
            List {
                if !bluetoothViewModel.errorList.isEmpty {
                    HStack {
                        Spacer()
                        ZStack {
                            Button {
                                showErrors = true
                            } label: {
                                Label("Errors", systemImage: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                    .labelStyle(.iconOnly)
                            }
                            Text(String(bluetoothViewModel.errorList.count))
                                .foregroundColor(.white)
                                .font(.caption)
                                .background(Circle().fill(.red).frame(width: 15, height: 15))
                                .offset(x: 10, y: -10)
                        }
                    }
                    .listRowBackground(Color.clear)
                    .frame(maxWidth: .infinity)
                }
                    
                VStack {
                    HStack(alignment: .center) {
                        Label("lock", systemImage: bluetoothViewModel.deviceUnlocked ? "lock.open.fill" : "lock.fill")
                            .foregroundColor(bluetoothViewModel.deviceUnlocked ? .blue : .secondary)
                            .labelStyle(.iconOnly)
                            .font(.system(size: 30))
                            .animation(.easeInOut(duration: 0.5), value: bluetoothViewModel.deviceUnlocked)
                            .onChange(of: bluetoothViewModel.deviceUnlocked) { newValue in
                                if newValue {
                                    lockColor = .blue
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        lockColor = .red
                                    }
                                } else {
                                    lockColor = .secondary
                                }
                            }
                            
                        Button {
                            showId = true
                        } label: {
                            Text(deviceId.uuidString)
                                .frame(maxWidth: 100)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .alert(Text("ID устройства"), isPresented: $showId) {
                                    Button {
                                        showId = false
                                    } label: {
                                        Text("OK")
                                    }
                                } message: {
                                    Text(deviceId.uuidString)
                                }

                                
                        }
                        if bluetoothViewModel.isConnecting {
                            Spacer()
                                .frame(maxWidth: 10)
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: bluetoothViewModel.isConnecting)
                .listRowBackground(Color.clear)
                .frame(maxWidth: .infinity)
                
                Text("Чтобы провести диагностику определенного элемента, нажмите ПРОВЕРИТЬ. Визуально оценив работоспособность элемента на дисплее устрйоства, переключите ползунок, если элемент работает корректно")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .listRowBackground(Color.clear)
                
                Section("Сервоприводы") {
                    VStack {
                        Toggle("Cерво 1", isOn: $s0)
                        Button {
                            bluetoothViewModel.sendStringToDevice("m0")
                        } label: {
                            Text("Проверить")
                        }
                    }
                    VStack {
                        Toggle("Cерво 2", isOn: $s1)
                        Button {
                            bluetoothViewModel.sendStringToDevice("m1")
                        } label: {
                            Text("Проверить")
                        }
                    }
                    VStack {
                        Toggle("Cерво 3", isOn: $s2)
                        Button {
                            bluetoothViewModel.sendStringToDevice("m2")
                        } label: {
                            Text("Проверить")
                        }
                    }
                }
                .disabled(!bluetoothViewModel.deviceUnlocked)
                
                Section("Датчики цвета") {
                    VStack {
                        Toggle("Цвет 1", isOn: $t0)
                        Button {
                            bluetoothViewModel.sendStringToDevice("t0")
                        } label: {
                            Text("Проверить")
                        }
                    }
                    VStack {
                        Toggle("Цвет 2", isOn: $t1)
                        Button {
                            bluetoothViewModel.sendStringToDevice("t1")
                        } label: {
                            Text("Проверить")
                        }
                    }
                    VStack {
                        Toggle("Цвет 3", isOn: $t2)
                        Button {
                            bluetoothViewModel.sendStringToDevice("t2")
                        } label: {
                            Text("Проверить")
                        }
                    }
                }
                .disabled(!bluetoothViewModel.deviceUnlocked)
                
                Section("Датчики расстояния") {
                    VStack {
                        Toggle("Расстояние 1", isOn: $f0)
                        Button {
                            bluetoothViewModel.sendStringToDevice("f0")
                        } label: {
                            Text("Проверить")
                        }
                    }
                    VStack {
                        Toggle("Расстояние 2", isOn: $f1)
                        Button {
                            bluetoothViewModel.sendStringToDevice("f1")
                        } label: {
                            Text("Проверить")
                        }
                    }
                    VStack {
                        Toggle("Расстояние 3", isOn: $f2)
                        Button {
                            bluetoothViewModel.sendStringToDevice("f2")
                        } label: {
                            Text("Проверить")
                        }
                    }
                }
                .disabled(!bluetoothViewModel.deviceUnlocked)
            }
        }
        .onChange(of: self.bluetoothViewModel.showResponse) { newValue in
            print(newValue)
            showAlert = true
        }
        .toolbar {
            HStack {
                Button {
                    showResponse = true
                } label: {
                    Text("Отчет")
                        .bold()
                }
                .alert("Отчет", isPresented: $showResponse) {
                    Button {
                        
                    } label: {
                        Text("ОК")
                    }
                    
                    Button {
                        bluetoothViewModel.sendResponse(id: "1", m0: s0, m1: s1, m2: s2, t0: t0, t1: t1, t2: t2, f0: f0, f1: f1, f2: f2)
                    } label: {
                        Text("Отправить")
                            .bold()
                    }
                } message: {
                    Text(bluetoothViewModel.createResponse(m0: s0, m1: s1, m2: s2, t0: t0, t1: t1, t2: t2, f0: f0, f1: f1, f2: f2, splitter: "\r"))
                }
            }
        }
        .onAppear {
            bluetoothViewModel.connectToDevice(withID: deviceId)
        }
        .sheet(isPresented: $showErrors, onDismiss: {
            print("dissmis")
        }, content: {
            List {
                ForEach(bluetoothViewModel.errorList.reversed()) { el in
                    Text(el.text)
                }
            }
        })
        .alert("Отчет отправлен", isPresented: $showAlert) {
            Button {

            } label: {
                Text("OK")
            }
        } message: {
            if bluetoothViewModel.requestAnswer == "200" {
                Text("Отчет отправлен успешно!")
            } else {
                Text("Ошибка \(bluetoothViewModel.requestAnswer)")
            }
        }
    }
    
    func actionSheet() {
        let data = bluetoothViewModel.createPDF(id: "1", m0: s0, m1: s1, m2: s2, t0: t0, t1: t1, t2: t2, f0: f0, f1: f1, f2: f2)
        let activityVC = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true, completion: nil)
        }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(bluetoothViewModel: BluetoothViewModel(), deviceId: UUID())
    }
}
