//
//  FirstView.swift
//  deadline
//
//  Created by Kangmin on 11/19/24.
//

import Foundation
import SwiftUI
import Vision
import CoreML

struct FirstView: View {
    @EnvironmentObject var screenSizeModel: ScreenSizeModel // 화면 크기 정보 참조
    @EnvironmentObject var ingredientData: IngredientData // 환경 객체로 데이터 참조
    @State private var showCamera = false // 카메라 표시 여부를 관리하는 상태 변수
    @State private var showCameraForCalories = false // 음식 칼로리 확인용 카메라 상태
    @State private var selectedImage: UIImage? = nil // 찍은 이미지를 저장하는 상태 변수
    @State private var showPreview = false // 미리보기 화면 표시 여부를 관리하는 상태 변수
    @State private var showFoodAnalysis = false
    @State private var analyzedFood: String = ""
    @State private var analyzedCalories: Int = 0
    @State private var showRecommendation = false
    
    var body: some View {
        let fontSize = screenSizeModel.screenSize.width * 0.05 // 화면 크기에 따라 텍스트 크기 조절
        let iconSize = screenSizeModel.screenSize.width * 0.1 // 화면 크기에 비례한 아이콘 크기 설정
        
        NavigationView {
            VStack(spacing: 16) {
                // 카메라로 식재료 추가 버튼
                Button(action: {
                    showCamera = true // 카메라를 표시하도록 상태 업데이트
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("식재료 추가")
                                .font(.system(size: fontSize))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text("카메라로 식재료를 촬영해요")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "camera.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: iconSize) // 세로 크기만 지정하여 비율 유지
                    }
                    .padding()  // 버튼에 여백 추가
                }
                .frame(maxWidth: .infinity, alignment: .leading) // 전체적으로 왼쪽 정렬
                .background(Color.green)  // 배경색 설정
                .foregroundColor(.white)  // 텍스트 색상
                .cornerRadius(10)  // 모서리 둥글게
                .sheet(isPresented: $showCamera) {
                    ImagePicker(image: $selectedImage, showPreview: $showPreview, sourceType: .camera)
                        .onChange(of: selectedImage) { image in
                            if let image = image {
                                print("이미지 선택됨: \(image)") // 이미지가 정상적으로 선택되었는지 확인
                                classifyImage(image, ingredientData: ingredientData)
                                // 상태를 바로 업데이트하여 NavigationLink를 작동시킵니다.
                                showPreview = true
                            } else {
                                print("이미지가 선택되지 않음")
                            }
                        }
                }
                
                // NavigationLink를 사용해 PreviewView로 이동하는 링크
                NavigationLink(
                    destination: PreviewView(image: $selectedImage, ingredientData: ingredientData),
                    isActive: $showPreview
                ) {
                    EmptyView() // NavigationLink 자체는 보이지 않음
                }
                
                // 음식 칼로리 확인 버튼
                Button(action: {
                    showCameraForCalories = true // 카메라를 표시하도록 상태 업데이트
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("음식 칼로리")
                                .font(.system(size: fontSize))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text("카메라로 음식의 칼로리를 확인해요")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "flame.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: iconSize) // 세로 크기만 지정하여 비율 유지
                    }
                    .padding()  // 버튼에 여백 추가
                }
                .frame(maxWidth: .infinity, alignment: .leading) // 전체적으로 왼쪽 정렬
                .background(Color.green)  // 배경색 설정
                .foregroundColor(.white)  // 텍스트 색상
                .cornerRadius(10)  // 모서리 둥글게
                .sheet(isPresented: $showCameraForCalories) {
                    ImagePicker(image: $selectedImage, showPreview: .constant(false), sourceType: .camera)
                        .onChange(of: selectedImage) { image in
                            if let image = image {
                                classifyFood(image: image)
                                showFoodAnalysis = true
                            } else {
                                print("이미지가 선택되지 않음")
                            }
                        }
                }
                // NavigationLink를 사용해 음식 분석 결과 뷰로 이동
                NavigationLink(
                    destination: FoodAnalysisView(food: $analyzedFood, calories: $analyzedCalories),
                    isActive: $showFoodAnalysis
                ) {
                    EmptyView()
                }
                .padding(16)  // 전체 여백 설정
                
                
                // 음식 추천 버튼
                NavigationLink(
                    destination: RecommendationView(),
                    isActive: $showRecommendation
                ) {
                    EmptyView() // NavigationLink 자체는 보이지 않음
                }

                Button(action: {
                    showRecommendation = true
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("음식 추천")
                                .font(.system(size: fontSize))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            Text("가지고 있는 재료를 활용해요")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: "fork.knife")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: iconSize)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, alignment: .leading) // 전체적으로 왼쪽 정렬
                .background(Color.green)  // 배경색 설정
                .foregroundColor(.white)  // 텍스트 색상
                .cornerRadius(10)  // 모서리 둥글게
            }
            .padding(16)  // 전체 여백 설정
            
        }
        
    }
    func classifyFood(image: UIImage) {
        guard let model = try? VNCoreMLModel(for: FoodClassifier().model) else {
            print("CoreML 모델 로드 실패")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, _ in
            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                print("이미지 분석 실패")
                return
            }
            
            DispatchQueue.main.async {
                self.analyzedFood = topResult.identifier
                self.analyzedCalories = Int(topResult.confidence * 100) // 임의로 칼로리로 변환
                print("분석된 음식: \(self.analyzedFood), 예상 칼로리: \(self.analyzedCalories)")
                self.showFoodAnalysis = true
            }
        }
        
        guard let ciImage = CIImage(image: image) else {
            print("CIImage 변환 실패")
            return
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        try? handler.perform([request])
    }
    
    // 이미지 분석 요청 수행
       private func performImageAnalysis(image: UIImage, request: VNCoreMLRequest) {
           guard let ciImage = CIImage(image: image) else {
               print("CIImage 변환 실패")
               return
           }

           let handler = VNImageRequestHandler(ciImage: ciImage)
           try? handler.perform([request])
       }
}
