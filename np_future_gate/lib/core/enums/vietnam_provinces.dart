enum VietnamProvince {
  haNoi,
  hoChiMinh,
  daNang,
  haiPhong,
  canTho,
  anGiang,
  baRiaVungTau,
  bacGiang,
  bacKan,
  bacLieu,
  bacNinh,
  benTre,
  binhDinh,
  binhDuong,
  binhPhuoc,
  binhThuan,
  caMau,
  caoBang,
  dakLak,
  dakNong,
  dienBien,
  dongNai,
  dongThap,
  giaLai,
  haGiang,
  haNam,
  haTinh,
  haiDuong,
  hauGiang,
  hoaBinh,
  hungYen,
  khanhHoa,
  kienGiang,
  konTum,
  laiChau,
  lamDong,
  langSon,
  laoCai,
  longAn,
  namDinh,
  ngheAn,
  ninhBinh,
  ninhThuan,
  phuTho,
  phuYen,
  quangBinh,
  quangNam,
  quangNgai,
  quangNinh,
  quangTri,
  socTrang,
  sonLa,
  tayNinh,
  thaiBinh,
  thaiNguyen,
  thanhHoa,
  thuaThienHue,
  tienGiang,
  traVinh,
  tuyenQuang,
  vinhLong,
  vinhPhuc,
  yenBai,
  other;

  String get displayName {
    switch (this) {
      case VietnamProvince.haNoi: return 'Hà Nội';
      case VietnamProvince.hoChiMinh: return 'Hồ Chí Minh';
      case VietnamProvince.daNang: return 'Đà Nẵng';
      case VietnamProvince.haiPhong: return 'Hải Phòng';
      case VietnamProvince.canTho: return 'Cần Thơ';
      case VietnamProvince.anGiang: return 'An Giang';
      case VietnamProvince.baRiaVungTau: return 'Bà Rịa - Vũng Tàu';
      case VietnamProvince.bacGiang: return 'Bắc Giang';
      case VietnamProvince.bacKan: return 'Bắc Kạn';
      case VietnamProvince.bacLieu: return 'Bạc Liêu';
      case VietnamProvince.bacNinh: return 'Bắc Ninh';
      case VietnamProvince.benTre: return 'Bến Tre';
      case VietnamProvince.binhDinh: return 'Bình Định';
      case VietnamProvince.binhDuong: return 'Bình Dương';
      case VietnamProvince.binhPhuoc: return 'Bình Phước';
      case VietnamProvince.binhThuan: return 'Bình Thuận';
      case VietnamProvince.caMau: return 'Cà Mau';
      case VietnamProvince.caoBang: return 'Cao Bằng';
      case VietnamProvince.dakLak: return 'Đắk Lắk';
      case VietnamProvince.dakNong: return 'Đắk Nông';
      case VietnamProvince.dienBien: return 'Điện Biên';
      case VietnamProvince.dongNai: return 'Đồng Nai';
      case VietnamProvince.dongThap: return 'Đồng Tháp';
      case VietnamProvince.giaLai: return 'Gia Lai';
      case VietnamProvince.haGiang: return 'Hà Giang';
      case VietnamProvince.haNam: return 'Hà Nam';
      case VietnamProvince.haTinh: return 'Hà Tĩnh';
      case VietnamProvince.haiDuong: return 'Hải Dương';
      case VietnamProvince.hauGiang: return 'Hậu Giang';
      case VietnamProvince.hoaBinh: return 'Hòa Bình';
      case VietnamProvince.hungYen: return 'Hưng Yên';
      case VietnamProvince.khanhHoa: return 'Khánh Hòa';
      case VietnamProvince.kienGiang: return 'Kiên Giang';
      case VietnamProvince.konTum: return 'Kon Tum';
      case VietnamProvince.laiChau: return 'Lai Châu';
      case VietnamProvince.lamDong: return 'Lâm Đồng';
      case VietnamProvince.langSon: return 'Lạng Sơn';
      case VietnamProvince.laoCai: return 'Lào Cai';
      case VietnamProvince.longAn: return 'Long An';
      case VietnamProvince.namDinh: return 'Nam Định';
      case VietnamProvince.ngheAn: return 'Nghệ An';
      case VietnamProvince.ninhBinh: return 'Ninh Bình';
      case VietnamProvince.ninhThuan: return 'Ninh Thuận';
      case VietnamProvince.phuTho: return 'Phú Thọ';
      case VietnamProvince.phuYen: return 'Phú Yên';
      case VietnamProvince.quangBinh: return 'Quảng Bình';
      case VietnamProvince.quangNam: return 'Quảng Nam';
      case VietnamProvince.quangNgai: return 'Quảng Ngãi';
      case VietnamProvince.quangNinh: return 'Quảng Ninh';
      case VietnamProvince.quangTri: return 'Quảng Trị';
      case VietnamProvince.socTrang: return 'Sóc Trăng';
      case VietnamProvince.sonLa: return 'Sơn La';
      case VietnamProvince.tayNinh: return 'Tây Ninh';
      case VietnamProvince.thaiBinh: return 'Thái Bình';
      case VietnamProvince.thaiNguyen: return 'Thái Nguyên';
      case VietnamProvince.thanhHoa: return 'Thanh Hóa';
      case VietnamProvince.thuaThienHue: return 'Thừa Thiên Huế';
      case VietnamProvince.tienGiang: return 'Tiền Giang';
      case VietnamProvince.traVinh: return 'Trà Vinh';
      case VietnamProvince.tuyenQuang: return 'Tuyên Quang';
      case VietnamProvince.vinhLong: return 'Vĩnh Long';
      case VietnamProvince.vinhPhuc: return 'Vĩnh Phúc';
      case VietnamProvince.yenBai: return 'Yên Bái';
      case VietnamProvince.other: return 'Khác';
    }
  }

  static List<String> get valuesList => values.map((e) => e.displayName).toList();
}
