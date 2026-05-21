import 'package:np_future_gate/core/models/job_model.dart';

/// Mock data cho demo/preview
class MockJobs {
  static List<JobModel> getSampleJobs() {
    return [
      JobModel(
        id: 'demo-1',
        creatorId: 'demo-creator-1',
        isActive: true,
        deadline: DateTime.now().add(const Duration(days: 30)),
        metadata: JobMetadata(
          title: 'Senior Flutter Developer',
          workingRegions: ['Hà Nội'],
          experienceRequired: '2-3 years',
          fields: ['Mobile Development', 'Flutter'],
          employmentTypes: ['full-time'],
          workLocations: ['Ha Noi'],
          salary: JobSalary(
            min: 20000000,
            max: 30000000,
            currency: 'VND',
            type: 'monthly',
          ),
          jobDescription: [
            'Phát triển ứng dụng mobile với Flutter',
            'Làm việc với team backend để tích hợp API',
          ],
          benefits: ['Lương cao', 'Làm remote'],
        ),
        creatorName: 'Tech Company A',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      JobModel(
        id: 'demo-2',
        creatorId: 'demo-creator-2',
        isActive: true,
        deadline: DateTime.now().add(const Duration(days: 20)),
        metadata: JobMetadata(
          title: 'Backend Developer (Node.js)',
          workingRegions: ['Hồ Chí Minh'],
          experienceRequired: '1-2 years',
          fields: ['Backend', 'Node.js'],
          employmentTypes: ['full-time'],
          workLocations: ['Ho Chi Minh'],
          salary: JobSalary(
            min: 15000000,
            max: 25000000,
            currency: 'VND',
            type: 'monthly',
          ),
          jobDescription: [
            'Phát triển backend với Node.js',
            'Thiết kế database và API',
          ],
          benefits: ['Bảo hiểm', 'Thưởng tết'],
        ),
        creatorName: 'Startup B',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      JobModel(
        id: 'demo-3',
        creatorId: 'demo-creator-3',
        isActive: true,
        deadline: DateTime.now().add(const Duration(days: 15)),
        metadata: JobMetadata(
          title: 'UI/UX Designer',
          workingRegions: ['Đà Nẵng'],
          experienceRequired: '1 year',
          fields: ['Design', 'UI/UX'],
          employmentTypes: ['part-time'],
          workLocations: ['Da Nang'],
          salary: JobSalary(
            min: 12000000,
            max: 18000000,
            currency: 'VND',
            type: 'monthly',
          ),
          jobDescription: [
            'Thiết kế giao diện app mobile',
            'Làm việc với team phát triển',
          ],
          benefits: ['Flexible time', 'Work from home'],
        ),
        creatorName: 'Design Studio C',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
