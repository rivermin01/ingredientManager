import Foundation
import SwiftUI
import SQLite3 // SQLite를 사용하기 위해 SQLite3 임포트

struct PreviewView: View {
    @Binding var image: UIImage? // 이전 화면에서 전달받은 이미지
    @State private var predictedIngredient: String = "알 수 없음" // 예측된 식재료를 저장하는 상태 변수
    @State private var korName: String = "알 수 없음"
    @State private var estimatedExpirationDate: String = "알 수 없음" // 예측된 유통기한을 저장하는 상태 변수
    @ObservedObject var ingredientData: IngredientData // IngredientData 인스턴스 참조
    @Environment(\.presentationMode) var presentationMode // 현재 뷰의 표시 상태 관리


    var body: some View {
        VStack(spacing: 16) {
            // 찍은 사진 미리보기
            if let image = image { // 이미지가 있을 경우
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300) // 이미지의 최대 크기 설정
                    .cornerRadius(10) // 모서리를 둥글게 설정
                    .padding() // 여백 추가
            } else { // 이미지가 없을 경우
                Text("이미지를 찾을 수 없습니다.")
                    .font(.headline) // 폰트 스타일 설정
                    .foregroundColor(.gray) // 텍스트 색상 설정
            }

            // 예측된 식재료 표시
            VStack(alignment: .leading, spacing: 8) {
                Text("예측된 식재료")
                    .font(.title2) // 폰트 크기 설정
                    .fontWeight(.bold) // 폰트 두께 설정
                    .padding(.bottom, 4) // 아래쪽 여백 설정

                Text(predictedIngredient) // 예측된 식재료 이름 표시
                    .font(.body) // 기본 폰트 설정
                    .foregroundColor(.primary) // 기본 색상 설정
                    .padding() // 여백 추가
                    .background(Color.gray.opacity(0.1)) // 배경 색상 설정
                    .cornerRadius(8) // 모서리를 둥글게 설정
            }
            .padding() // 전체 여백 설정

            // 예측된 식재료의 유통기한 표시
            VStack(alignment: .leading, spacing: 8) {
                Text("예측된 유통기한")
                    .font(.title2) // 폰트 크기 설정
                    .fontWeight(.bold) // 폰트 두께 설정
                    .padding(.bottom, 4) // 아래쪽 여백 설정

                Text(estimatedExpirationDate) // 예측된 유통기한 표시
                    .font(.body) // 기본 폰트 설정
                    .foregroundColor(.primary) // 기본 색상 설정
                    .padding() // 여백 추가
                    .background(Color.gray.opacity(0.1)) // 배경 색상 설정
                    .cornerRadius(8) // 모서리를 둥글게 설정
            }
            .padding() // 전체 여백 설정
            
            //추가 버튼
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    // 필수 데이터가 있는지 확인
                    if predictedIngredient != "알 수 없음" && estimatedExpirationDate != "알 수 없음" {
                        let englishName = ingredientData.predictedIngredient // 영어 이름
                        let calculatedShelfLife = String(estimatedExpirationDate) + " 까지"    // 계산된 유통기한

                        // SQLite에 데이터 삽입
                        SQLiteManager.shared.insertIngredientToList(englishName: String(englishName), koreanName: String(englishName), calculatedShelfLife: calculatedShelfLife)

                        print("재료 추가 완료: \(englishName), \(englishName), \(calculatedShelfLife)")
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        print("추가할 수 없는 데이터입니다.")
                    }
                }) {
                    Text("식재료 추가")
                        .font(.title2) // 폰트 크기 설정
                        .fontWeight(.bold) // 폰트 두께 설정
                        .padding(.bottom, 4) // 아래쪽 여백 설정
                }
            }
            .padding() // 전체 여백 설정
            

            Spacer() // 남은 공간을 모두 차지하도록 설정
        }
        .navigationBarTitle("사진 미리보기", displayMode: .inline) // 네비게이션 바 타이틀 설정
        .padding() // 전체 여백 설정
        .onAppear {
            // 이미지가 있으면 이미지 분류를 시작합니다.
            if let selectedImage = image {
                classifyImage(selectedImage, ingredientData: ingredientData)
            }
        }
        // `predictedIngredient` 값이 변경될 때 `updatePrediction`을 호출하도록 설정합니다.
        .onChange(of: ingredientData.predictedIngredient) { newValue in
            updatePrediction()
        }
    }
    

    // 예측된 정보를 업데이트하는 함수
    func updatePrediction() {
        guard let db = SQLiteManager.shared.db else {
            print("데이터베이스 연결 실패")
            return
        }

        let predictedEnglishName = ingredientData.predictedIngredient
        print("예측된 영문 이름: \(predictedEnglishName)")
        let query = "SELECT korean_name, shelf_life FROM ingredient_info WHERE english_name = ?"
        print("쿼리 실행 값: \(query)")
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, predictedEnglishName, -1, nil)

            if sqlite3_step(statement) == SQLITE_ROW {
                let koreanName = sqlite3_column_text(statement, 0).flatMap { String(cString: $0) } ?? "NULL"
                let shelfLife = sqlite3_column_int(statement, 1)
                
                // UI 업데이트
                DispatchQueue.main.async {
                    predictedIngredient = predictedEnglishName
                    korName = koreanName
                    estimatedExpirationDate = calculateExpirationDate(days: Int(shelfLife))
                    
                    print("영어이름: \(predictedEnglishName)")
                    print("이름: \(koreanName)")
                    print("유통기한: \(shelfLife)")
                }
            } else {
                print("예측된 정보를 찾을 수 없습니다.")
            }
        } else {
            print("쿼리 준비 실패")
        }
        sqlite3_finalize(statement)
    }

    // 유통기한을 계산하여 반환하는 함수
    func calculateExpirationDate(days: Int) -> String {
        let currentDate = Date()
        guard let expirationDate = Calendar.current.date(byAdding: .day, value: days, to: currentDate) else {
            return "알 수 없음"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter.string(from: expirationDate)
    }
    
    
    
}



