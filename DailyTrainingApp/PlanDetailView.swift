import SwiftUI
import CoreData

struct PlanDetailView: View {
    let plan: TrainingPlan
    var viewModel: TrainingViewModel
    
    @State private var showingAddSection = false
    @State private var selectedSection: TrainingSection?
    
    var body: some View {
        List {
            Section(header: Text("计划信息")) {
                VStack(alignment: .leading) {
                    Text(plan.name ?? "未命名计划")
                        .font(.headline)
                    
                    if let date = plan.createdAt {
                        Text("创建于: \(dateFormatter.string(from: date))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let sections = plan.sections?.allObjects as? [TrainingSection], !sections.isEmpty {
                ForEach(sections.sorted(by: { $0.order < $1.order }), id: \.id) { section in
                    Section(header: sectionHeader(for: section)) {
                        NavigationLink(
                            destination: SectionDetailView(section: section, viewModel: viewModel),
                            tag: section,
                            selection: $selectedSection
                        ) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(section.name ?? "未命名阶段")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    if let exercises = section.exercises?.allObjects as? [TrainingExercise] {
                                        Text("\(exercises.count) 个动作")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if section.duration > 0 {
                                    Text("持续时间: \(formatDuration(section.duration))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            } else {
                Section {
                    Text("暂无训练阶段")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .navigationTitle("训练计划详情")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddSection = true }) {
                    Label("添加阶段", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: StartTrainingView(plan: plan)) {
                    Text("开始训练")
                        .fontWeight(.bold)
                }
            }
        }
        .sheet(isPresented: $showingAddSection) {
            AddSectionView(isPresented: $showingAddSection, plan: plan, viewModel: viewModel)
        }
    }
    
    private func sectionHeader(for section: TrainingSection) -> some View {
        HStack {
            if let type = section.type, let sectionType = TrainingSectionType(rawValue: type) {
                Circle()
                    .fill(sectionType.color)
                    .frame(width: 10, height: 10)
                
                Text(sectionType.rawValue)
            } else {
                Text("训练阶段")
            }
        }
    }
    
    private func formatDuration(_ duration: Int32) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d分%02d秒", minutes, seconds)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

struct AddSectionView: View {
    @Binding var isPresented: Bool
    let plan: TrainingPlan
    var viewModel: TrainingViewModel
    
    @State private var sectionName = ""
    @State private var selectedType = TrainingSectionType.training
    @State private var durationMinutes: Int = 5
    @State private var durationSeconds: Int = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("阶段信息")) {
                    TextField("阶段名称", text: $sectionName)
                    
                    Picker("阶段类型", selection: $selectedType) {
                        ForEach(TrainingSectionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    HStack {
                        Text("持续时间")
                        Spacer()
                        Picker("分钟", selection: $durationMinutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)分").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        .clipped()
                        
                        Picker("秒", selection: $durationSeconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)秒").tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 100)
                        .clipped()
                    }
                }
                
                Section {
                    Button("添加阶段") {
                        let totalDuration = Int32(durationMinutes * 60 + durationSeconds)
                        viewModel.addSection(to: plan, name: sectionName, type: selectedType, duration: totalDuration)
                        isPresented = false
                    }
                    .disabled(sectionName.isEmpty)
                }
            }
            .navigationTitle("添加训练阶段")
            .navigationBarItems(trailing: Button("取消") {
                isPresented = false
            })
        }
    }
} 