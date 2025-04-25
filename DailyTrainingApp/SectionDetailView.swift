import SwiftUI
import CoreData

struct SectionDetailView: View {
    let section: TrainingSection
    var viewModel: TrainingViewModel
    
    @State private var showingAddExercise = false
    @State private var selectedExercise: TrainingExercise?
    
    var body: some View {
        List {
            Section(header: Text("阶段信息")) {
                HStack {
                    if let type = section.type, let sectionType = TrainingSectionType(rawValue: type) {
                        Circle()
                            .fill(sectionType.color)
                            .frame(width: 12, height: 12)
                        Text(sectionType.rawValue)
                            .font(.headline)
                    }
                }
                
                Text("名称: \(section.name ?? "未命名阶段")")
                
                if section.duration > 0 {
                    Text("持续时间: \(formatDuration(section.duration))")
                }
            }
            
            Section(header: Text("训练动作")) {
                if let exercises = section.exercises?.allObjects as? [TrainingExercise], !exercises.isEmpty {
                    ForEach(exercises.sorted(by: { $0.order < $1.order }), id: \.id) { exercise in
                        NavigationLink(
                            destination: ExerciseDetailView(exercise: exercise),
                            tag: exercise,
                            selection: $selectedExercise
                        ) {
                            VStack(alignment: .leading) {
                                Text(exercise.name ?? "未命名动作")
                                    .font(.headline)
                                
                                HStack {
                                    if exercise.sets > 0 {
                                        Text("\(exercise.sets)组")
                                    }
                                    
                                    if exercise.reps > 0 {
                                        Text("x \(exercise.reps)次")
                                    }
                                    
                                    if exercise.duration > 0 {
                                        Spacer()
                                        Text("\(formatDuration(exercise.duration))")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                if let desc = exercise.desc, !desc.isEmpty {
                                    Text(desc)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                } else {
                    Text("暂无训练动作")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .navigationTitle(section.name ?? "未命名阶段")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddExercise = true }) {
                    Label("添加动作", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView(isPresented: $showingAddExercise, section: section, viewModel: viewModel)
        }
    }
    
    private func formatDuration(_ duration: Int32) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d分%02d秒", minutes, seconds)
    }
}

struct AddExerciseView: View {
    @Binding var isPresented: Bool
    let section: TrainingSection
    var viewModel: TrainingViewModel
    
    @State private var exerciseName = ""
    @State private var exerciseDesc = ""
    @State private var sets: Int = 3
    @State private var reps: Int = 10
    @State private var durationMinutes: Int = 0
    @State private var durationSeconds: Int = 30
    @State private var exerciseType: ExerciseType = .reps
    
    enum ExerciseType: String, CaseIterable, Identifiable {
        case reps = "次数"
        case duration = "时间"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("动作信息")) {
                    TextField("动作名称", text: $exerciseName)
                    TextField("动作描述", text: $exerciseDesc)
                    
                    Picker("动作类型", selection: $exerciseType) {
                        ForEach(ExerciseType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if exerciseType == .reps {
                    Section(header: Text("组数与次数")) {
                        Stepper("组数: \(sets)", value: $sets, in: 1...10)
                        Stepper("每组次数: \(reps)", value: $reps, in: 1...100)
                    }
                } else {
                    Section(header: Text("持续时间")) {
                        HStack {
                            Picker("分钟", selection: $durationMinutes) {
                                ForEach(0..<30) { minute in
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
                }
                
                Section {
                    Button("添加动作") {
                        let totalDuration = exerciseType == .duration ? Int32(durationMinutes * 60 + durationSeconds) : 0
                        let finalReps = exerciseType == .reps ? Int16(reps) : 0
                        viewModel.addExercise(
                            to: section,
                            name: exerciseName,
                            desc: exerciseDesc,
                            sets: Int16(sets),
                            reps: finalReps,
                            duration: totalDuration
                        )
                        isPresented = false
                    }
                    .disabled(exerciseName.isEmpty)
                }
            }
            .navigationTitle("添加训练动作")
            .navigationBarItems(trailing: Button("取消") {
                isPresented = false
            })
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: TrainingExercise
    
    var body: some View {
        List {
            Section(header: Text("动作信息")) {
                Text("名称: \(exercise.name ?? "未命名动作")")
                    .font(.headline)
                
                if let desc = exercise.desc, !desc.isEmpty {
                    Text("描述: \(desc)")
                }
            }
            
            Section(header: Text("训练参数")) {
                if exercise.sets > 0 {
                    Text("组数: \(exercise.sets)")
                }
                
                if exercise.reps > 0 {
                    Text("每组次数: \(exercise.reps)")
                }
                
                if exercise.duration > 0 {
                    Text("持续时间: \(formatDuration(exercise.duration))")
                }
            }
        }
        .navigationTitle(exercise.name ?? "动作详情")
    }
    
    private func formatDuration(_ duration: Int32) -> String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d分%02d秒", minutes, seconds)
    }
} 