import Foundation
import CoreData
import SwiftUI

enum TrainingSectionType: String, CaseIterable {
    case warmup = "热身"
    case training = "训练"
    case stretch = "拉伸"
    case cooldown = "放松"
    
    var color: Color {
        switch self {
        case .warmup:
            return .orange
        case .training:
            return .blue
        case .stretch:
            return .green
        case .cooldown:
            return .purple
        }
    }
}

class TrainingViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    @Published var trainingPlans: [TrainingPlan] = []
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchTrainingPlans()
    }
    
    // 获取所有训练计划
    func fetchTrainingPlans() {
        let request = NSFetchRequest<TrainingPlan>(entityName: "TrainingPlan")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrainingPlan.createdAt, ascending: false)]
        
        do {
            trainingPlans = try viewContext.fetch(request)
        } catch {
            print("获取训练计划失败: \(error)")
        }
    }
    
    // 创建新训练计划
    func createTrainingPlan(name: String) -> TrainingPlan {
        let plan = TrainingPlan(context: viewContext)
        plan.id = UUID()
        plan.name = name
        plan.createdAt = Date()
        
        saveContext()
        fetchTrainingPlans()
        
        return plan
    }
    
    // 添加训练阶段
    func addSection(to plan: TrainingPlan, name: String, type: TrainingSectionType, duration: Int32) {
        let section = TrainingSection(context: viewContext)
        section.id = UUID()
        section.name = name
        section.type = type.rawValue
        section.duration = duration
        section.plan = plan
        
        if let sections = plan.sections?.allObjects as? [TrainingSection] {
            section.order = Int16(sections.count)
        } else {
            section.order = 0
        }
        
        saveContext()
    }
    
    // 添加训练项目
    func addExercise(to section: TrainingSection, name: String, desc: String, sets: Int16, reps: Int16, duration: Int32) {
        let exercise = TrainingExercise(context: viewContext)
        exercise.id = UUID()
        exercise.name = name
        exercise.desc = desc
        exercise.sets = sets
        exercise.reps = reps
        exercise.duration = duration
        exercise.section = section
        
        if let exercises = section.exercises?.allObjects as? [TrainingExercise] {
            exercise.order = Int16(exercises.count)
        } else {
            exercise.order = 0
        }
        
        saveContext()
    }
    
    // 删除训练计划
    func deletePlan(_ plan: TrainingPlan) {
        viewContext.delete(plan)
        saveContext()
        fetchTrainingPlans()
    }
    
    // 保存上下文
    func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("保存上下文失败: \(error)")
        }
    }
    
    // 创建示例数据
    func createSampleData() {
        // 检查是否已有数据
        if !trainingPlans.isEmpty {
            return
        }
        
        // 创建一个基础训练计划
        let plan = createTrainingPlan(name: "基础全身训练")
        
        // 添加热身阶段
        let warmupSection = TrainingSection(context: viewContext)
        warmupSection.id = UUID()
        warmupSection.name = "热身"
        warmupSection.type = TrainingSectionType.warmup.rawValue
        warmupSection.duration = 300 // 5分钟
        warmupSection.order = 0
        warmupSection.plan = plan
        
        // 添加训练阶段
        let trainingSection = TrainingSection(context: viewContext)
        trainingSection.id = UUID()
        trainingSection.name = "主要训练"
        trainingSection.type = TrainingSectionType.training.rawValue
        trainingSection.duration = 1800 // 30分钟
        trainingSection.order = 1
        trainingSection.plan = plan
        
        // 添加拉伸阶段
        let stretchSection = TrainingSection(context: viewContext)
        stretchSection.id = UUID()
        stretchSection.name = "拉伸"
        stretchSection.type = TrainingSectionType.stretch.rawValue
        stretchSection.duration = 300 // 5分钟
        stretchSection.order = 2
        stretchSection.plan = plan
        
        // 添加热身运动
        addExercise(to: warmupSection, name: "跑步", desc: "慢跑热身", sets: 1, reps: 0, duration: 180)
        addExercise(to: warmupSection, name: "高抬腿", desc: "每条腿20次", sets: 1, reps: 40, duration: 60)
        addExercise(to: warmupSection, name: "扩胸运动", desc: "伸展肩部和胸部", sets: 1, reps: 10, duration: 60)
        
        // 添加训练运动
        addExercise(to: trainingSection, name: "俯卧撑", desc: "标准俯卧撑，胸部贴近地面", sets: 3, reps: 12, duration: 0)
        addExercise(to: trainingSection, name: "深蹲", desc: "标准深蹲，大腿与地面平行", sets: 3, reps: 15, duration: 0)
        addExercise(to: trainingSection, name: "平板支撑", desc: "保持平板姿势", sets: 3, reps: 0, duration: 30)
        
        // 添加拉伸运动
        addExercise(to: stretchSection, name: "hamstring stretch", desc: "坐姿前倾，伸展腿部后侧", sets: 1, reps: 0, duration: 30)
        addExercise(to: stretchSection, name: "肩部拉伸", desc: "拉伸肩膀和三角肌", sets: 1, reps: 0, duration: 30)
        addExercise(to: stretchSection, name: "chest stretch", desc: "伸展胸大肌", sets: 1, reps: 0, duration: 30)
        
        saveContext()
        fetchTrainingPlans()
    }
} 