import Foundation
import SwiftUI
import SQLite3

struct SecondView: View {
    @EnvironmentObject var screenSizeModel: ScreenSizeModel // 화면 크기 정보 참조
    @StateObject var ingredientData = IngredientData() // ingredient 데이터 모델 생성
    @State private var newKorName = ""
    @State private var newCalculatedShelfLife = ""
    @State private var isAdding = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var newLimitDate = Date()

    // 데이터 모델
    struct Item: Identifiable {
        var id = UUID()
        var title: String
        var details: String
    }

    @State private var items: [Item] = [] // ingredient_list 테이블의 데이터를 저장

    // Alert 상태 (삭제와 추가를 구분)
    @State private var showDeleteAlert = false
    @State private var deleteItemID: UUID? = nil // 삭제할 아이템을 식별할 변수
    
    // 데이터베이스에서 레코드 불러오기
    func loadRecords() {
        items = fetchIngredients()
        print("로드된 레코드: \(items)")
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
        guard let itemToDelete = items.first(where: { $0.id == id }) else {
            print("삭제할 아이템을 찾을 수 없습니다.")
            return
        }
        print("삭제하려는 아이템 이름: \(itemToDelete.title)")
        // 데이터베이스 삭제 쿼리
        let deleteQuery = "DELETE FROM ingredient_list WHERE korean_name = ?"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, itemToDelete.title, -1, SQLITE_TRANSIENT)
            if sqlite3_step(statement) == SQLITE_DONE {
                print("데이터베이스에서 아이템 삭제 성공: \(itemToDelete.title)")
                // UI에서 아이템 제거
                DispatchQueue.main.async {
                    self.items.removeAll { $0.id == id }
                    print("UI 업데이트 완료, 삭제된 아이템: \(itemToDelete.title)")
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
    
    func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
    
     
    // 새로운 레코드를 데이터베이스에 추가
    func addToDatabase() {
        // 입력 필드가 비어있는지 확인
        if newKorName.isEmpty {
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
        let formattedLimitDate = dateFormatter.string(from: newLimitDate) + " 까지"
        
        let insertQuery = "INSERT INTO ingredient_list (english_name, korean_name, calculated_shelf_life) VALUES (?, ?, ?)"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, newKorName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, newKorName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, formattedLimitDate, -1, SQLITE_TRANSIENT)
            
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
        newKorName = ""
        isAdding = false
        loadRecords() // 데이터베이스에서 다시 로드
    }
    
    
    func fetchIngredients() -> [SecondView.Item] {
        guard let db = SQLiteManager.shared.db else {
            print("데이터베이스 연결 실패")
            return []
        }
        let query = "SELECT korean_name, calculated_shelf_life FROM ingredient_list"
        var statement: OpaquePointer?
        var ingredients: [SecondView.Item] = []

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let koreanName = sqlite3_column_text(statement, 0).flatMap { String(cString: $0) } ?? "NULL"
                let calculatedShelfLife = sqlite3_column_text(statement, 1).flatMap { String(cString: $0) } ?? "NULL"

                let ingredient = SecondView.Item(title: koreanName, details: calculatedShelfLife)
                ingredients.append(ingredient)
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("조회 쿼리 준비 실패: \(errorMessage)")
        }
        sqlite3_finalize(statement)
        return ingredients
    }

    var body: some View {
        let fontSize = screenSizeModel.screenSize.width * 0.05 // 화면 크기에 따른 폰트 크기 계산

        VStack {
            // 세로 스크롤 뷰로 아이템 리스트
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(items) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.system(size: fontSize)) // 폰트 크기 적용
                                    .fontWeight(.bold)
                                    .padding(.bottom, 2)
                                Text(item.details)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .onLongPressGesture {
                            deleteItemID = item.id
                            showDeleteAlert = true // 삭제 알림창 표시
                            print("삭제 요청된 아이템: \(item)")
                        }
                    }
                    VStack {
                        // 추가하기 / 취소하기 버튼
                        Button(action: {
                            isAdding.toggle() // 추가하기 상태 토글
                            if !isAdding {
                                newKorName = "" // 취소 시 입력 초기화
                                newCalculatedShelfLife = ""
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
                        
                        // 텍스트 필드와 추가 버튼 (isAdding이 true일 때만 보이게)
                        if isAdding {
                            VStack {
                                TextField("이름을 입력하세요", text: $newKorName)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                    .padding(.horizontal)

                                DatePicker("소비기한을 선택하세요", selection: $newLimitDate, displayedComponents: .date)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                    .padding(.horizontal)

                                Button(action: addToDatabase) {
                                    Text("아이템 추가")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, minHeight: 50)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                        .padding()
                                        
                                }
                            }
                            .padding(.top)
                        }
                    }
                    
                }
                .padding(.top)
            }
        }
        .navigationBarTitle("두번째 탭", displayMode: .inline)
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("삭제할까요?"),
                message: Text("이 아이템을 삭제하시겠습니까?"),
                primaryButton: .destructive(Text("예"), action: deleteItem), // 예 버튼을 눌렀을 때 삭제
                secondaryButton: .cancel(Text("취소")) // 취소 버튼을 눌렀을 때 아무 동작도 안함
            )
        }
        .onAppear {
            loadRecords() // 화면 표시 시 데이터 로드
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
