import os
import uvicorn
from fastapi import FastAPI, File, UploadFile, Form
from paddleocr import PaddleOCR
from sentence_transformers import SentenceTransformer, util
import json
import tempfile
from pdf2image import convert_from_path
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

# Load .env file từ thư mục np_future_gate
env_path = os.path.join(os.path.dirname(__file__), '..', 'np_future_gate', '.env')
load_dotenv(dotenv_path=env_path)

app = FastAPI()

# Cấu hình CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

import requests

# Cấu hình AI
MISTRAL_API_KEY = os.getenv("MISTRAL_API_KEY")
MISTRAL_MODEL = os.getenv("MISTRAL_MODEL", "open-mistral-7b")
MISTRAL_URL = "https://api.mistral.ai/v1/chat/completions"

if not MISTRAL_API_KEY:
    print("❌ CẢNH BÁO: Chưa cấu hình MISTRAL_API_KEY trong biến môi trường!")
    # Bạn có thể dán trực tiếp key vào đây để test nhanh:
    # MISTRAL_API_KEY = "your_key_here"

model_similarity = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')
ocr = PaddleOCR(use_textline_orientation=True, lang='vi') 

def extract_text_from_cv(file_path):
    """Sử dụng PaddleOCR để lấy text từ PDF hoặc Ảnh"""
    if file_path.endswith('.pdf'):
        # Chuyển PDF sang ảnh để OCR chính xác hơn
        images = convert_from_path(file_path)
        full_text = ""
        for i, img in enumerate(images):
            img_path = f"temp_page_{i}.jpg"
            img.save(img_path, 'JPEG')
            result = ocr.ocr(img_path, cls=True)
            for line in result[0]:
                full_text += line[1][0] + " "
            os.remove(img_path)
        return full_text
    else:
        # Xử lý trực tiếp nếu là file ảnh
        result = ocr.ocr(file_path, cls=True)
        return " ".join([line[1][0] for line in result[0]])

@app.post("/analyze_cv")
async def analyze_cv(
    cv_file: UploadFile = File(...),
    job_description: str = Form(...),
    requirements: str = Form(...)
):
    # 1. Save temp file
    ext = os.path.splitext(cv_file.filename)[1]
    with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as tmp:
        tmp.write(await cv_file.read())
        tmp_path = tmp.name

    try:
        # 2. OCR Step
        print(f"DEBUG: Processing file {cv_file.filename}...")
        cv_text = extract_text_from_cv(tmp_path)
        print(f"DEBUG: OCR extracted {len(cv_text)} characters.")
        
        if len(cv_text.strip()) < 50:
            return {
                "overall_score": 0,
                "summary": "Không thể trích xuất văn bản từ CV này. Vui lòng kiểm tra định dạng file.",
                "matching_points": [],
                "missing_points": ["Văn bản quá ngắn hoặc lỗi OCR"],
                "parsed_data": {"Status": "OCR Error"}
            }

        # 3. LLM Analysis with Mistral AI
        prompt = f"""
        Bạn là chuyên gia tuyển dụng cao cấp. Hãy phân tích độ phù hợp giữa CV và Công việc.
        
        TIN TUYỂN DỤNG:
        {job_description}
        YÊU CẦU: {requirements}
        
        NỘI DUNG CV (TỪ OCR):
        {cv_text}
        
        QUY TẮC CHẤM ĐIỂM:
        1. Nếu CV không có kỹ năng liên quan đến Job (ví dụ: Job Flutter mà CV không có Flutter/Dart), điểm không quá 20.
        2. Chú ý các kỹ năng then chốt: Flutter, Dart, REST API, Bloc, Provider, Git.
        3. Nếu CV phù hợp tốt mặt kỹ thuật, điểm phải trên 80%.
        
        HÃY TRẢ VỀ JSON DUY NHẤT:
        {{
            "overall_score": (int từ 0-100),
            "keyword_match_score": (int từ 0-100),
            "summary": "Tóm tắt chuyên sâu 2-3 câu",
            "matching_points": ["Điểm khớp 1", "Điểm khớp 2"],
            "missing_points": ["Yêu cầu còn thiếu 1", "Yêu cầu còn thiếu 2"],
            "parsed_data": {{
                "Họ tên": "Tên ứng viên",
                "Học vấn": "Trường, chuyên ngành",
                "Kinh nghiệm": "Số năm hoặc vị trí gần nhất",
                "Kỹ năng chính": "Liệt kê kỹ năng chuyên môn phát hiện được",
                "Engine": "PaddleOCR + Mistral Analysis"
            }}
        }}
        """
        
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {MISTRAL_API_KEY}"
        }
        
        payload = {
            "model": MISTRAL_MODEL,
            "messages": [
                {"role": "system", "content": "You are a professional recruitment assistant. Always output valid JSON."},
                {"role": "user", "content": prompt}
            ],
            "response_format": {"type": "json_object"}
        }
        
        response = requests.post(MISTRAL_URL, headers=headers, json=payload)
        response.raise_for_status()
        
        content = response.json()['choices'][0]['message']['content'].strip()
        analysis_result = json.loads(content)

        # 4. Semantic Similarity
        emb1 = model_similarity.encode(cv_text, convert_to_tensor=True)
        emb2 = model_similarity.encode(f"{job_description} {requirements}", convert_to_tensor=True)
        cosine_score = util.pytorch_cos_sim(emb1, emb2).item()
        
        analysis_result["semantic_similarity"] = cosine_score
        
        print(f"DEBUG: Analysis complete. Score: {analysis_result['overall_score']}")
        return analysis_result

    except Exception as e:
        print(f"ERROR: {str(e)}")
        return {
            "overall_score": 0,
            "summary": f"Lỗi xử lý AI: {str(e)}",
            "matching_points": [],
            "missing_points": ["Backend Error"],
            "parsed_data": {"Error": str(e)}
        }
    finally:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
