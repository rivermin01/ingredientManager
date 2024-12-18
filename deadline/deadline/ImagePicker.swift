import SwiftUI // SwiftUI 프레임워크 가져오기
import UIKit // UIKit 프레임워크 가져오기

struct ImagePicker: UIViewControllerRepresentable { // SwiftUI에서 UIKit의 UIImagePickerController를 사용하기 위한 구조체 정의
    @Binding var image: UIImage? // 선택된 이미지를 저장하기 위한 바인딩 변수
    @Binding var showPreview: Bool // 미리보기 상태를 제어하기 위한 바인딩 변수
    var sourceType: UIImagePickerController.SourceType // 소스 타입(카메라 또는 앨범)을 설정하기 위한 변수

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate { // UIImagePickerController의 델리게이트를 처리하기 위한 Coordinator 클래스
        var parent: ImagePicker // 상위 ImagePicker 구조체에 대한 참조

        init(parent: ImagePicker) { // 초기화 메서드
            self.parent = parent // 상위 ImagePicker 참조를 초기화
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) { // 이미지 선택이 완료되었을 때 호출되는 메서드
            picker.dismiss(animated: true) // 이미지 선택 컨트롤러를 닫기

            if let userPickedImage = info[.editedImage] as? UIImage { // 선택된 편집된 이미지가 있으면
                parent.image = userPickedImage // 상위 구조체의 이미지 변수에 저장

                // 이미지가 선택되었으므로 미리보기 화면으로 전환
                DispatchQueue.main.async { [self] in
                    parent.showPreview = true // 미리보기 화면 표시 상태 업데이트
                }
            } else {
                print("IP 이미지 선택 실패") // 이미지 선택 실패 로그 출력
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { // 이미지 선택이 취소되었을 때 호출되는 메서드
            picker.dismiss(animated: true) // 이미지 선택 컨트롤러를 닫기
        }
    }

    @EnvironmentObject var ingredientData: IngredientData // 환경 객체로 재료 데이터 접근

    func makeCoordinator() -> Coordinator { // Coordinator 생성 메서드
        Coordinator(parent: self) // Coordinator 인스턴스를 생성하여 반환
    }

    func makeUIViewController(context: Context) -> UIImagePickerController { // UIImagePickerController를 생성하는 메서드
        let picker = UIImagePickerController() // UIImagePickerController 인스턴스 생성
        picker.delegate = context.coordinator // 델리게이트 설정
        picker.allowsEditing = true // 이미지 편집 허용 설정
        picker.sourceType = sourceType // 소스 타입 설정 (카메라 또는 앨범)
        return picker // 설정된 UIImagePickerController 반환
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { // UIViewController 업데이트 메서드
        // 추가 업데이트 필요 없음
    }
}
