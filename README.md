# Flutter Fitness App — Bài Tập Lớn

## Câu 3: BmiRecord — Đối tượng chính

File: `lib/view/fontend/bmi_view.dart`

### Biến:
- `height` — chiều cao (cm)
- `weight` — cân nặng (kg)
- `age` — tuổi
- `gender` — giới tính
- `activityLevel` — hệ số vận động
- `bmiValue` — chỉ số BMI
- `tdee` — tổng năng lượng tiêu thụ mỗi ngày (kcal)
- `bmiStatus` — phân loại BMI (Underweight / Normal / Overweight / Obese)

### Phương thức:
- `calculateBmi()` — tính BMI từ cân nặng và chiều cao
- `calculateBmr()` — tính BMR theo công thức Mifflin-St Jeor
- `calculateTdee()` — tính TDEE = BMR × activityLevel
- `getBmiStatus()` — phân loại BMI dựa trên giá trị tính được

---

## Câu 4: CRUD cho BmiRecord

Trong bài, danh sách `BmiRecord` không được lưu local trong RAM mà lưu thẳng lên **Firebase Firestore**.

- **`_buildHistoryCard(record)`** — hàm này truy vấn dữ liệu từ Firebase và in ra lịch sử các bản ghi.

**Cơ chế Update hiện tại:** Người dùng nhập lại input → nhấn *Calculate & Save* → tạo bản ghi mới lưu vào Firestore.

Đây là thiết kế hợp lý cho ứng dụng health tracking: mỗi lần đo là một bản ghi mới, không ghi đè lịch sử cũ.
