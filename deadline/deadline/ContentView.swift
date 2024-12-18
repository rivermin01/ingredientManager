//
//  ContentView.swift
//  deadline
//
//  Created by Kangmin on 10/30/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject var screenSizeModel = ScreenSizeModel() // 화면 크기 모델 생성
    @StateObject var ingredientData = IngredientData() // ingredient 데이터 모델 생성
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            Color.clear
                .onAppear {
                    screenSizeModel.updateSize(newSize: size) // 화면 크기 업데이트
                    print("GeometryReader onAppear - size: \(size)")
                }
                .onChange(of: size) {
                    screenSizeModel.updateSize(newSize: size) // 화면 크기 업데이트
                    print("GeometryReader onChange - size: \(size)")
                }
            
            TabView {
                FirstView()
                    .environmentObject(screenSizeModel) // 화면 크기 모델 전달
                    .environmentObject(ingredientData) // 환경 객체로 전달
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                
                SecondView()
                    .environmentObject(screenSizeModel)
                    .environmentObject(ingredientData) // 환경 객체로 전달
                    .tabItem {
                        Image(systemName: "cube.box")
                        Text("ingredient")
                    }
                
                ThirdView()
                    .environmentObject(screenSizeModel)
                    .tabItem {
                        Image(systemName: "note.text")
                        Text("record")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}






