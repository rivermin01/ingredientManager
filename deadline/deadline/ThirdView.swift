//
//  ThirdView.swift
//  deadline
//
//  Created by Kangmin on 11/19/24.
//

import Foundation
import SwiftUI
import SQLite3

struct ThirdView: View {
    @EnvironmentObject var screenSizeModel: ScreenSizeModel
    
    // 데이터 모델
    struct Record: Identifiable {
        var id = UUID()
        var date: String
        var title: String
        var calories: String
    }
    
    @State private var records: [Record] = [] // 데이터베이스에서 불러온 레코드 저장
    @State private var newDate = Date()
    @State private var mealTime = "아침"
    @State private var newTitle = ""
    @State private var newCalories = ""
    @State private var isAdding = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showDeleteAlert = false
    @State private var deleteItemID: UUID? = nil
    
    // 데이터베이스에서 레코드 불러오기
    func loadRecords() {
        records = fetchRecordsFromDatabase()
        print("로드된 레코드: \(records)")
    }
    
    func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
    
    // 새로운 레코드를 데이터베이스에 추가
    func addRecordToDatabase() {
        if newTitle.isEmpty || newCalories.isEmpty {
            showToastMessage("모든 필드를 입력해주세요.") // 토스트 메시지 표시
            print("레코드 추가 실패: 입력 필드가 비어있음")
            return
        }
        
        guard let db = SQLiteManager.shared.db else {
            print("데이터베이스 연결 실패")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let formattedDate = dateFormatter.string(from: newDate) + " \(mealTime)"
        
        let insertQuery = "INSERT INTO food_calories (eaten_date, english_name, calories) VALUES (?, ?, ?)"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, formattedDate, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, newTitle, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 3, Int32(newCalories) ?? 0)
            
            if sqlite3_step(statement) == SQLITE_DONE {
                print("레코드 데이터베이스에 추가 성공")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("레코드 추가 실패: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("쿼리 준비 실패: \(errorMessage)")
        }
        sqlite3_finalize(statement)
        newTitle = ""
        newCalories = ""
        isAdding = false
        loadRecords() // 데이터베이스에서 다시 로드
    }
    
    func deleteItem() {
        guard let id = deleteItemID else {
            print("삭제할 아이템 ID가 없습니다.")
            return
        }
        // SQLite에서 해당 아이템 삭제
        guard let db = SQLiteManager.shared.db else {
            print("데이터베이스 연결 실패")
            return
        }
        // 삭제할 아이템 찾기
        guard let recordToDelete = records.first(where: { $0.id == id }) else {
            print("삭제할 아이템을 찾을 수 없습니다.")
            return
        }
        print("삭제하려는 아이템 이름: \(recordToDelete.title)")
        // 데이터베이스 삭제 쿼리
        let deleteQuery = "DELETE FROM food_calories WHERE english_name = ?"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, recordToDelete.title, -1, SQLITE_TRANSIENT)
            if sqlite3_step(statement) == SQLITE_DONE {
                print("데이터베이스에서 아이템 삭제 성공: \(recordToDelete.title)")
                // UI에서 아이템 제거
                DispatchQueue.main.async {
                    self.records.removeAll { $0.id == id }
                    print("UI 업데이트 완료, 삭제된 아이템: \(recordToDelete.title)")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("데이터베이스에서 아이템 삭제 실패: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("쿼리 준비 실패: \(errorMessage)")
        }
        sqlite3_finalize(statement)
        deleteItemID = nil // 삭제 후 삭제할 아이템 초기화
        loadRecords()
    }
    
    var body: some View {
        let fontSize = screenSizeModel.screenSize.width * 0.05
        
        VStack {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(records) { record in
                        HStack {
                            Text(record.date)
                                .font(.system(size: fontSize * 0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(record.title)
                                .font(.system(size: fontSize))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Text(record.calories)
                                .font(.system(size: fontSize))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .onLongPressGesture {
                            deleteItemID = record.id
                            showDeleteAlert = true // 삭제 알림창 표시
                            print("삭제 요청된 아이템: \(record)")
                        }
                    }
                }
                .padding(.top)
            }
            
            VStack {
                Button(action: {
                    isAdding.toggle()
                    if !isAdding {
                        newTitle = ""
                        newCalories = ""
                    }
                }) {
                    Text(isAdding ? "취소하기" : "추가하기")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding()
                }
                
                if isAdding {
                    VStack {
                        DatePicker("날짜를 선택하세요", selection: $newDate, displayedComponents: .date)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                        
                        Picker("식사 시간", selection: $mealTime) {
                            Text("아침").tag("아침")
                            Text("점심").tag("점심")
                            Text("저녁").tag("저녁")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        
                        TextField("음식 이름을 입력하세요", text: $newTitle)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                        
                        TextField("칼로리를 입력하세요", text: $newCalories)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .padding(.horizontal)
                        
                        Button(action: addRecordToDatabase) {
                            Text("아이템 추가")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .padding()
                        }
                        .padding(.top)
                    }
                    
                }
                
                
            }
            .navigationBarTitle("세번째 탭", displayMode: .inline)
            .alert(isPresented: $showDeleteAlert) {
                Alert(
                    title: Text("삭제할까요?"),
                    message: Text("이 아이템을 삭제하시겠습니까?"),
                    primaryButton: .destructive(Text("예"), action: deleteItem), // 예 버튼을 눌렀을 때 삭제
                    secondaryButton: .cancel(Text("취소")) // 취소 버튼을 눌렀을 때 아무 동작도 안함
                )
            }
            .onAppear {
                loadRecords()
            }
            .overlay(
                VStack {
                    if showToast {
                        Text(toastMessage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                            .transition(.opacity) // 애니메이션 효과
                            .padding(.bottom, 50) // 화면 하단에 위치
                    }
                }
            )
        }
    }
    
    
    func fetchRecordsFromDatabase() -> [ThirdView.Record] {
        guard let db = SQLiteManager.shared.db else {
            print("데이터베이스 연결 실패")
            return []
        }
        
        let query = "SELECT eaten_date, english_name, calories FROM food_calories"
        var statement: OpaquePointer?
        var records: [ThirdView.Record] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let date = sqlite3_column_text(statement, 0).flatMap { String(cString: $0) } ?? "Unknown Date"
                let title = sqlite3_column_text(statement, 1).flatMap { String(cString: $0) } ?? "Unknown Food"
                let calories = sqlite3_column_int(statement, 2)
                
                let record = ThirdView.Record(date: date, title: title, calories: "\(calories) kcal")
                records.append(record)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("조회 쿼리 실패: \(errorMessage)")
        }
        sqlite3_finalize(statement)
        return records
    }
}
