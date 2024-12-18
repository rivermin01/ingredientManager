//
//  IngredientData.swift
//  deadline
//
//  Created by Kangmin on 12/1/24.
//

import Foundation
import SwiftUI

class IngredientData: ObservableObject {
    @Published var items: [Item] = []
    @Published var predictedIngredient: String = "알 수 없음" // 예측된 식재료 저장 변수 추가
    @Published var predictedIngredientKor: String = "알 수 없음"
    @Published var estimatedExpirationDate: String = "알 수 없음"
    @Published var storageMethod: String = "알 수 없음"

    func addNewItem(_ item: Item) {
        items.append(item)
    }
}

struct Item: Identifiable {
    var id = UUID() // 고유 식별자
    var title: String
    var details: String
    var storageMethod: String
}
