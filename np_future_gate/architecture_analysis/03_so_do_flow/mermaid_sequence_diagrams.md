# Sequence Diagrams - Luong Chinh Cua He Thong

## Muc dich

Tai lieu nay chua cac **sequence diagrams** duoc viet bang cu phap Mermaid, mo ta chi tiet luong tuong tac giua cac thanh phan trong he thong NP FutureGate. Cac so do bao gom 4 luong chinh:

1. **Authentication** - Xac thuc nguoi dung (Email va Google Sign-In)
2. **AI Matching** - Phan tich CV va matching voi cong viec
3. **Notification** - Gui va nhan thong bao push (FCM)
4. **Payment** - Thanh toan qua PayOS

---

## 1. Luong Xac Thuc (Authentication Flow)

### 1.1 Dang nhap bang Email/Password

```mermaid
sequenceDiagram
    autonumber
    participant U as Nguoi dung
    participant LS as LoginScreen
    participant AR as AuthRepository
    participant SA as Supabase Auth
    participant DB as Supabase Database
    participant FCM as FCMService

    Note over U,FCM: Luong dang nhap bang email va mat khau

    U->>LS: Nhap email va password
    LS->>LS: Validate form (email hop le, password >= 6 ky tu)
    LS->>AR: signInWithEmail(email, password)
    AR->>SA: signInWithPassword(email, password)

    alt Dang nhap thanh cong
        SA-->>AR: AuthResponse (user != null)
        AR->>DB: SELECT FROM profiles WHERE id = user.id
        
        alt Tai khoan bi vo hieu hoa
            DB-->>AR: profile.isActive == false
            AR->>SA: signOut()
            AR-->>LS: AuthResult.failure("Tai khoan bi ngung hoat dong")
            LS-->>U: Hien thi thong bao loi
        else Tai khoan hoat dong
            DB-->>AR: Profile (role, fullName, isActive=true)
            AR-->>LS: AuthResult.success()
            LS->>FCM: Lay FCM token
            FCM-->>LS: fcmToken
            LS->>AR: saveDeviceToken(fcmToken, userId, role)
            AR->>DB: UPSERT device_tokens
            LS->>LS: Dieu huong theo role (candidate/employer/school/admin)
            LS-->>U: Chuyen den HomeScreen tuong ung
        end
    else Dang nhap that bai
        SA-->>AR: AuthException (sai email/password)
        AR-->>LS: AuthResult.failure(message tieng Viet)
        LS-->>U: Hien thi SnackBar loi
    end
```

### 1.2 Dang nhap bang Google Sign-In

```mermaid
sequenceDiagram
    autonumber
    participant U as Nguoi dung
    participant LS as LoginScreen
    participant AR as AuthRepository
    participant GS as Google Sign-In
    participant SA as Supabase Auth
    participant DB as Supabase Database
    participant FCM as FCMService

    Note over U,FCM: Luong dang nhap voi tai khoan Google (OAuth)

    U->>LS: Nhan nut "Dang nhap voi Google"
    LS->>AR: signInWithGoogle()
    AR->>GS: signOut() - Reset session cu
    AR->>GS: signIn() - Hien thi Google Account Picker
    U->>GS: Chon tai khoan Google

    alt Nguoi dung huy chon
        GS-->>AR: null
        AR-->>LS: AuthResult.failure("Dang nhap Google bi huy")
        LS-->>U: Hien thi thong bao loi
    else Nguoi dung chon tai khoan
        GS-->>AR: GoogleSignInAccount
        AR->>GS: Lay authentication tokens
        GS-->>AR: accessToken + idToken

        Note over AR,SA: Gui tokens den Supabase de xac thuc

        AR->>SA: signInWithIdToken(provider: google, idToken, accessToken)

        alt Xac thuc thanh cong
            SA-->>AR: AuthResponse (user)
            AR->>DB: SELECT FROM profiles WHERE id = user.id

            alt Tai khoan bi vo hieu hoa
                DB-->>AR: profile.isActive == false
                AR->>SA: signOut()
                AR->>GS: signOut()
                AR-->>LS: AuthResult.failure("Tai khoan bi ngung")
            else Tai khoan hoat dong
                DB-->>AR: Profile data
                AR-->>LS: AuthResult.success()
                LS->>FCM: Lay FCM token
                FCM-->>LS: fcmToken
                LS->>AR: saveDeviceToken(fcmToken, userId, role)
                LS-->>U: Chuyen den HomeScreen theo role
            end
        else Xac thuc that bai
            SA-->>AR: AuthException
            AR-->>LS: AuthResult.failure(message)
            LS-->>U: Hien thi SnackBar loi
        end
    end
```

### 1.3 Dang ky tai khoan moi

```mermaid
sequenceDiagram
    autonumber
    participant U as Nguoi dung
    participant RS as RegisterScreen
    participant AR as AuthRepository
    participant SA as Supabase Auth
    participant DB as Supabase Database

    Note over U,DB: Luong dang ky tai khoan moi voi lua chon vai tro

    U->>RS: Chon vai tro (Candidate/Employer/School)
    U->>RS: Nhap thong tin (ho ten, email, SDT, mat khau)
    RS->>RS: Validate form (email, SDT >= 10 ky tu, password >= 6)
    RS->>AR: signUpWithEmail(email, password, fullName, phone, role)
    AR->>SA: signUp(email, password, data: metadata)

    alt Dang ky thanh cong
        SA-->>AR: AuthResponse (user created)
        AR->>DB: INSERT INTO profiles (id, email, full_name, phone, role, is_active: false)
        DB-->>AR: Profile created

        alt Can xac thuc email
            AR-->>RS: AuthResult.success("Kiem tra email de xac thuc")
            RS-->>U: Thong bao kiem tra hop thu email
        else Email da xac thuc (Google linked)
            AR-->>RS: AuthResult.success("Dang ky thanh cong!")
            RS-->>U: Chuyen den HomeScreen theo role da chon
        end
    else Dang ky that bai
        SA-->>AR: AuthException (email da ton tai, v.v.)
        AR-->>RS: AuthResult.failure(message tieng Viet)
        RS-->>U: Hien thi SnackBar loi
    end
```

### 1.4 Dang xuat

```mermaid
sequenceDiagram
    autonumber
    participant U as Nguoi dung
    participant App as Ung dung
    participant AR as AuthRepository
    participant DTR as DeviceTokenRepository
    participant SA as Supabase Auth
    participant GS as Google Sign-In
    participant DB as Supabase Database

    Note over U,DB: Luong dang xuat va don dep session

    U->>App: Nhan nut Dang xuat
    App->>AR: signOut(deviceToken)

    alt Co device token
        AR->>DTR: removeDeviceToken(token, userId)
        DTR->>DB: DELETE FROM device_tokens WHERE device_id = token
        DB-->>DTR: Deleted
        DTR-->>AR: Done
    end

    AR->>SA: signOut()
    SA-->>AR: Session cleared
    AR->>GS: signOut()
    GS-->>AR: Google session cleared
    AR-->>App: AuthResult.success("Dang xuat thanh cong!")
    App-->>U: Chuyen ve LoginScreen
```

---

## 2. Luong AI Matching (Phan Tich CV)

### 2.1 Phan tich CV Upload (File PDF/Anh qua OCR)

```mermaid
sequenceDiagram
    autonumber
    participant NTD as Nha tuyen dung
    participant UI as CVAnalysisScreen
    participant AMS as AIMatchingService
    participant OCR as MLKitOcrService
    participant MS as MistralService
    participant API as Mistral AI API

    Note over NTD,API: Luong phan tich CV dang file (PDF/anh) su dung OCR + AI

    NTD->>UI: Xem phan tich CV ung vien
    UI->>AMS: analyzeCVMatching(cvData, job)

    Note over AMS: Phat hien type = "upload" va co file_url

    AMS->>OCR: extractTextFromUrl(fileUrl)

    alt File la PDF
        OCR->>OCR: Render tung trang thanh anh (3x resolution)
        OCR->>OCR: TextRecognizer xu ly tung trang
        OCR-->>AMS: MLKitOcrResult (combined text)
    else File la anh
        OCR->>OCR: InputImage.fromFile -> TextRecognizer
        OCR-->>AMS: MLKitOcrResult (extracted text)
    end

    AMS->>AMS: Tao prompt phan tich (CV text + Job requirements)

    Note over AMS,API: Gui prompt den Mistral AI de danh gia

    AMS->>MS: sendIsolatedMessage(prompt)
    MS->>API: POST /chat/completions (temperature: 0.1, json_object mode)
    API-->>MS: JSON response (score, matching_points, missing_points)
    MS-->>AMS: Raw JSON string
    AMS->>AMS: Parse JSON + sanitize response
    AMS-->>UI: CVMatchingResult (overall_score 0-100)
    UI-->>NTD: Hien thi diem phu hop + chi tiet diem manh/yeu
```

### 2.2 Phan tich CV Structured (CV tao trong app)

```mermaid
sequenceDiagram
    autonumber
    participant UV as Ung vien
    participant UI as CVSelectionScreen
    participant AMS as AIMatchingService
    participant MS as MistralService
    participant API as Mistral AI API

    Note over UV,API: Luong phan tich CV duoc tao truc tiep trong ung dung

    UV->>UI: Chon CV de ung tuyen vao cong viec
    UI->>AMS: analyzeCVMatching(cvData, job)

    Note over AMS: Phat hien type != "upload" -> Luong Structured

    AMS->>AMS: _buildStructuredText(cvData)

    Note over AMS: Trich xuat: personal_info, experiences,<br/>education, skills, certifications, projects

    alt Text < 30 ky tu (CV qua ngan)
        AMS-->>UI: CVMatchingResult.fromMock(score=5)
        UI-->>UV: Hien thi diem thap - CV chua du thong tin
    else Text du dai
        AMS->>AMS: _buildAnalysisPrompt(cvText, job)
        AMS->>MS: sendIsolatedMessage(prompt)
        MS->>API: POST /chat/completions
        API-->>MS: JSON response
        MS-->>AMS: Parsed result
        AMS-->>UI: CVMatchingResult (score, matching/missing points)
        UI-->>UV: Hien thi diem matching va goi y cai thien
    end
```

### 2.3 So sanh nhieu ung vien (CV Comparison)

```mermaid
sequenceDiagram
    autonumber
    participant NTD as Nha tuyen dung
    participant UI as JobApplicantsScreen
    participant AMS as AIMatchingService
    participant OCR as MLKitOcrService
    participant MS as MistralService
    participant API as Mistral AI API

    Note over NTD,API: Luong so sanh nhieu ung vien cho 1 vi tri

    NTD->>UI: Chon nhieu ung vien de so sanh
    UI->>AMS: compareCVsStructured(cvsData, names, job)

    loop Moi CV ung vien
        AMS->>AMS: Kiem tra type (upload/structured)
        alt Upload CV
            AMS->>OCR: extractTextFromUrl(url)
            OCR-->>AMS: OCR text
        else Structured CV
            AMS->>AMS: _buildStructuredText(data)
        end
    end

    Note over AMS: Tao prompt so sanh voi 5 tieu chi:<br/>skills, experience, education, overall, potential

    AMS->>MS: sendIsolatedMessage(comparison prompt)
    MS->>API: POST /chat/completions
    API-->>MS: JSON comparison result
    MS-->>AMS: Parsed JSON

    AMS->>AMS: CVComparisonResult.fromJson(result)
    AMS-->>UI: CVComparisonResult (candidates ranked)
    UI-->>NTD: Bang so sanh + xep hang ung vien theo diem
```

### 2.4 Chatbot AI voi Intent-Based Queries

```mermaid
sequenceDiagram
    autonumber
    participant U as Nguoi dung
    participant UI as ChatbotScreen
    participant EAS as EnhancedAIService
    participant AIS as AIIntentService
    participant ADR as AIDataRepository
    participant MS as MistralService
    participant SB as Supabase
    participant API as Mistral AI

    Note over U,API: Luong chatbot AI thong minh voi kha nang truy van du lieu

    U->>UI: Nhap cau hoi (text hoac giong noi)

    alt Su dung Speech-to-Text
        UI->>UI: SpeechToText.listen(localeId: vi_VN)
        UI->>UI: Chuyen giong noi thanh text
    end

    UI->>EAS: processUserQuery(query, userId, userRole)

    Note over EAS,AIS: Buoc 1: Phan tich y dinh nguoi dung (Intent Detection)

    EAS->>AIS: analyzeUserQuery(query, userRole)
    AIS->>AIS: Loc intents theo role nguoi dung
    AIS->>AIS: Tinh diem match (keywords + patterns)
    AIS->>AIS: Trich xuat parameters (thoi gian, trang thai)
    AIS-->>EAS: IntentAnalysisResult (confidence, intent, params)

    alt confidence >= 0.6 (Data Query - Truy van du lieu)
        Note over EAS,SB: Buoc 2: Lay du lieu thuc tu Supabase

        EAS->>ADR: fetchDataByIntent(intent, params, userId)
        ADR->>SB: Query theo intent (applications, jobs, interviews...)
        SB-->>ADR: List data results
        ADR-->>EAS: Data tu database

        Note over EAS,API: Buoc 3: AI format response voi du lieu thuc

        EAS->>MS: sendMessage(data + format prompt)
        MS->>API: POST /chat/completions (with conversation history)
        API-->>MS: Formatted response bang tieng Viet
        MS-->>EAS: AI message

        EAS-->>UI: AIResponseWithData(message, chartType, data)
        UI-->>U: Hien thi text + Data UI (list/card/table/chart)

    else confidence < 0.6 (General Chat - Hoi dap chung)
        Note over EAS,API: Chat thong thuong khong can data

        EAS->>MS: sendMessage(query)
        MS->>API: POST /chat/completions (with history)
        API-->>MS: AI response
        MS-->>EAS: Message text

        EAS-->>UI: AIResponseWithData(message, null, null)
        UI-->>U: Hien thi cau tra loi text
    end
```

---

## 3. Luong Thong Bao (Notification Flow)

### 3.1 Gui Push Notification (Server-side)

```mermaid
sequenceDiagram
    autonumber
    participant App as Ung dung (Su kien kich hoat)
    participant SNS as StatusNotificationService
    participant NR as NotificationRepository
    participant DTR as DeviceTokenRepository
    participant DB as Supabase Database
    participant PNS as PushNotificationService
    participant FCM as FCM V1 API
    participant Device as Thiet bi nguoi nhan

    Note over App,Device: Luong gui thong bao khi co su kien (ung tuyen, phong van, duyet tin...)

    App->>SNS: notifyNewApplication() / notifyInterviewScheduled()

    Note over SNS,DB: Buoc 1: Luu notification vao database

    SNS->>NR: createNotificationToUser(userId, title, content, actionCode, actionData)
    NR->>DB: INSERT INTO notifications (recipient_ids, title, content, action_code, action_data)
    DB-->>NR: NotificationModel created
    NR-->>SNS: Notification da luu

    Note over SNS,DTR: Buoc 2: Lay danh sach device tokens cua nguoi nhan

    SNS->>DTR: getActiveDeviceIds(userId, role)
    DTR->>DB: SELECT device_id FROM device_tokens WHERE user_id AND is_active=true
    DB-->>DTR: List deviceIds
    DTR-->>SNS: Danh sach device tokens

    Note over SNS,Device: Buoc 3: Gui push notification qua FCM V1 API

    SNS->>PNS: sendNotificationToMultipleDevices(deviceTokens, title, body, data)

    loop Moi device token
        PNS->>PNS: _getAccessToken() - OAuth2 Service Account
        PNS->>FCM: POST /v1/projects/npfuturegate/messages:send
        Note over FCM: Headers: Authorization Bearer token<br/>Body: message with notification + data payload
        FCM-->>PNS: 200 OK - Message sent
    end

    PNS-->>SNS: Ket qua gui (success/failure)
    FCM->>Device: Push Notification den thiet bi
```

### 3.2 Nhan va xu ly Notification tren Client

```mermaid
sequenceDiagram
    autonumber
    participant FCM as Firebase Server
    participant App as FCMService (Client)
    participant LN as Local Notifications
    participant Nav as NotificationNavigationSetup
    participant Handler as Action Handler
    participant Screen as Man hinh dich

    Note over FCM,Screen: Xu ly notification o 3 trang thai ung dung

    rect rgb(220, 240, 255)
        Note over FCM,Screen: TRANG THAI FOREGROUND (App dang mo)
        FCM->>App: onMessage (RemoteMessage)
        App->>LN: _showLocalNotification(title, body, payload)
        LN-->>App: Hien thi notification banner tren man hinh
    end

    rect rgb(255, 240, 220)
        Note over FCM,Screen: TRANG THAI BACKGROUND (App chay nen)
        FCM->>App: onMessageOpenedApp (RemoteMessage)
        App->>App: Parse data thanh NotificationModel
    end

    rect rgb(240, 255, 220)
        Note over FCM,Screen: TRANG THAI TERMINATED (App da dong)
        App->>App: checkInitialMessage()
        App->>FCM: getInitialMessage()
        FCM-->>App: RemoteMessage (neu co)
        App->>App: Parse data thanh NotificationModel
    end

    Note over App,Screen: Xu ly khi nguoi dung tap vao notification

    App->>Nav: handleNotificationTap(context, notification)
    Nav->>Nav: Danh dau da doc (markAsRead)
    Nav->>Nav: Lay config tu actionCode

    alt showDialog = true
        Nav-->>App: Hien thi AlertDialog thong bao
    else requiresNavigation = true
        Nav->>Handler: Navigate theo actionCode
        
        alt applicationReceived
            Handler->>Screen: Push JobApplicantsScreen
        else applicationApproved/Rejected
            Handler->>Screen: Push JobDetailScreen
        else interviewScheduled
            Handler->>Screen: Push InterviewDetailScreen
        else newMessage
            Handler->>Screen: Push ChatScreen
        end
    end
```

### 3.3 Khoi tao FCM Service

```mermaid
sequenceDiagram
    autonumber
    participant Main as main.dart
    participant FCM as FCMService
    participant FBM as FirebaseMessaging
    participant LN as Local Notifications
    participant DTR as DeviceTokenRepository
    participant DB as Supabase

    Note over Main,DB: Khoi tao he thong notification khi app khoi dong

    Main->>FCM: initialize()

    Note over FCM,LN: Buoc 1: Khoi tao Local Notifications plugin

    FCM->>LN: initialize(androidSettings, iosSettings)
    LN-->>FCM: Plugin initialized

    Note over FCM,FBM: Buoc 2: Xin quyen notification (iOS)

    FCM->>FBM: requestPermission(alert, badge, sound)
    FBM-->>FCM: AuthorizationStatus.authorized

    Note over FCM,FBM: Buoc 3: Lay FCM Token

    FCM->>FBM: getToken()
    FBM-->>FCM: fcmToken (device identifier)

    Note over FCM,DB: Buoc 4: Luu token vao database

    FCM->>DTR: saveDeviceToken(token, userId, role)
    DTR->>DB: UPSERT device_tokens (device_id, user_id, role, is_active)
    DB-->>DTR: Token saved

    Note over FCM,FBM: Buoc 5: Dang ky cac listeners

    FCM->>FBM: onMessage.listen(_handleForegroundMessage)
    FCM->>FBM: onMessageOpenedApp.listen(_handleMessageOpenedApp)
    FCM->>FBM: onBackgroundMessage(_backgroundHandler)
    FCM->>FBM: onTokenRefresh.listen(autoUpdateToken)
    FBM-->>FCM: Listeners registered
```

---

## 4. Luong Thanh Toan (Payment Flow - PayOS)

### 4.1 Tao yeu cau thanh toan va hien thi QR

```mermaid
sequenceDiagram
    autonumber
    participant NTD as Nha tuyen dung
    participant UI as UpgradeAccountScreen
    participant POS as PayOSService
    participant API as PayOS API
    participant QR as QR Payment Dialog

    Note over NTD,QR: Luong tao link thanh toan va hien thi ma QR

    NTD->>UI: Chon goi nang cap (Co ban/Thuong/VIP)
    UI->>POS: createPaymentLink(amount, planName, userId)

    Note over POS: Kiem tra credentials (clientId, apiKey, checksumKey)

    alt Credentials rong hoac chua cau hinh
        POS-->>UI: PaymentResult(success: false, error: "Chua cau hinh PayOS")
        UI-->>NTD: Hien thi thong bao loi cau hinh
    else Credentials hop le
        Note over POS: Tao orderCode = timestamp % MAX_SAFE_INT
        Note over POS: Tao description (ASCII, max 25 ky tu)
        Note over POS: Tao signature HMAC-SHA256<br/>Data: amount&cancelUrl&description&orderCode&returnUrl

        POS->>API: POST /v2/payment-requests
        Note over API: Headers: x-client-id, x-api-key<br/>Body: orderCode, amount, items, signature, returnUrl, cancelUrl

        alt Response code == "00" (Thanh cong)
            API-->>POS: checkoutUrl, qrCode, accountNumber, accountName
            POS-->>UI: PaymentResult(success: true, qrCodeData, orderCode)
            UI->>QR: Hien thi dialog chua ma QR
            QR-->>NTD: Ma QR + thong tin chuyen khoan + huong dan
        else Response loi
            API-->>POS: Error response (code != "00")
            POS-->>UI: PaymentResult(success: false, error: desc tu PayOS)
            UI-->>NTD: Hien thi thong bao loi
        end
    end
```

### 4.2 Xac nhan thanh toan va kich hoat goi

```mermaid
sequenceDiagram
    autonumber
    participant NTD as Nha tuyen dung
    participant QR as QR Payment Dialog
    participant POS as PayOSService
    participant API as PayOS API
    participant SS as SubscriptionService
    participant DB as Supabase (profiles)

    Note over NTD,DB: Luong xac nhan thanh toan sau khi quet QR

    NTD->>NTD: Mo app ngan hang, quet ma QR va thanh toan
    NTD->>QR: Nhan nut "Da thanh toan"
    QR->>POS: checkPaymentStatus(orderCode)
    POS->>API: GET /v2/payment-requests/{orderCode}

    alt status == "PAID" (Da thanh toan)
        API-->>POS: PaymentStatus(isPaid: true, transactionId)
        POS-->>QR: PaymentStatus(isPaid: true)

        Note over QR,DB: Luu thong tin subscription vao database

        QR->>SS: saveSubscription(plan, transactionId)
        SS->>DB: SELECT metadata FROM profiles WHERE id = userId
        DB-->>SS: Current metadata

        Note over SS: Cap nhat subscription:<br/>plan, started_at, expires_at (+ 1 thang)<br/>transaction_id, payment_history[]

        SS->>DB: UPDATE profiles SET metadata = updated_metadata
        DB-->>SS: Success
        SS-->>QR: Subscription saved

        QR-->>NTD: Thong bao "Kich hoat goi thanh cong!"
        Note over NTD: Nha tuyen dung co the dang them tin tuyen dung

    else status != "PAID" (Chua thanh toan)
        API-->>POS: PaymentStatus(isPaid: false, status: PENDING/CANCELLED)
        POS-->>QR: PaymentStatus(isPaid: false)
        QR-->>NTD: Thong bao "Chua nhan duoc thanh toan. Trang thai: {status}"
    end
```

### 4.3 Kiem tra quyen dang tin (Subscription Check)

```mermaid
sequenceDiagram
    autonumber
    participant NTD as Nha tuyen dung
    participant UI as JobPostingScreen
    participant SS as SubscriptionService
    participant DB as Supabase

    Note over NTD,DB: Kiem tra quyen dang tin truoc khi tao bai dang moi

    NTD->>UI: Nhan "Dang tin tuyen dung moi"
    UI->>SS: canPostJob(userId)
    SS->>DB: SELECT metadata FROM profiles WHERE id = userId
    DB-->>SS: metadata (subscription info)

    alt Khong co subscription data
        SS->>SS: Ap dung goi Free (4 tin/thang)
    else Co subscription data
        SS->>SS: Kiem tra expires_at

        alt Subscription het han
            SS->>SS: Reset ve goi Free + set wasExpired = true
        else Subscription con han
            SS->>SS: Lay plan hien tai (basic: 5, standard: 6, vip: 7 tin)
        end
    end

    SS->>DB: COUNT jobs WHERE employer_id AND created_at trong thang nay
    DB-->>SS: So tin da dang

    alt remainingJobs > 0
        SS-->>UI: CanPostResult(allowed: true, remaining: N)
        UI-->>NTD: Cho phep tao tin moi
    else remainingJobs <= 0
        SS-->>UI: CanPostResult(allowed: false)
        UI-->>NTD: Hien thi thong bao "Het luot dang tin. Vui long nang cap goi"
    end
```

---

## Tong Ket Cac Luong Chinh

```mermaid
graph LR
    subgraph Authentication
        A1[Email Login] --> A2[Google Login]
        A2 --> A3[Register]
        A3 --> A4[Logout]
    end

    subgraph AI Matching
        B1[CV Upload + OCR] --> B2[CV Structured]
        B2 --> B3[CV Comparison]
        B3 --> B4[Chatbot + Intent]
    end

    subgraph Notification
        C1[Tao Notification] --> C2[Gui qua FCM]
        C2 --> C3[Nhan tren Client]
        C3 --> C4[Navigate den man hinh]
    end

    subgraph Payment
        D1[Chon goi] --> D2[Tao QR PayOS]
        D2 --> D3[Xac nhan thanh toan]
        D3 --> D4[Kich hoat subscription]
    end
```

---

## Lien Ket Lien Quan

- [Tong quan kien truc](../01_tong_quan_kien_truc.md)
- [Luong Authentication chi tiet](../02_co_che_tung_chuc_nang/authentication_flow.md)
- [Luong AI Matching chi tiet](../02_co_che_tung_chuc_nang/ai_matching_flow.md)
- [Luong Notification chi tiet](../02_co_che_tung_chuc_nang/notification_flow.md)
- [Luong Payment chi tiet](../02_co_che_tung_chuc_nang/payment_flow.md)
- [State Management Flow](./state_management_flow.mermaid)
- [Navigation Flow](./navigation_flow.mermaid)
