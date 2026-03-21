## 1. Mục tiêu
Xây dựng hệ thống gợi ý để hỗ trợ 2 bài toán:
- Gợi ý chiến dịch phù hợp cho tình nguyện viên
- Gợi ý tình nguyện viên phù hợp cho người tạo chiến dịch

**Kết quả mong muốn**

Hệ thống không chỉ trả về danh sách, mà phải hỗ trợ ra quyết định:
- biết ai hoặc chiến dịch nào phù hợp nhất
- biết vì sao phù hợp
- biết ai nên mời trước, ai có thể cân nhắc thêm, ai chưa phù hợp

## 2. Nguyên tắc cốt lõi
- Chỉ có 1 logic đánh giá duy nhất cho cặp `tình_nguyện_viên <-> chiến_dịch`
- Cùng 1 cặp dữ liệu thì kết quả phải giống nhau ở mọi màn hình
- Gợi ý phải minh bạch: có điểm tổng, điểm từng tiêu chí, lý do, cảnh báo
- Điều phối là bước sắp xếp lại kết quả gợi ý, không phải một logic riêng

## 3. Dữ liệu đầu vào cần sử dụng
- Hồ sơ tình nguyện viên: kỹ năng, khu vực, lịch rảnh, vị trí, lịch sử tham gia, đánh giá
- Chỉ xét các tài khoản có vai trò `tình_nguyện_viên`, đã xác thực email; khi điều phối mặc định chỉ lấy tài khoản đang hoạt động
- Thông tin chiến dịch: kỹ năng yêu cầu, loại chiến dịch, thời gian, địa điểm, mức độ ưu tiên, số lượng cần
- Trạng thái tham gia hiện tại: chờ xác nhận, đã xác nhận, đang tham gia, đã hoàn thành, đã hủy

## 4. Logic đánh giá phù hợp
Mỗi cặp `TNV - Chiến dịch` được chấm theo 6 nhóm:
- Khoảng cách
- Kỹ năng
- Lịch rảnh
- Mức độ ưu tiên hoặc độ phù hợp bối cảnh
- Độ tin cậy từ lịch sử tham gia
- Kinh nghiệm và chứng chỉ

**Trọng số ưu tiên**

- Khoảng cách là yếu tố quan trọng nhất
- Sau đó đến kỹ năng
- Sau đó đến lịch rảnh
- Các yếu tố còn lại đóng vai trò bổ trợ

**Quy tắc chấm điểm**

- `Khoảng cách` được tính theo km giữa vị trí TNV và địa điểm chiến dịch
- Nếu khoảng cách `<= 3 km`: chấm `100%`
- Nếu khoảng cách `> 3 km` đến `10 km`: giảm tuyến tính từ `100%` xuống `70%`
- Nếu khoảng cách `> 10 km` đến `20 km`: giảm tuyến tính từ `70%` xuống `40%`
- Nếu khoảng cách `> 20 km`: chấm `10%`
- Nếu thiếu dữ liệu tọa độ của một trong hai bên: chấm `0%`

- `Kỹ năng` được tính theo số kỹ năng chiến dịch yêu cầu và số kỹ năng TNV đang có
- Nếu chiến dịch không yêu cầu kỹ năng cụ thể: chấm `50%`
- Nếu TNV không có kỹ năng nào: chấm `0%`
- Nếu chiến dịch có `N` kỹ năng và TNV khớp `M` kỹ năng thì điểm kỹ năng không chỉ là `M / N`, mà được tính theo công thức:
  `Điểm kỹ năng = ((độ phủ kỹ năng * 0.7) + (Cosine Similarity * 0.3)) * 100`
- Trong đó:
  - `độ phủ kỹ năng = M / N`
  - `Cosine Similarity = M / sqrt(tổng kỹ năng TNV * tổng kỹ năng chiến dịch)`
- Ví dụ chiến dịch cần `5` kỹ năng, TNV có `6` kỹ năng và khớp `3` kỹ năng:
  - độ phủ = `3 / 5 = 60%`
  - cosine = `3 / sqrt(6 * 5) = 54.77%`
  - điểm kỹ năng = `(0.6 * 0.7 + 0.5477 * 0.3) * 100 = 58.43%`
- Nếu không khớp kỹ năng nào thì chấm `0%`
- Nếu chiến dịch có kỹ năng nhưng TNV khớp dưới mức tối thiểu thì không được đưa vào nhóm đủ điều kiện

- `Lịch rảnh` được tính theo số ngày chiến dịch diễn ra và số ngày TNV có thể tham gia
- Nếu chiến dịch kéo dài từ ngày A đến ngày B thì phải xác định rõ từng ngày trong khoảng đó rơi vào thứ mấy
- Điểm lịch rảnh = `số ngày khớp / tổng số ngày của chiến dịch`
- Ví dụ chiến dịch diễn ra `5` ngày, TNV rảnh `3` ngày trong số đó thì điểm lịch rảnh = `60%`
- Nếu không khớp ngày nào thì chấm `0%`

- `Mức độ ưu tiên hoặc độ phù hợp bối cảnh` là điểm cộng bổ trợ
- Chiến dịch khẩn cấp hoặc đúng lĩnh vực TNV từng tham gia nhiều lần thì được cộng nhẹ
- Phần này không được lấn át khoảng cách, kỹ năng và lịch rảnh

- `Độ tin cậy` được tính từ lịch sử tham gia
- TNV từng xác nhận, tham gia đầy đủ, được đánh giá tốt thì điểm cao hơn
- TNV từng hủy nhiều hoặc ít tham gia thực tế thì điểm thấp hơn

- `Kinh nghiệm và chứng chỉ` phản ánh độ dày của hồ sơ năng lực
- Số `kinh nghiệm` được chuẩn hóa tối đa theo mốc `5` bản ghi
- Số `chứng chỉ` được chuẩn hóa tối đa theo mốc `3` bản ghi
- Công thức:
  `Điểm kinh nghiệm & chứng chỉ = ((kinh_nghiệm_chuẩn_hóa * 0.7) + (chứng_chỉ_chuẩn_hóa * 0.3)) * 100`
- Trong đó:
  - `kinh_nghiệm_chuẩn_hóa = min(số kinh nghiệm, 5) / 5`
  - `chứng_chỉ_chuẩn_hóa = min(số chứng chỉ, 3) / 3`
- Ví dụ TNV có `3` kinh nghiệm và `2` chứng chỉ:
  - kinh nghiệm chuẩn hóa = `3 / 5 = 60%`
  - chứng chỉ chuẩn hóa = `2 / 3 = 66.67%`
  - điểm kinh nghiệm & chứng chỉ = `(0.6 * 0.7 + 0.6667 * 0.3) * 100 = 62%`

**Điểm phù hợp cuối cùng**

- `Khoảng cách`: `30%`
- `Kỹ năng`: `30%`
- `Lịch rảnh`: `20%`
- `Mức độ ưu tiên hoặc độ phù hợp bối cảnh`: `5%`
- `Độ tin cậy`: `5%`
- `Kinh nghiệm và chứng chỉ`: `10%`

Công thức tính điểm cuối:

`Điểm phù hợp cuối = (Khoảng cách × 0.30) + (Kỹ năng × 0.30) + (Lịch rảnh × 0.20) + (Bối cảnh × 0.05) + (Độ tin cậy × 0.05) + (Kinh nghiệm & chứng chỉ × 0.10)`

Ví dụ:
- Khoảng cách: `80`
- Kỹ năng: `60`
- Lịch rảnh: `100`
- Bối cảnh: `40`
- Độ tin cậy: `70`
- Kinh nghiệm & chứng chỉ: `62`

Khi đó:

`Điểm phù hợp cuối = 80 × 0.30 + 60 × 0.30 + 100 × 0.20 + 40 × 0.05 + 70 × 0.05 + 62 × 0.10 = 73.7%`

Phần trăm hiển thị trên giao diện là điểm cuối này, thường được làm tròn để hiển thị ngắn gọn.

**Quy tắc nghiệp vụ bắt buộc**

- Chiến dịch đã xóa, chưa duyệt, hết hạn đăng ký, đã kết thúc, đủ người thì không được gợi ý
- Tình nguyện viên là người tạo chiến dịch thì không được gợi ý chiến dịch đó
- Tình nguyện viên chưa xác thực email thì không được đưa vào gợi ý hoặc điều phối
- Nếu trùng lịch nghiêm trọng với chiến dịch khác thì không được đưa vào nhóm có thể mời ngay
- Nếu chiến dịch có kỹ năng, TNV phải có mức độ khớp tối thiểu mới được đưa vào gợi ý
- Nếu lịch rảnh không giao với thời gian chiến dịch thì không được đưa vào gợi ý

**Khi nhìn từ phía người tạo chiến dịch**

Kết quả gợi ý tình nguyện viên phải chia thành 3 nhóm:
- `Tình nguyện viên đề xuất`: các TNV đạt điều kiện gợi ý và có điểm phù hợp từ `50%` đến dưới `80%`
- `Nhóm nên mời trước`: các TNV đạt điều kiện gợi ý và có điểm phù hợp từ `80%` trở lên
- `Nhóm chưa phù hợp hoặc cần bổ sung trước khi mời`: các TNV dưới `50%` hoặc bị loại do không đạt điều kiện tối thiểu

**Điều kiện để được tính là đạt điều kiện gợi ý**

- có ít nhất `1 kỹ năng khớp` nếu chiến dịch có yêu cầu kỹ năng
- tỷ lệ khớp kỹ năng đạt mức tối thiểu theo chiến dịch
- có ngày rảnh giao với thời gian chiến dịch
- không bị trùng lịch nghiêm trọng với chiến dịch khác
- chưa ở trạng thái `đã xác nhận`, `đang tham gia` hoặc `đã hoàn thành` với chính chiến dịch đó

**Quy tắc hiển thị theo nhóm**

- `Tình nguyện viên đề xuất` là nhóm có thể cân nhắc mời nếu cần thêm người, nhưng chưa phải nhóm ưu tiên cao nhất
- `Nhóm nên mời trước` là nhóm ưu tiên hành động đầu tiên, được dùng để gửi thư mời ngay
- `Nhóm chưa phù hợp` vẫn phải hiển thị để người tạo chiến dịch biết vì sao chưa mời được và cần bổ sung điều gì
- TNV đã ở nhóm nào thì chỉ xuất hiện đúng `1 lần` trong toàn bộ màn hình
- TNV đã ở `Nhóm nên mời trước` thì không lặp lại ở danh sách đề xuất tổng
- TNV `chờ xác nhận` vẫn cần hiển thị để theo dõi
- TNV `đã xác nhận`, `đang tham gia`, `đã hoàn thành` thì không đưa vào các nhóm gợi ý nữa

## 5. Gợi ý chiến dịch cho tình nguyện viên
Mục tiêu là hiển thị các chiến dịch phù hợp nhất với người dùng đang đăng nhập.

**Kết quả cần**

- xếp theo mức độ phù hợp tổng thể giảm dần
- nếu bằng điểm thì chiến dịch gần hơn đứng trước
- lấy top 6 chiến dịch phù hợp nhất
- chiến dịch được hiển thị nếu:
  - đạt điều kiện gợi ý, hoặc
  - có điểm phù hợp từ `50%` trở lên
- không hiển thị nếu rơi vào các trường hợp loại cứng như:
  - không khớp kỹ năng nào
  - không khớp lịch rảnh
  - bị loại bởi bộ lọc `gần tôi`

**Thông tin cần hiển thị trên card**

- phù hợp bao nhiêu phần trăm
- kỹ năng khớp ra sao
- lịch rảnh khớp ra sao
- cách chiến dịch bao xa

## 6. Điều phối nhân sự
Từ kết quả gợi ý tình nguyện viên, hệ thống phải đề xuất phương án điều phối:
- mời ai trước để đạt số lượng tối thiểu
- theo dõi những người đã mời nhưng đang ở trạng thái `chờ xác nhận`
- cảnh báo chiến dịch đang thiếu nguồn lực

**Cảnh báo cần có**

- thiếu ứng viên phù hợp so với mức tối thiểu
- nhiều ứng viên ở xa
- nhiều ứng viên chỉ khớp lịch một phần

## 7. So sánh giữa TNV và chiến dịch
Tại màn danh sách chiến dịch và màn điều phối, người dùng phải có thể bấm `So sánh`.

**Modal so sánh cần hiển thị rõ dạng bảng**

- Kỹ năng chiến dịch
- Kỹ năng tình nguyện viên
- Kỹ năng khớp
- Kỹ năng chưa có
- Thời gian chiến dịch, kèm thứ trong tuần
- Ngày khớp
- Ngày chưa khớp
- Địa điểm chiến dịch
- Vị trí hoặc khu vực của TNV
- Khoảng cách cụ thể giữa 2 bên
- Phần trăm khớp từng tiêu chí và phần trăm tổng thể

## 8. Yêu cầu UX
- Danh sách hiển thị gọn, dễ quét nhanh
- Chi tiết mới đưa vào modal
- Câu chữ trong UI phải viết theo ngôn ngữ người dùng, không theo ngôn ngữ dev
- Không hiển thị các từ mơ hồ như `hard constraint`, `qualification failed`
- Người dùng phải hiểu được tại sao một người nên mời trước, đang ở mức đề xuất, hay chưa phù hợp

## 9. Mục tiêu hoàn thiện
Sau khi hoàn thiện, hệ thống phải đảm bảo:
- kết quả gợi ý 2 chiều là nhất quán
- điều phối dùng được trong vận hành thật
- người dùng nhìn vào biết nên làm gì tiếp theo
- logic đủ chặt để không chỉ dùng cho demo

## 10. Thuật toán hoặc công nghệ sử dụng trong chức năng
- Hệ gợi ý sử dụng hướng tiếp cận `Content-Based Filtering`, tức là so khớp trực tiếp giữa hồ sơ tình nguyện viên và thông tin chiến dịch.
- Độ phù hợp về kỹ năng được tính bằng cách biểu diễn tập kỹ năng của hai bên thành đặc trưng và so sánh bằng `Cosine Similarity`.
- Độ phù hợp về vị trí được tính bằng `công thức Haversine` để xác định khoảng cách thực tế giữa vị trí tình nguyện viên và địa điểm chiến dịch.
- Độ phù hợp về thời gian được tính dựa trên phần giao nhau giữa lịch rảnh của tình nguyện viên và khoảng thời gian diễn ra chiến dịch.
- Điểm phù hợp cuối cùng được tạo từ mô hình `chấm điểm có trọng số`, trong đó khoảng cách, kỹ năng và lịch rảnh là các yếu tố chính.
- Chức năng điều phối sử dụng kết quả gợi ý này để chia ứng viên thành các nhóm `nên mời trước`, `đề xuất` và `chưa phù hợp`, theo hướng hỗ trợ ra quyết định minh bạch.
- Hệ thống thuộc nhóm `White-box Decision Support`, nghĩa là kết quả gợi ý phải giải thích được bằng phần trăm phù hợp, lý do khớp, lý do chưa khớp và các cảnh báo liên quan.
