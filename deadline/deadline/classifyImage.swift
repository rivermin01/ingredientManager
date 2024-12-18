//
//  IngredientClassifier.swift
//  deadline
//
//  Created by Kangmin on 12/1/24.
//

import Vision // CoreML을 사용하기 위해 Vision 프레임워크 가져오기
import CoreML // CoreML 모델을 사용하기 위해 CoreML 프레임워크 가져오기
import SwiftUI // SwiftUI 프레임워크 가져오기

func classifyImage(_ image: UIImage, ingredientData: IngredientData) { // 이미지를 분류하는 함수 정의
    print("이미지 분류 시작") // 분류 시작 로그 출력

    guard let model = try? VNCoreMLModel(for: IngredientClassifier(configuration: .init()).model) else { // CoreML 모델을 로드
        print("모델 로드 실패") // 모델 로드 실패 시 로그 출력
        return // 함수 종료
    }
    print("모델 로드 성공") // 모델 로드 성공 시 로그 출력
    
    guard let ciImage = CIImage(image: image) else { // UIImage를 CIImage로 변환
        print("CIImage로 변환 실패") // 변환 실패 시 로그 출력
        return // 함수 종료
    }
    print("CIImage 변환 성공") // 변환 성공 시 로그 출력

    let request = VNCoreMLRequest(model: model) { request, error in // CoreML 모델을 사용한 Vision 요청 생성
        if let error = error {
            print("예측 요청 중 오류 발생: \(error.localizedDescription)") // 예측 요청 중 오류 발생 시 로그 출력
            return
        }

        if let results = request.results as? [VNClassificationObservation], // 예측 결과를 VNClassificationObservation 배열로 변환
           let topResult = results.first { // 가장 높은 확률의 결과 선택
            DispatchQueue.main.async {
                print("예측된 식재료: \(topResult.identifier)") // 예측된 식재료 로그 출력
                ingredientData.predictedIngredient = topResult.identifier // 예측된 식재료를 저장
            }
        } else {
            print("결과를 찾을 수 없음") // 결과를 찾지 못한 경우 로그 출력
        }
    }

    let handler = VNImageRequestHandler(ciImage: ciImage, options: [:]) // 이미지 요청 핸들러 생성
    DispatchQueue.global(qos: .userInteractive).async { // 비동기로 이미지 분류 수행
        do {
            try handler.perform([request]) // 요청 수행
            print("이미지 요청 수행 완료") // 요청 수행 완료 로그 출력
        } catch {
            print("이미지 처리 실패: \(error.localizedDescription)") // 이미지 처리 실패 시 로그 출력
        }
    }
}
