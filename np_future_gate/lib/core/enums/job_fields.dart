enum JobField {
  itSoftware,
  marketing,
  sales,
  accountingAudit,
  hrAdmin,
  construction,
  architecture,
  education,
  medicalHealth,
  customerService,
  production,
  transportLogistics,
  designCreative,
  bankingFinance,
  realEstate,
  restaurantHotel,
  legal,
  interpreterTranslator,
  telecommunications,
  insurance,
  retail,
  other;

  String get displayName {
    switch (this) {
      case JobField.itSoftware: return 'IT - Phần mềm';
      case JobField.marketing: return 'Marketing / Truyền thông';
      case JobField.sales: return 'Kinh doanh / Bán hàng';
      case JobField.accountingAudit: return 'Kế toán / Kiểm toán';
      case JobField.hrAdmin: return 'Nhân sự / Hành chính';
      case JobField.construction: return 'Xây dựng';
      case JobField.architecture: return 'Kiến trúc / Nội thất';
      case JobField.education: return 'Giáo dục / Đào tạo';
      case JobField.medicalHealth: return 'Y tế / Sức khỏe';
      case JobField.customerService: return 'Dịch vụ khách hàng';
      case JobField.production: return 'Sản xuất / Vận hành';
      case JobField.transportLogistics: return 'Vận tải / Kho vận';
      case JobField.designCreative: return 'Thiết kế / Sáng tạo';
      case JobField.bankingFinance: return 'Ngân hàng / Tài chính';
      case JobField.realEstate: return 'Bất động sản';
      case JobField.restaurantHotel: return 'Nhà hàng / Khách sạn';
      case JobField.legal: return 'Luật / Pháp lý';
      case JobField.interpreterTranslator: return 'Biên / Phiên dịch';
      case JobField.telecommunications: return 'Viễn thông';
      case JobField.insurance: return 'Bảo hiểm';
      case JobField.retail: return 'Bán lẻ / Tiêu dùng';
      case JobField.other: return 'Khác';
    }
  }

  static List<String> get valuesList => values.map((e) => e.displayName).toList();
}
