import Foundation
import SQLite3

class SQLiteManager: ObservableObject  {
    
    @Published var ingredientList: [Ingredient] = []
    static let shared = SQLiteManager()

    var db: OpaquePointer?

    private init() {
        openDatabase()
        insertDefaultIngredients() // 기본 재료 데이터 삽입
        insertDefaultFood()
    }

    // 데이터베이스 열기 함수
    private func openDatabase() {
        guard let dbPath = getDatabasePath() else {
            print("데이터베이스 경로를 찾을 수 없습니다.")
            return
        }

        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            print("데이터베이스 열기 성공: \(dbPath)")
            // UTF-8 인코딩 설정
            if sqlite3_exec(db, "PRAGMA encoding = \"UTF-8\";", nil, nil, nil) == SQLITE_OK {
                print("데이터베이스 UTF-8 인코딩 설정 성공")
            } else {
                print("데이터베이스 UTF-8 인코딩 설정 실패")
            }
            createTablesIfNeeded() // 필요한 모든 테이블을 생성
        } else {
            print("데이터베이스 열기 실패")
        }
    }
        
    

    // 데이터베이스 경로 반환 함수
    private func getDatabasePath() -> String? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent("appDatabase.sqlite").path
    }

    // 필요한 모든 테이블 생성 함수
    private func createTablesIfNeeded() {
        createIngredientInfoTable()
        createIngredientListTable()
        createFoodInfoTable()
        createFoodCaloriesTable()
    }

    // 재료 정보 테이블 생성
    private func createIngredientInfoTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS ingredient_info (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            english_name TEXT,
            korean_name TEXT,
            shelf_life INTEGER
        );
        """

        executeQuery(createTableQuery)
    }

    // 재료 리스트 테이블 생성
    private func createIngredientListTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS ingredient_list (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            english_name TEXT,
            korean_name TEXT,
            calculated_shelf_life TEXT
        );
        """

        executeQuery(createTableQuery)
    }

    // 음식 정보 테이블 생성
    private func createFoodInfoTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS food_info (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            english_name TEXT,
            korean_name TEXT,
            calories INTEGER
        );
        """

        executeQuery(createTableQuery)
    }

    // 음식 칼로리 테이블 생성
    private func createFoodCaloriesTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS food_calories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            english_name TEXT,
            eaten_date TEXT,
            calories INTEGER
        );
        """

        executeQuery(createTableQuery)
    }

    // 쿼리 실행을 위한 함수
    private func executeQuery(_ query: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("쿼리 실행 성공: \(query)")
            } else {
                print("쿼리 실행 실패: \(query)")
            }
        } else {
            print("쿼리 준비 실패: \(query)")
        }
        sqlite3_finalize(statement)
    }

    // 데이터베이스 닫기 함수
    func closeDatabase() {
        if sqlite3_close(db) == SQLITE_OK {
            print("데이터베이스 닫기 성공")
        } else {
            print("데이터베이스 닫기 실패")
        }
    }
    
    //기본 재료 리스트 만들기
    func insertFoodInfo(englishName: String, koreanName: String, calories: Int) {
        let insertQuery = "INSERT INTO food_info (english_name, korean_name, calories) VALUES (?, ?, ?);"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, englishName, -1, nil)
            sqlite3_bind_text(statement, 2, koreanName, -1, nil)
            sqlite3_bind_int(statement, 3, Int32(calories))

            if sqlite3_step(statement) == SQLITE_DONE {
                //print("데이터 삽입 성공: \(englishName)")
                print("데이터 삽입 성공 - 영어 이름: \(englishName), 한글 이름: \(koreanName), 칼로리: \(calories)kcal")
            } else {
                print("데이터 삽입 실패: \(englishName)")
            }
        } else {
            print("삽입 준비 실패")
        }
        sqlite3_finalize(statement)
    }
    func insertDefaultFood() {
        let defaultFoods = [
            ("Baked Potato", "베이크드 포테이토", 161),
            ("Crispy Chicken", "크리스피 치킨", 246),
            ("Donut", "도넛", 195),
            ("Fries", "감자튀김", 312),
            ("Hot Dog", "핫도그", 151),
            ("Sandwich", "샌드위치", 250),
            ("Taco", "타코", 226),
            ("Taquito", "타키토", 190),
            ("apple_pie", "애플파이", 296),
            ("burger", "버거", 354),
            ("butter_naan", "버터난", 292),
            ("chai", "차", 120),
            ("chapati", "차파티", 120),
            ("cheesecake", "치즈케이크", 257),
            ("chicken_curry", "치킨커리", 243),
            ("chole_bhature", "촐레 바투레", 427),
            ("dal_makhani", "달 마카니", 350),
            ("dhokla", "도클라", 162),
            ("fried_rice", "볶음밥", 250),
            ("ice_cream", "아이스크림", 137),
            ("idli", "이들리", 58),
            ("jalebi", "잘레비", 150),
            ("kaathi_rolls", "커티 롤스", 200),
            ("kadai_paneer", "카다이 파니르", 260),
            ("kulfi", "쿨피", 120),
            ("masala_dosa", "마살라 도사", 168),
            ("momos", "모모", 35),
            ("omelette", "오믈렛", 154),
            ("paani_puri", "파니 푸리", 200),
            ("pakode", "파코데", 170),
            ("pav_bhaji", "파브 바지", 400),
            ("pizza", "피자", 285),
            ("samosa", "사모사", 252),
            ("sushi", "스시", 200)
        ]
        for food in defaultFoods {
            insertFoodInfo(englishName: food.0, koreanName: food.1, calories: food.2)
        }
    }
    //사용자 재료 리스트 추가
    func insertFoodsToList(englishName: String, koreanName: String, calories: String) {
        print("삽입하려는 데이터 확인 - englishName: \(englishName), calculatedShelfLife: \(calories)")

        let insertQuery = "INSERT INTO food_calories (english_name, korean_Name, calories) VALUES (?, ?, ?)"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, englishName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, koreanName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, calories, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                print("데이터 삽입 성공")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("데이터 삽입 실패: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("삽입 쿼리 준비 실패: \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }
    
    //기본 재료 리스트 만들기
    func insertIngredientInfo(englishName: String, koreanName: String, shelfLife: Int) {
        let insertQuery = "INSERT INTO ingredient_info (english_name, korean_name, shelf_life) VALUES (?, ?, ?);"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, englishName, -1, nil)
            sqlite3_bind_text(statement, 2, koreanName, -1, nil)
            sqlite3_bind_int(statement, 3, Int32(shelfLife))

            if sqlite3_step(statement) == SQLITE_DONE {
                //print("데이터 삽입 성공: \(englishName)")
                print("데이터 삽입 성공 - 영어 이름: \(englishName), 한글 이름: \(koreanName), 유통기한: \(shelfLife)일")
            } else {
                print("데이터 삽입 실패: \(englishName)")
            }
        } else {
            print("삽입 준비 실패")
        }
        sqlite3_finalize(statement)
    }
    func insertDefaultIngredients() {
        let defaultIngredients = [
            ("apple", "사과", 7),
            ("banana", "바나나", 5),
            ("beetroot", "비트", 14),
            ("bell pepper", "피망", 7),
            ("cabbage", "양배추", 21),
            ("capsicum", "고추", 7),
            ("carrot", "당근", 21),
            ("cauliflower", "콜리플라워", 7),
            ("chilli pepper", "고추", 7),
            ("corn", "옥수수", 5),
            ("cucumber", "오이", 7),
            ("eggplant", "가지", 4),
            ("garlic", "마늘", 180),
            ("ginger", "생강", 30),
            ("grapes", "포도", 7),
            ("jalepeno", "할라페뇨", 7),
            ("kiwi", "키위", 7),
            ("lemon", "레몬", 21),
            ("lettuce", "상추", 7),
            ("mango", "망고", 5),
            ("onion", "양파", 60),
            ("orange", "오렌지", 21),
            ("paprika", "파프리카", 7),
            ("pear", "배", 7),
            ("peas", "완두콩", 5),
            ("pineapple", "파인애플", 5),
            ("pomegranate", "석류", 14),
            ("potato", "감자", 90),
            ("raddish", "무", 14),
            ("soy beans", "콩", 7),
            ("spinach", "시금치", 5),
            ("sweetcorn", "단옥수수", 3),
            ("sweetpotato", "고구마", 30),
            ("tomato", "토마토", 7),
            ("turnip", "순무", 14),
            ("watermelon", "수박", 7)
        ]
        for ingredient in defaultIngredients {
            insertIngredientInfo(englishName: ingredient.0, koreanName: ingredient.1, shelfLife: ingredient.2)
        }
    }
    //사용자 재료 리스트 추가
    func insertIngredientToList(englishName: String, koreanName: String, calculatedShelfLife: String) {
        print("삽입하려는 데이터 확인 - englishName: \(englishName), calculatedShelfLife: \(calculatedShelfLife)")

        let insertQuery = "INSERT INTO ingredient_list (english_name, korean_Name, calculated_shelf_life) VALUES (?, ?, ?)"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        if sqlite3_prepare_v2(db, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, englishName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, koreanName, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, calculatedShelfLife, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_DONE {
                print("데이터 삽입 성공")
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("데이터 삽입 실패: \(errorMessage)")
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("삽입 쿼리 준비 실패: \(errorMessage)")
        }
        sqlite3_finalize(statement)
    }
    
    func deleteDatabase() {
        guard let dbPath = getDatabasePath() else { return }
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: dbPath)
            print("데이터베이스 파일 삭제 성공: \(dbPath)")
        } catch {
            print("데이터베이스 파일 삭제 실패: \(error)")
        }
    }
    
    func fetchIngredientsForRecommendation() -> [String] {
        guard let db = SQLiteManager.shared.db else {
            print("데이터베이스 연결 실패")
            return []
        }

        let query = "SELECT english_name FROM ingredient_list"
        var statement: OpaquePointer?
        var ingredients: [String] = []
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let englishName = sqlite3_column_text(statement, 0).flatMap({ String(cString: $0) }) {
                    ingredients.append(englishName)
                }
            }
        } else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            print("쿼리 준비 실패: \(errorMessage)")
        }
        sqlite3_finalize(statement)
        return ingredients
    }
}

struct IngredientInfo: Identifiable {
    var id: UUID
    var englishName: String
    var koreanName: String
    var shelfLife: Int
}

struct Ingredient: Identifiable {
    var id: Int
    var koreanName: String
    var calculatedShelfLife: String
}

struct IngredientList: Identifiable {
    var id: UUID
    var koreanName: String
    var calculatedShelfLife: String
}

struct FoodInfo: Identifiable {
    var id: UUID
    var englishName: String
    var koreanName: String
    var calories: Int
}

struct FoodCalories: Identifiable {
    var id: UUID
    var englishName: String
    var koreanName: String
    var calories: Int
    var eatenDate: String
}



