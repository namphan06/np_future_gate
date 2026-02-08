# NP FutureGate - Sơ Đồ Use Case

> **Ngày tạo:** 2026-01-21  
> **Phiên bản:** 1.0.0  
> **Ghi chú:** Sử dụng Mermaid syntax để vẽ sơ đồ. Có thể xem trực tiếp trên GitHub hoặc VSCode với extension Mermaid.

---

## 📋 MỤC LỤC

1. [Sơ Đồ Use Case Cấp 0 - Tổng Quan Hệ Thống](#1-sơ-đồ-use-case-cấp-0---tổng-quan-hệ-thống)
2. [Sơ Đồ Use Case Cấp 1 - Theo Actor](#2-sơ-đồ-use-case-cấp-1---theo-actor)
3. [Sơ Đồ Use Case Cấp 2 - Chi Tiết Chức Năng](#3-sơ-đồ-use-case-cấp-2---chi-tiết-chức-năng)
4. [Mô Tả Chi Tiết Các Use Case](#4-mô-tả-chi-tiết-các-use-case)

---

## 1. SƠ ĐỒ USE CASE CẤP 0 - TỔNG QUAN HỆ THỐNG

### 1.1 Context Diagram - Hệ thống NP FutureGate

```mermaid
flowchart TB
    subgraph External["Hệ Thống Bên Ngoài"]
        SUPABASE[(Supabase\nDatabase)]
        FIREBASE[(Firebase\nFCM)]
        GOOGLE[Google\nAuth]
    end
    
    subgraph System["🎯 HỆ THỐNG NP FUTUREGATE"]
        CORE[Ứng Dụng\nTuyển Dụng]
    end
    
    subgraph Actors["Người Dùng"]
        CANDIDATE[👤 Ứng Viên\nCandidate]
        EMPLOYER[🏢 Nhà Tuyển Dụng\nEmployer]
        SCHOOL[🏫 Nhà Trường\nSchool]
        ADMIN[👨‍💼 Quản Trị Viên\nAdmin]
    end
    
    CANDIDATE --> CORE
    EMPLOYER --> CORE
    SCHOOL --> CORE
    ADMIN --> CORE
    
    CORE <--> SUPABASE
    CORE <--> FIREBASE
    CORE <--> GOOGLE
```

### 1.2 Use Case Cấp 0 - Tổng Quan

```mermaid
flowchart LR
    subgraph actors[" "]
        C[👤 Candidate]
        E[🏢 Employer]
        S[🏫 School]
        A[👨‍💼 Admin]
    end
    
    subgraph system["🎯 NP FUTUREGATE SYSTEM"]
        UC1[🔐 Quản lý\nTài Khoản]
        UC2[💼 Quản lý\nViệc Làm]
        UC3[📄 Quản lý\nỨng Tuyển]
        UC4[📅 Quản lý\nPhỏng Vấn]
        UC5[💬 Hệ Thống\nChat]
        UC6[🔔 Hệ Thống\nThông Báo]
        UC7[🤝 Quản lý\nPartnership]
        UC8[⚙️ Quản Trị\nHệ Thống]
    end
    
    C --> UC1
    C --> UC2
    C --> UC3
    C --> UC4
    C --> UC5
    C --> UC6
    
    E --> UC1
    E --> UC2
    E --> UC3
    E --> UC4
    E --> UC5
    E --> UC6
    
    S --> UC1
    S --> UC5
    S --> UC6
    S --> UC7
    
    A --> UC1
    A --> UC6
    A --> UC8
```

---

## 2. SƠ ĐỒ USE CASE CẤP 1 - THEO ACTOR

### 2.1 Use Case - CANDIDATE (Ứng Viên)

```mermaid
flowchart LR
    subgraph candidate["👤 CANDIDATE"]
        C((Ứng Viên))
    end
    
    subgraph system["NP FUTUREGATE - CANDIDATE MODULE"]
        subgraph auth["🔐 Xác Thực"]
            UC_C01[UC-C01\nĐăng ký tài khoản]
            UC_C02[UC-C02\nĐăng nhập]
            UC_C03[UC-C03\nĐăng nhập Google]
            UC_C04[UC-C04\nQuên mật khẩu]
        end
        
        subgraph job["💼 Việc Làm"]
            UC_C05[UC-C05\nTìm kiếm việc làm]
            UC_C06[UC-C06\nXem chi tiết việc]
            UC_C07[UC-C07\nLưu việc làm]
            UC_C08[UC-C08\nỨng tuyển việc]
        end
        
        subgraph cv["📄 CV"]
            UC_C09[UC-C09\nUpload CV]
            UC_C10[UC-C10\nQuản lý CV]
            UC_C11[UC-C11\nXem CV]
        end
        
        subgraph company["🏢 Công Ty"]
            UC_C12[UC-C12\nXem danh sách công ty]
            UC_C13[UC-C13\nXem chi tiết công ty]
            UC_C14[UC-C14\nTheo dõi công ty]
        end
        
        subgraph comm["💬 Giao Tiếp"]
            UC_C15[UC-C15\nChat với NTD]
            UC_C16[UC-C16\nXem thông báo]
        end
        
        subgraph profile["👤 Hồ Sơ"]
            UC_C17[UC-C17\nCập nhật profile]
            UC_C18[UC-C18\nXem lịch phỏng vấn]
            UC_C19[UC-C19\nXem việc đã ứng tuyển]
        end
    end
    
    C --> UC_C01
    C --> UC_C02
    C --> UC_C03
    C --> UC_C04
    C --> UC_C05
    C --> UC_C06
    C --> UC_C07
    C --> UC_C08
    C --> UC_C09
    C --> UC_C10
    C --> UC_C11
    C --> UC_C12
    C --> UC_C13
    C --> UC_C14
    C --> UC_C15
    C --> UC_C16
    C --> UC_C17
    C --> UC_C18
    C --> UC_C19
```

### 2.2 Use Case - EMPLOYER (Nhà Tuyển Dụng)

```mermaid
flowchart LR
    subgraph employer["🏢 EMPLOYER"]
        E((Nhà Tuyển Dụng))
    end
    
    subgraph system["NP FUTUREGATE - EMPLOYER MODULE"]
        subgraph auth["🔐 Xác Thực"]
            UC_E01[UC-E01\nĐăng ký/Đăng nhập]
        end
        
        subgraph job["💼 Quản Lý Tin"]
            UC_E02[UC-E02\nĐăng tin tuyển dụng]
            UC_E03[UC-E03\nChỉnh sửa tin]
            UC_E04[UC-E04\nXóa tin]
            UC_E05[UC-E05\nXem danh sách tin]
        end
        
        subgraph applicant["👥 Quản Lý Ứng Viên"]
            UC_E06[UC-E06\nXem ứng viên theo job]
            UC_E07[UC-E07\nDuyệt ứng viên]
            UC_E08[UC-E08\nTừ chối ứng viên]
            UC_E09[UC-E09\nTìm kiếm ứng viên]
            UC_E10[UC-E10\nLưu ứng viên]
        end
        
        subgraph interview["📅 Phỏng Vấn"]
            UC_E11[UC-E11\nTạo lịch phỏng vấn]
            UC_E12[UC-E12\nXem lịch phỏng vấn]
            UC_E13[UC-E13\nĐánh giá ứng viên]
        end
        
        subgraph partnership["🤝 Partnership"]
            UC_E14[UC-E14\nXem yêu cầu từ trường]
            UC_E15[UC-E15\nDuyệt partnership job]
        end
        
        subgraph comm["💬 Giao Tiếp"]
            UC_E16[UC-E16\nChat với ứng viên]
            UC_E17[UC-E17\nXem thông báo]
        end
        
        subgraph profile["🏢 Hồ Sơ Công Ty"]
            UC_E18[UC-E18\nCập nhật hồ sơ công ty]
            UC_E19[UC-E19\nXem thống kê]
        end
    end
    
    E --> UC_E01
    E --> UC_E02
    E --> UC_E03
    E --> UC_E04
    E --> UC_E05
    E --> UC_E06
    E --> UC_E07
    E --> UC_E08
    E --> UC_E09
    E --> UC_E10
    E --> UC_E11
    E --> UC_E12
    E --> UC_E13
    E --> UC_E14
    E --> UC_E15
    E --> UC_E16
    E --> UC_E17
    E --> UC_E18
    E --> UC_E19
```

### 2.3 Use Case - SCHOOL (Nhà Trường)

```mermaid
flowchart LR
    subgraph school["🏫 SCHOOL"]
        S((Nhà Trường))
    end
    
    subgraph system["NP FUTUREGATE - SCHOOL MODULE"]
        subgraph auth["🔐 Xác Thực"]
            UC_S01[UC-S01\nĐăng ký/Đăng nhập]
        end
        
        subgraph partnership["🤝 Partnership"]
            UC_S02[UC-S02\nTạo partnership job]
            UC_S03[UC-S03\nChọn công ty đối tác]
            UC_S04[UC-S04\nTheo dõi trạng thái duyệt]
            UC_S05[UC-S05\nXem danh sách partnership]
        end
        
        subgraph company["🏢 Công Ty"]
            UC_S06[UC-S06\nTìm công ty đối tác]
            UC_S07[UC-S07\nXem chi tiết công ty]
        end
        
        subgraph config["⚙️ Cấu Hình"]
            UC_S08[UC-S08\nCấu hình email trường]
            UC_S09[UC-S09\nCập nhật hồ sơ trường]
        end
        
        subgraph comm["💬 Giao Tiếp"]
            UC_S10[UC-S10\nXem thông báo]
        end
    end
    
    S --> UC_S01
    S --> UC_S02
    S --> UC_S03
    S --> UC_S04
    S --> UC_S05
    S --> UC_S06
    S --> UC_S07
    S --> UC_S08
    S --> UC_S09
    S --> UC_S10
```

### 2.4 Use Case - ADMIN (Quản Trị Viên)

```mermaid
flowchart LR
    subgraph admin["👨‍💼 ADMIN"]
        A((Quản Trị Viên))
    end
    
    subgraph system["NP FUTUREGATE - ADMIN MODULE"]
        subgraph auth["🔐 Xác Thực"]
            UC_A01[UC-A01\nĐăng nhập Admin]
        end
        
        subgraph dashboard["📊 Dashboard"]
            UC_A02[UC-A02\nXem thống kê tổng quan]
            UC_A03[UC-A03\nXem báo cáo]
        end
        
        subgraph user["👥 Quản Lý User"]
            UC_A04[UC-A04\nXem danh sách user]
            UC_A05[UC-A05\nXem chi tiết user]
            UC_A06[UC-A06\nKhóa/Mở khóa user]
            UC_A07[UC-A07\nXóa user]
        end
        
        subgraph job["💼 Duyệt Tin"]
            UC_A08[UC-A08\nXem tin chờ duyệt]
            UC_A09[UC-A09\nDuyệt tin tuyển dụng]
            UC_A10[UC-A10\nTừ chối tin]
        end
        
        subgraph partnership["🤝 Partnership"]
            UC_A11[UC-A11\nXem partnership chờ duyệt]
            UC_A12[UC-A12\nDuyệt partnership job]
        end
        
        subgraph notification["🔔 Thông Báo"]
            UC_A13[UC-A13\nGửi thông báo toàn hệ thống]
            UC_A14[UC-A14\nGửi thông báo theo role]
        end
        
        subgraph content["📝 Nội Dung"]
            UC_A15[UC-A15\nQuản lý tin tức]
            UC_A16[UC-A16\nQuản lý khóa học]
        end
    end
    
    A --> UC_A01
    A --> UC_A02
    A --> UC_A03
    A --> UC_A04
    A --> UC_A05
    A --> UC_A06
    A --> UC_A07
    A --> UC_A08
    A --> UC_A09
    A --> UC_A10
    A --> UC_A11
    A --> UC_A12
    A --> UC_A13
    A --> UC_A14
    A --> UC_A15
    A --> UC_A16
```

---

## 3. SƠ ĐỒ USE CASE CẤP 2 - CHI TIẾT CHỨC NĂNG

### 3.1 Chi Tiết: Quản Lý Việc Làm (Job Management)

```mermaid
flowchart TB
    subgraph actors["Actors"]
        C((👤 Candidate))
        E((🏢 Employer))
        A((👨‍💼 Admin))
    end
    
    subgraph system["MODULE: QUẢN LÝ VIỆC LÀM"]
        subgraph create["Tạo Tin"]
            UC1[Đăng tin tuyển dụng]
            UC1a[Nhập thông tin cơ bản]
            UC1b[Nhập yêu cầu công việc]
            UC1c[Nhập mức lương]
            UC1d[Nhập phúc lợi]
            UC1e[Chọn deadline]
        end
        
        subgraph manage["Quản Lý Tin"]
            UC2[Chỉnh sửa tin]
            UC3[Xóa tin]
            UC4[Đóng/Mở tin]
        end
        
        subgraph view["Xem Tin"]
            UC5[Tìm kiếm việc làm]
            UC5a[Lọc theo vị trí]
            UC5b[Lọc theo lĩnh vực]
            UC5c[Lọc theo mức lương]
            UC5d[Lọc theo kinh nghiệm]
            UC6[Xem chi tiết việc]
            UC7[Lưu việc làm]
        end
        
        subgraph approve["Duyệt Tin"]
            UC8[Xem tin chờ duyệt]
            UC9[Duyệt tin]
            UC10[Từ chối tin]
        end
    end
    
    E --> UC1
    UC1 -.->|include| UC1a
    UC1 -.->|include| UC1b
    UC1 -.->|include| UC1c
    UC1 -.->|extend| UC1d
    UC1 -.->|extend| UC1e
    
    E --> UC2
    E --> UC3
    E --> UC4
    
    C --> UC5
    UC5 -.->|extend| UC5a
    UC5 -.->|extend| UC5b
    UC5 -.->|extend| UC5c
    UC5 -.->|extend| UC5d
    
    C --> UC6
    C --> UC7
    
    A --> UC8
    A --> UC9
    A --> UC10
```

### 3.2 Chi Tiết: Quy Trình Ứng Tuyển (Application Process)

```mermaid
flowchart TB
    subgraph actors["Actors"]
        C((👤 Candidate))
        E((🏢 Employer))
    end
    
    subgraph system["MODULE: QUY TRÌNH ỨNG TUYỂN"]
        subgraph apply["Ứng Tuyển"]
            UC1[Xem chi tiết việc làm]
            UC2[Chọn CV ứng tuyển]
            UC2a[Upload CV mới]
            UC3[Xác nhận ứng tuyển]
            UC4[Nhận thông báo]
        end
        
        subgraph review["Xem Xét Hồ Sơ"]
            UC5[Xem danh sách ứng viên]
            UC6[Xem CV ứng viên]
            UC7[Xem profile ứng viên]
        end
        
        subgraph decision["Ra Quyết Định"]
            UC8[Chấp nhận ứng viên]
            UC8a[Tạo lịch phỏng vấn]
            UC9[Từ chối ứng viên]
            UC9a[Gửi lý do từ chối]
        end
        
        subgraph track["Theo Dõi"]
            UC10[Xem việc đã ứng tuyển]
            UC11[Xem trạng thái đơn]
        end
    end
    
    C --> UC1
    UC1 --> UC2
    UC2 -.->|extend| UC2a
    UC2 --> UC3
    UC3 --> UC4
    
    E --> UC5
    E --> UC6
    E --> UC7
    
    E --> UC8
    UC8 -.->|extend| UC8a
    E --> UC9
    UC9 -.->|extend| UC9a
    
    C --> UC10
    C --> UC11
```

### 3.3 Chi Tiết: Quy Trình Phỏng Vấn (Interview Process)

```mermaid
flowchart TB
    subgraph actors["Actors"]
        C((👤 Candidate))
        E((🏢 Employer))
    end
    
    subgraph system["MODULE: QUY TRÌNH PHỎNG VẤN"]
        subgraph schedule["Lên Lịch"]
            UC1[Chọn ứng viên]
            UC2[Chọn thời gian phỏng vấn]
            UC2a[Kiểm tra xung đột lịch]
            UC3[Tạo lịch phỏng vấn]
            UC4[Gửi thông báo cho UV]
        end
        
        subgraph view["Xem Lịch"]
            UC5[Xem lịch phỏng vấn - Employer]
            UC6[Xem lịch phỏng vấn - Candidate]
            UC7[Xem chi tiết buổi PV]
        end
        
        subgraph manage["Quản Lý"]
            UC8[Hủy lịch phỏng vấn]
            UC9[Đổi lịch phỏng vấn]
        end
        
        subgraph evaluate["Đánh Giá"]
            UC10[Đánh giá sau phỏng vấn]
            UC10a[Nhập điểm đánh giá]
            UC10b[Nhập nhận xét]
            UC11[Cập nhật kết quả]
            UC11a[Chấp nhận]
            UC11b[Từ chối]
        end
    end
    
    E --> UC1
    UC1 --> UC2
    UC2 -.->|include| UC2a
    UC2 --> UC3
    UC3 --> UC4
    
    E --> UC5
    C --> UC6
    E --> UC7
    C --> UC7
    
    E --> UC8
    E --> UC9
    
    E --> UC10
    UC10 -.->|include| UC10a
    UC10 -.->|extend| UC10b
    UC10 --> UC11
    UC11 -.->|extend| UC11a
    UC11 -.->|extend| UC11b
```

### 3.4 Chi Tiết: Partnership Job (Hợp Tác Trường - Doanh Nghiệp)

```mermaid
flowchart TB
    subgraph actors["Actors"]
        S((🏫 School))
        E((🏢 Employer))
        A((👨‍💼 Admin))
    end
    
    subgraph system["MODULE: PARTNERSHIP JOB"]
        subgraph create["Tạo Partnership"]
            UC1[Tìm công ty đối tác]
            UC2[Chọn công ty]
            UC3[Nhập thông tin job]
            UC4[Gửi yêu cầu partnership]
        end
        
        subgraph companyReview["Công Ty Duyệt"]
            UC5[Nhận thông báo yêu cầu]
            UC6[Xem chi tiết yêu cầu]
            UC7[Chấp nhận yêu cầu]
            UC8[Từ chối yêu cầu]
            UC8a[Nhập lý do từ chối]
        end
        
        subgraph adminReview["Admin Duyệt"]
            UC9[Xem partnership chờ duyệt]
            UC10[Duyệt partnership job]
            UC11[Từ chối partnership job]
        end
        
        subgraph track["Theo Dõi"]
            UC12[Xem trạng thái duyệt]
            UC13[Xem danh sách partnership]
        end
    end
    
    S --> UC1
    UC1 --> UC2
    UC2 --> UC3
    UC3 --> UC4
    
    E --> UC5
    E --> UC6
    E --> UC7
    E --> UC8
    UC8 -.->|extend| UC8a
    
    A --> UC9
    A --> UC10
    A --> UC11
    
    S --> UC12
    S --> UC13
```

### 3.5 Chi Tiết: Hệ Thống Chat

```mermaid
flowchart TB
    subgraph actors["Actors"]
        C((👤 Candidate))
        E((🏢 Employer))
    end
    
    subgraph system["MODULE: HỆ THỐNG CHAT"]
        subgraph conversation["Quản Lý Cuộc Trò Chuyện"]
            UC1[Xem danh sách chat]
            UC2[Tạo cuộc trò chuyện mới]
            UC3[Xóa cuộc trò chuyện]
        end
        
        subgraph message["Tin Nhắn"]
            UC4[Gửi tin nhắn text]
            UC5[Gửi file đính kèm]
            UC6[Xem lịch sử chat]
        end
        
        subgraph status["Trạng Thái"]
            UC7[Đánh dấu đã đọc]
            UC8[Xem số tin chưa đọc]
        end
        
        subgraph realtime["Realtime"]
            UC9[Nhận tin nhắn realtime]
            UC10[Cập nhật trạng thái online]
        end
    end
    
    C --> UC1
    C --> UC2
    C --> UC3
    C --> UC4
    C --> UC5
    C --> UC6
    C --> UC7
    C --> UC8
    C --> UC9
    C --> UC10
    
    E --> UC1
    E --> UC2
    E --> UC3
    E --> UC4
    E --> UC5
    E --> UC6
    E --> UC7
    E --> UC8
    E --> UC9
    E --> UC10
```

### 3.6 Chi Tiết: Quản Lý CV

```mermaid
flowchart TB
    subgraph actors["Actors"]
        C((👤 Candidate))
    end
    
    subgraph system["MODULE: QUẢN LÝ CV"]
        subgraph upload["Upload CV"]
            UC1[Chọn file CV]
            UC1a[Hỗ trợ PDF]
            UC1b[Hỗ trợ DOC/DOCX]
            UC2[Upload lên Storage]
            UC3[Đặt tên CV]
        end
        
        subgraph manage["Quản Lý"]
            UC4[Xem danh sách CV]
            UC5[Xem chi tiết CV]
            UC5a[Xem PDF trong app]
            UC6[Xóa CV]
            UC7[Tải CV về máy]
        end
        
        subgraph use["Sử Dụng"]
            UC8[Chọn CV khi ứng tuyển]
            UC9[Đặt CV mặc định]
        end
    end
    
    C --> UC1
    UC1 -.->|extend| UC1a
    UC1 -.->|extend| UC1b
    UC1 --> UC2
    UC2 --> UC3
    
    C --> UC4
    C --> UC5
    UC5 -.->|include| UC5a
    C --> UC6
    C --> UC7
    
    C --> UC8
    C --> UC9
```

---

## 4. MÔ TẢ CHI TIẾT CÁC USE CASE

### 4.1 CANDIDATE USE CASES

#### UC-C08: Ứng Tuyển Việc Làm

| Thuộc tính | Mô tả |
|------------|-------|
| **Tên Use Case** | Ứng tuyển việc làm |
| **Mã** | UC-C08 |
| **Actor** | Candidate |
| **Mô tả** | Ứng viên gửi đơn ứng tuyển vào một công việc |
| **Tiền điều kiện** | - Đã đăng nhập<br>- Có ít nhất 1 CV<br>- Chưa ứng tuyển job này |
| **Hậu điều kiện** | - Đơn ứng tuyển được ghi nhận<br>- NTD nhận thông báo |
| **Luồng chính** | 1. UV xem chi tiết job<br>2. UV nhấn "Ứng tuyển"<br>3. Hệ thống hiển thị danh sách CV<br>4. UV chọn CV<br>5. UV xác nhận ứng tuyển<br>6. Hệ thống ghi nhận & gửi thông báo |
| **Luồng thay thế** | 3a. Nếu chưa có CV → Chuyển đến Upload CV |
| **Ngoại lệ** | - Đã ứng tuyển trước đó<br>- Job đã đóng<br>- Lỗi kết nối |

#### UC-C05: Tìm Kiếm Việc Làm

| Thuộc tính | Mô tả |
|------------|-------|
| **Tên Use Case** | Tìm kiếm việc làm |
| **Mã** | UC-C05 |
| **Actor** | Candidate |
| **Mô tả** | Tìm kiếm và lọc các công việc phù hợp |
| **Tiền điều kiện** | Đã đăng nhập |
| **Hậu điều kiện** | Hiển thị danh sách job matching |
| **Luồng chính** | 1. UV vào trang tìm kiếm<br>2. UV nhập từ khóa/chọn bộ lọc<br>3. Hệ thống filter jobs<br>4. Hiển thị kết quả |
| **Bộ lọc** | - Vị trí (63 tỉnh/thành)<br>- Lĩnh vực (22 ngành)<br>- Mức lương<br>- Kinh nghiệm<br>- Loại hình công việc |

---

### 4.2 EMPLOYER USE CASES

#### UC-E02: Đăng Tin Tuyển Dụng

| Thuộc tính | Mô tả |
|------------|-------|
| **Tên Use Case** | Đăng tin tuyển dụng |
| **Mã** | UC-E02 |
| **Actor** | Employer |
| **Mô tả** | NTD tạo tin tuyển dụng mới |
| **Tiền điều kiện** | - Đã đăng nhập<br>- Role = employer |
| **Hậu điều kiện** | - Job được tạo (status=pending)<br>- Admin nhận thông báo |
| **Luồng chính** | 1. NTD vào màn hình tạo tin<br>2. Nhập thông tin cơ bản (tiêu đề, mô tả)<br>3. Chọn vị trí, lĩnh vực<br>4. Nhập yêu cầu ứng viên<br>5. Nhập mức lương<br>6. Nhập phúc lợi<br>7. Chọn deadline (optional)<br>8. Submit<br>9. Hệ thống lưu & gửi thông báo Admin |
| **Validation** | - Tiêu đề: bắt buộc, max 200 ký tự<br>- Mô tả: bắt buộc<br>- Ít nhất 1 vị trí<br>- Ít nhất 1 lĩnh vực |

#### UC-E11: Tạo Lịch Phỏng Vấn

| Thuộc tính | Mô tả |
|------------|-------|
| **Tên Use Case** | Tạo lịch phỏng vấn |
| **Mã** | UC-E11 |
| **Actor** | Employer |
| **Mô tả** | NTD đặt lịch phỏng vấn với ứng viên |
| **Tiền điều kiện** | - Có ứng viên accepted<br>- Không xung đột lịch |
| **Hậu điều kiện** | - Lịch PV được tạo<br>- UV nhận thông báo |
| **Luồng chính** | 1. NTD chọn UV từ danh sách<br>2. NTD chọn ngày giờ<br>3. Hệ thống check xung đột<br>4. Nếu OK → Tạo lịch<br>5. Gửi thông báo cho UV |
| **Luồng thay thế** | 3a. Nếu xung đột → Thông báo, yêu cầu chọn lại |

---

### 4.3 SCHOOL USE CASES

#### UC-S02: Tạo Partnership Job

| Thuộc tính | Mô tả |
|------------|-------|
| **Tên Use Case** | Tạo Partnership Job |
| **Mã** | UC-S02 |
| **Actor** | School |
| **Mô tả** | Trường tạo tin tuyển dụng cho công ty đối tác |
| **Tiền điều kiện** | - Đã đăng nhập<br>- Role = school |
| **Hậu điều kiện** | - Partnership job được tạo<br>- Công ty nhận thông báo |
| **Luồng chính** | 1. Trường tìm & chọn công ty<br>2. Nhập thông tin job (giống employer)<br>3. Submit<br>4. Hệ thống lưu (company_status=pending)<br>5. Gửi thông báo cho công ty |
| **Quy trình duyệt** | Trường tạo → Công ty duyệt → Admin duyệt → Xuất bản |

---

### 4.4 ADMIN USE CASES

#### UC-A09: Duyệt Tin Tuyển Dụng

| Thuộc tính | Mô tả |
|------------|-------|
| **Tên Use Case** | Duyệt tin tuyển dụng |
| **Mã** | UC-A09 |
| **Actor** | Admin |
| **Mô tả** | Admin phê duyệt tin tuyển dụng |
| **Tiền điều kiện** | - Role = admin<br>- Có tin chờ duyệt |
| **Hậu điều kiện** | - Job status = approved/rejected<br>- NTD nhận thông báo |
| **Luồng chính** | 1. Admin xem danh sách pending jobs<br>2. Chọn job để review<br>3. Xem chi tiết<br>4. Approve/Reject<br>5. Gửi thông báo cho NTD |
| **Tiêu chí duyệt** | - Nội dung hợp lệ<br>- Không spam<br>- Không vi phạm |

---

## 5. BẢNG TỔNG HỢP QUAN HỆ USE CASE

### 5.1 Quan hệ Include (Bắt buộc)

| Use Case Chính | Include | Mô tả |
|----------------|---------|-------|
| Ứng tuyển việc | Chọn CV | Phải chọn CV để ứng tuyển |
| Tạo lịch PV | Check xung đột lịch | Phải kiểm tra trước khi tạo |
| Xem chi tiết CV | Render PDF | Hiển thị nội dung PDF |

### 5.2 Quan hệ Extend (Tùy chọn)

| Use Case Chính | Extend | Điều kiện |
|----------------|--------|-----------|
| Ứng tuyển việc | Upload CV mới | Nếu chưa có CV |
| Tìm kiếm việc | Lọc theo vị trí | User muốn lọc thêm |
| Từ chối ứng viên | Gửi lý do | NTD muốn gửi lý do |
| Đăng tin | Chọn deadline | NTD muốn set deadline |

### 5.3 Quan hệ Generalization (Kế thừa)

| Use Case Tổng Quát | Use Case Cụ Thể |
|--------------------|-----------------|
| Đăng nhập | Đăng nhập Email, Đăng nhập Google |
| Duyệt tin | Duyệt tin thường, Duyệt partnership |
| Gửi thông báo | Gửi cho user, Gửi cho role, Gửi toàn hệ thống |

---

## 6. DIAGRAM LEGEND

```
Ký hiệu trong sơ đồ:

○ ──────→  : Actor sử dụng Use Case
┅┅┅┅┅┅→    : Include (bao gồm bắt buộc)
- - - - →  : Extend (mở rộng tùy chọn)
△          : Generalization (kế thừa)

Màu sắc:
🟢 Xanh lá : Candidate
🟠 Cam     : Employer  
🟣 Tím     : School
🔴 Đỏ     : Admin
```

---

## 7. TỔNG KẾT SỐ LƯỢNG USE CASE

| Actor | Số Use Case Cấp 1 | Số Use Case Cấp 2 |
|-------|-------------------|-------------------|
| Candidate | 19 | 35+ |
| Employer | 19 | 40+ |
| School | 10 | 20+ |
| Admin | 16 | 30+ |
| **Tổng** | **64** | **125+** |

---

*Cập nhật lần cuối: 2026-01-21*

*Công cụ vẽ sơ đồ: Mermaid.js - Tương thích GitHub, VSCode, Notion*
