import SwiftUI
import CoreData

struct StartTrainingView: View {
    let plan: TrainingPlan
    
    @State private var currentSectionIndex = 0
    @State private var currentExerciseIndex = 0
    @State private var remainingTime: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer? = nil
    @State private var showingCompleteAlert = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var sections: [TrainingSection] {
        if let sections = plan.sections?.allObjects as? [TrainingSection] {
            return sections.sorted(by: { $0.order < $1.order })
        }
        return []
    }
    
    var currentSection: TrainingSection? {
        guard currentSectionIndex < sections.count else { return nil }
        return sections[currentSectionIndex]
    }
    
    var exercises: [TrainingExercise] {
        if let section = currentSection, 
           let exercises = section.exercises?.allObjects as? [TrainingExercise] {
            return exercises.sorted(by: { $0.order < $1.order })
        }
        return []
    }
    
    var currentExercise: TrainingExercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 头部进度指示器
            HStack {
                ForEach(0..<sections.count, id: \.self) { index in
                    Circle()
                        .fill(sectionColor(for: index))
                        .frame(width: 12, height: 12)
                    
                    if index < sections.count - 1 {
                        Rectangle()
                            .fill(index < currentSectionIndex ? Color.green : Color.gray.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal)
            
            // 当前训练阶段
            if let section = currentSection {
                VStack {
                    if let type = section.type, let sectionType = TrainingSectionType(rawValue: type) {
                        Text(sectionType.rawValue)
                            .font(.title3)
                            .foregroundColor(sectionType.color)
                    }
                    
                    Text(section.name ?? "")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 5)
                    
                    if let exercise = currentExercise {
                        ExerciseView(
                            exercise: exercise,
                            remainingTime: $remainingTime,
                            isRunning: $isRunning
                        )
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    } else {
                        Text("准备下一阶段...")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .center)
            } else {
                Text("训练完成！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            
            // 控制按钮
            HStack(spacing: 40) {
                Button(action: previousExercise) {
                    Image(systemName: "backward.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
                
                Button(action: toggleTimer) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(isRunning ? .red : .green)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(Color.gray.opacity(0.2)))
                }
                
                Button(action: nextExercise) {
                    Image(systemName: "forward.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 30)
        }
        .padding()
        .navigationTitle("训练中")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("退出") {
                    stopTimer()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onAppear {
            prepareExercise()
        }
        .alert(isPresented: $showingCompleteAlert) {
            Alert(
                title: Text("训练完成"),
                message: Text("恭喜你完成了今天的训练！"),
                dismissButton: .default(Text("确定")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func sectionColor(for index: Int) -> Color {
        guard index < sections.count else { return .gray }
        
        if index < currentSectionIndex {
            return .green
        } else if index == currentSectionIndex {
            let section = sections[index]
            if let type = section.type,
               let sectionType = TrainingSectionType(rawValue: type) {
                return sectionType.color
            }
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
    
    private func prepareExercise() {
        stopTimer()
        
        if let exercise = currentExercise {
            if exercise.duration > 0 {
                remainingTime = Int(exercise.duration)
            } else {
                remainingTime = 0
            }
        } else if currentExerciseIndex >= exercises.count {
            moveToNextSection()
        }
    }
    
    private func toggleTimer() {
        if isRunning {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        guard !isRunning && remainingTime > 0 else {
            if remainingTime <= 0 {
                nextExercise()
            }
            return
        }
        
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            } else {
                stopTimer()
                // 可以添加音效或震动通知用户时间到了
                nextExercise()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
    
    private func nextExercise() {
        stopTimer()
        
        if currentExerciseIndex < exercises.count - 1 {
            // 还有下一个动作
            currentExerciseIndex += 1
            prepareExercise()
        } else {
            // 完成所有动作，移到下一阶段
            moveToNextSection()
        }
    }
    
    private func previousExercise() {
        stopTimer()
        
        if currentExerciseIndex > 0 {
            // 还有上一个动作
            currentExerciseIndex -= 1
            prepareExercise()
        } else if currentSectionIndex > 0 {
            // 移到上一阶段的最后一个动作
            currentSectionIndex -= 1
            if let previousSectionExercises = sections[currentSectionIndex].exercises?.allObjects as? [TrainingExercise],
               !previousSectionExercises.isEmpty {
                let sortedExercises = previousSectionExercises.sorted(by: { $0.order < $1.order })
                currentExerciseIndex = sortedExercises.count - 1
            } else {
                currentExerciseIndex = 0
            }
            prepareExercise()
        }
    }
    
    private func moveToNextSection() {
        if currentSectionIndex < sections.count - 1 {
            // 还有下一个阶段
            currentSectionIndex += 1
            currentExerciseIndex = 0
            prepareExercise()
        } else {
            // 完成所有阶段
            showingCompleteAlert = true
        }
    }
}

struct ExerciseView: View {
    let exercise: TrainingExercise
    @Binding var remainingTime: Int
    @Binding var isRunning: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Text(exercise.name ?? "未命名动作")
                .font(.title2)
                .fontWeight(.bold)
            
            if let desc = exercise.desc, !desc.isEmpty {
                Text(desc)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if exercise.sets > 0 && exercise.reps > 0 {
                HStack {
                    Spacer()
                    VStack {
                        Text("\(exercise.sets)")
                            .font(.system(size: 30, weight: .bold))
                        Text("组")
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("\(exercise.reps)")
                            .font(.system(size: 30, weight: .bold))
                        Text("次")
                            .font(.caption)
                    }
                    Spacer()
                }
                .padding(.vertical)
            }
            
            if exercise.duration > 0 {
                TimerView(
                    remainingTime: $remainingTime,
                    isRunning: $isRunning, 
                    totalDuration: Int(exercise.duration)
                )
            }
        }
    }
}

struct TimerView: View {
    @Binding var remainingTime: Int
    @Binding var isRunning: Bool
    let totalDuration: Int
    
    var body: some View {
        VStack {
            // 时间显示
            Text(timeString(from: remainingTime))
                .font(.system(size: 50, design: .monospaced))
                .fontWeight(.semibold)
            
            // 进度条
            if totalDuration > 0 {
                ProgressView(value: 1.0 - (Double(remainingTime) / Double(totalDuration)))
                    .accentColor(timeColor)
                    .animation(.linear, value: remainingTime)
                    .padding(.top, 5)
            }
        }
    }
    
    private var timeColor: Color {
        let percentage = Double(remainingTime) / Double(totalDuration)
        if percentage > 0.5 {
            return .green
        } else if percentage > 0.25 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct StartTrainingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            let context = PersistenceController.preview.container.viewContext
            let plan = TrainingPlan(context: context)
            plan.name = "预览训练"
            plan.id = UUID()
            
            let section = TrainingSection(context: context)
            section.name = "热身"
            section.type = TrainingSectionType.warmup.rawValue
            section.order = 0
            section.plan = plan
            
            let exercise = TrainingExercise(context: context)
            exercise.name = "跑步"
            exercise.desc = "慢跑热身"
            exercise.duration = 60
            exercise.section = section
            
            return StartTrainingView(plan: plan)
        }
    }
} 