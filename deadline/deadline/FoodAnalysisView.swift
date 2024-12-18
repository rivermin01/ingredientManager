//
//  FoodAnalysisView.swift
//  deadline
//
//  Created by 최강민 on 12/16/24.
//

import Foundation
import SQLite3
import SwiftUI
import CoreML
import Vision

struct FoodAnalysisView: View {
    @Binding var food: String
    @Binding var calories: Int
    @State private var selectedDate = Date()
    @State private var mealTime = "아침"
    @State private var showConfirmation = false
    @State private var preCal: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Text("분석된 음식: \(food)")
                .font(.title)
                .fontWeight(.bold)
            
            Text("예상 칼로리: \(calories) kcal")
                .font(.title2)
                .foregroundColor(.gray)
            
            DatePicker("날짜를 선택하세요", selection: $selectedDate, displayedComponents: .date)
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            
            Picker("식사 시간", selection: $mealTime) {
                Text("아침").tag("아침")
                Text("점심").tag("점심")
                Text("저녁").tag("저녁")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Button(action: {
                saveToDatabase()
                showConfirmation = true
            }) {
                Text("저장하기")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding()
            }
            .alert(isPresented: $showConfirmation) {
                Alert(
                    title: Text("저장 완료"),
                    message: Text("\(food) 데이터가 저장되었습니다."),
                    dismissButton: .default(Text("확인"))
                )
            }
        }
        .padding(16)
    }

    func saveToDatabase() {
        let db = SQLiteManager.shared.db
        let query = "INSERT INTO food_calories (english_name, calories, eaten_date) VALUES (?, ?, ?)"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: selectedDate) + " \(mealTime)"
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, food, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 2, Int32(calories))
            sqlite3_bind_text(statement, 3, formattedDate, -1, SQLITE_TRANSIENT)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("데이터베이스에 저장 성공: \(food), \(calories), \(formattedDate)")
            } else {
                print("데이터베이스 저장 실패")
            }
        }
        sqlite3_finalize(statement)
    }

}

