import Foundation

class GeminiAPI {
    static let shared = GeminiAPI()

    private let apiKey = "" // 활성화된 API 키 사용
    private let apiUrl = "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent"

    func fetchRecommendations(using ingredients: [String], completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: "\(apiUrl)?key=\(apiKey)") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "잘못된 URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 요청 바디: Gemini가 요구하는 JSON 형식
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "다음 식재료로 만들 수 있는 음식을 5개만 추천해 주는데 형식대로 대답해줘 (형식: ** 음식1 **\n ** 음식2 **\n ** 음식3 **\n ** 음식4 **\n ** 음식5 **) 식재료 : \(ingredients.joined(separator: ", "))"]
                    ]
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("네트워크 오류: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let response = response as? HTTPURLResponse {
                print("HTTP 응답 코드: \(response.statusCode)")
            }

            guard let data = data else {
                print("서버로부터 받은 데이터 없음")
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "데이터 없음"])))
                return
            }

            print("서버 응답 데이터: \(String(data: data, encoding: .utf8) ?? "디코딩 실패")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    print("서버에서 받은 전체 JSON 응답: \(json)") // 전체 JSON 구조 출력

                    // JSON 파싱 로직 수정
                    if let candidates = json["candidates"] as? [[String: Any]],
                       let content = candidates.first?["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let text = parts.first?["text"] as? String {

                        let recipes = text.components(separatedBy: "\n").filter { !$0.isEmpty }
                        completion(.success(recipes))
                    } else {
                        print("JSON 구조 파싱 오류")
                        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON 구조가 예상과 다름"])))
                    }
                } else {
                    print("JSON 전체 응답 변환 실패")
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "JSON 변환 실패"])))
                }
            } catch {
                print("JSON 파싱 오류: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
