//
//  RecommendationView.swift
//  deadline
//
//  Created by 최강민 on 12/16/24.
//

import Foundation
import SwiftUI

struct RecommendationView: View {
    @State private var recommendations: [String] = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("추천을 불러오는 중...")
                    .padding()
            } else if recommendations.isEmpty {
                Text("추천 결과가 없습니다.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(recommendations, id: \.self) { recipe in
                            Text(recipe)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }

            Button(action: fetchRecommendations) {
                Text("다시 추천 받기")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationBarTitle("음식 추천", displayMode: .inline)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("오류 발생"), message: Text(alertMessage), dismissButton: .default(Text("확인")))
        }
        .onAppear {
            fetchRecommendations()
        }
    }

    func fetchRecommendations() {
        isLoading = true
        let ingredients = SQLiteManager.shared.fetchIngredientsForRecommendation()

        GeminiAPI.shared.fetchRecommendations(using: ingredients) { result in
            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(let recipes):
                    self.recommendations = recipes
                case .failure(let error):
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                }
            }
        }
    }
}
