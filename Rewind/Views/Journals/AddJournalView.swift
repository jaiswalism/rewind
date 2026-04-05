import SwiftUI
import PhotosUI

struct AddJournalView: View {
	let journalToEdit: DBJournal?
	let onSaveCompleted: ((DBJournal) -> Void)?

	@StateObject private var viewModel = JournalViewModel()

	init(journalToEdit: DBJournal? = nil, onSaveCompleted: ((DBJournal) -> Void)? = nil) {
		self.journalToEdit = journalToEdit
		self.onSaveCompleted = onSaveCompleted
	}
	@Environment(\.dismiss) private var dismiss
	@Environment(\.colorScheme) private var colorScheme

	private var isEditMode: Bool {
		journalToEdit != nil
	}

	@State private var selectedDate = Date()
	@State private var title = ""
	@State private var note = ""
	@State private var moodIndex = 3
	@State private var selectedFeelings: Set<String> = []
	@State private var selectedActivities: Set<String> = []
	@State private var selectedPhotoItems: [PhotosPickerItem] = []
	@State private var selectedImages: [UIImage] = []
	@State private var showPhotoPicker = false
	@State private var isLoading = false
	@State private var showFeelings = false
	@State private var showActivities = false
	@State private var showVoiceRecording = false
	@State private var voiceRecordingURL: URL?
	@State private var showDatePickerSheet = false
	@State private var showStatusAlert = false
	@State private var statusMessage = ""

	private let feelingsOptions = ["Happy", "Sad", "Angry", "Calm", "Stressed", "Excited", "Grateful", "Anxious"]
	private let activitiesOptions = ["Exercise", "Reading", "Gaming", "Cooking", "Shopping", "Socializing", "Work", "Movie"]

	private var bgMain: Color {
		colorScheme == .dark
			? Color(red: 0.10, green: 0.10, blue: 0.30)
			: Color(red: 0.98, green: 0.98, blue: 0.99)
	}

	private var cardBg: Color {
		colorScheme == .dark
			? Color(red: 0.16, green: 0.17, blue: 0.36)
			: Color.white
	}

	private var titleText: Color {
		colorScheme == .dark
			? Color(red: 0.63, green: 0.65, blue: 0.75)
			: Color(red: 0.44, green: 0.46, blue: 0.58)
	}

	private var primaryText: Color {
		colorScheme == .dark ? .white : Color(red: 0.25, green: 0.25, blue: 0.35)
	}

	private var buttonBlue: Color {
		Color(red: 0.30, green: 0.65, blue: 0.98)
	}

	private var trackBlue: Color {
		colorScheme == .dark
			? Color(red: 0.38, green: 0.95, blue: 0.67)
			: Color(red: 0.35, green: 0.40, blue: 0.90)
	}

	private var iconBg: Color {
		colorScheme == .dark ? Color.white.opacity(0.12) : Color(red: 0.95, green: 0.95, blue: 0.97)
	}

	private var moodLabel: String {
		moodOptions[moodIndex].label
	}

	private var moodEmoji: String {
		moodOptions[moodIndex].emoji
	}

	private var moodOptions: [(label: String, emoji: String)] {
		[
			("Unhappy", "😞"),
			("Low", "😕"),
			("Okay", "😐"),
			("Good", "🙂"),
			("Happy", "😄")
		]
	}

	var body: some View {
		ZStack {
			bgMain.ignoresSafeArea()

			ScrollView(showsIndicators: false) {
				VStack(alignment: .leading, spacing: 24) {
					topBar
					titleSection
					noteSection
					moodSection
					feelingsSection
					activitiesSection
					if !isEditMode {
						audioSection
						photoSection
					}
					saveButton
				}
				.padding(.horizontal, 24)
				.padding(.top, 12)
				.padding(.bottom, 22)
			}
		}
		.photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItems, matching: .images)
		.sheet(isPresented: $showVoiceRecording) {
			VoiceRecordingView { transcription, audioURL in
				note = transcription
				voiceRecordingURL = audioURL
			}
		}
		.sheet(isPresented: $showDatePickerSheet) {
			datePickerSheet
		}
		.alert("Journal", isPresented: $showStatusAlert) {
			Button("OK", role: .cancel) { }
		} message: {
			Text(statusMessage)
		}
		.onChange(of: selectedPhotoItems) { _, items in
			Task {
				selectedImages.removeAll()
				for item in items {
					if let data = try? await item.loadTransferable(type: Data.self),
					   let image = UIImage(data: data) {
						selectedImages.append(image)
					}
				}
			}
		}
		.onAppear {
			guard let journal = journalToEdit else { return }
			title = journal.title
			note = journal.content
			if let emotion = journal.emotion {
				moodIndex = moodIndex(from: emotion)
			}
			if let createdDate = journal.createdDate {
				selectedDate = createdDate
			}
			selectedFeelings = Set(journal.feelings ?? [])
			selectedActivities = Set(journal.activities ?? [])
		}
	}

	private var topBar: some View {
		HStack {
			Button(action: { dismiss() }) {
				Image(systemName: "xmark")
					.font(.system(size: 16, weight: .bold))
					.foregroundColor(titleText)
					.frame(width: 44, height: 44)
					.background(cardBg)
					.clipShape(Circle())
					.shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
			}
			.buttonStyle(.plain)

			Spacer()

			Button(action: { showDatePickerSheet = true }) {
				HStack(spacing: 6) {
					Text(formattedTime(from: selectedDate))
						.font(.system(size: 15, weight: .semibold, design: .rounded))
						.foregroundColor(primaryText)
					Image(systemName: "chevron.down")
						.font(.system(size: 12, weight: .bold))
						.foregroundColor(primaryText)
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 12)
				.background(cardBg)
				.clipShape(Capsule())
				.shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
			}
			.buttonStyle(.plain)
			.frame(minWidth: 148)
		}
	}

	private var noteSection: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text("Your note")
				.font(.system(size: 16, weight: .bold, design: .rounded))
				.foregroundColor(titleText)

			TextField("What's on your mind?", text: $note, axis: .vertical)
				.font(.system(size: 18, weight: .semibold, design: .rounded))
				.foregroundColor(primaryText)
				.frame(minHeight: 40, alignment: .top)
		}
	}

	private var moodSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Mood")
				.font(.system(size: 16, weight: .bold, design: .rounded))
				.foregroundColor(titleText)

			VStack(spacing: 16) {
				Text(moodEmoji)
					.font(.system(size: 58))
					.id(moodIndex)
					.transition(.scale.combined(with: .opacity))

				Text(moodLabel)
					.font(.system(size: 20, weight: .bold, design: .rounded))
					.foregroundColor(trackBlue)
					.contentTransition(.opacity)

				Slider(
					value: Binding(
						get: { Double(moodIndex) },
						set: { newValue in
							withAnimation(.interactiveSpring(response: 0.22, dampingFraction: 0.86)) {
								moodIndex = Int(newValue.rounded())
							}
						}
					),
					in: 0...Double(moodOptions.count - 1),
					step: 1
				)
				.tint(trackBlue)

				HStack(spacing: 0) {
					ForEach(moodOptions.indices, id: \.self) { index in
						Circle()
							.fill(moodIndex == index ? trackBlue : titleText.opacity(0.25))
							.frame(width: 8, height: 8)
							.frame(maxWidth: .infinity)
					}
				}

				HStack {
					Text(moodOptions.first?.label ?? "Unhappy")
						.font(.system(size: 12, weight: .bold, design: .rounded))
						.foregroundColor(titleText)
					Spacer()
					Text(moodOptions.last?.label ?? "Happy")
						.font(.system(size: 12, weight: .bold, design: .rounded))
						.foregroundColor(titleText)
				}
			}
			.animation(.easeInOut(duration: 0.18), value: moodIndex)
			.padding(.horizontal, 24)
			.padding(.vertical, 20)
			.background(cardBg)
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
		}
	}

	private var feelingsSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Feelings")
				.font(.system(size: 16, weight: .bold, design: .rounded))
				.foregroundColor(titleText)

			expandableCard(title: "Pick words that match\nyour feelings", isExpanded: $showFeelings, selectedCount: selectedFeelings.count)

			if showFeelings {
				LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
					ForEach(feelingsOptions, id: \.self) { feeling in
						tagButton(title: feeling, isSelected: selectedFeelings.contains(feeling)) {
							toggle(selected: &selectedFeelings, value: feeling)
						}
					}
				}
			}
		}
	}

	private var activitiesSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Activities")
				.font(.system(size: 16, weight: .bold, design: .rounded))
				.foregroundColor(titleText)

			expandableCard(title: "What have you\nbeen up to?", isExpanded: $showActivities, selectedCount: selectedActivities.count)

			if showActivities {
				LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
					ForEach(activitiesOptions, id: \.self) { activity in
						tagButton(title: activity, isSelected: selectedActivities.contains(activity)) {
							toggle(selected: &selectedActivities, value: activity)
						}
					}
				}
			}
		}
	}

	private var audioSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Audio")
				.font(.system(size: 16, weight: .bold, design: .rounded))
				.foregroundColor(titleText)

			Button(action: { showVoiceRecording = true }) {
				HStack {
					Text("Record an audio journal")
						.font(.system(size: 16, weight: .semibold, design: .rounded))
						.foregroundColor(primaryText)
					Spacer()
					Image(systemName: "mic.fill")
						.font(.system(size: 16, weight: .bold))
						.foregroundColor(titleText)
						.frame(width: 44, height: 44)
						.background(iconBg)
						.clipShape(Circle())
				}
				.padding(.horizontal, 20)
				.padding(.vertical, 16)
				.background(cardBg)
				.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
				.shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
			}
			.buttonStyle(.plain)
		}
	}

	private var photoSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Photo")
				.font(.system(size: 16, weight: .bold, design: .rounded))
				.foregroundColor(titleText)

			Button(action: { showPhotoPicker = true }) {
				HStack {
					Text("Add a photo from your day")
						.font(.system(size: 16, weight: .semibold, design: .rounded))
						.foregroundColor(primaryText)
					Spacer()
					Image(systemName: "plus")
						.font(.system(size: 16, weight: .bold))
						.foregroundColor(titleText)
						.frame(width: 44, height: 44)
						.background(iconBg)
						.clipShape(Circle())
				}
				.padding(.horizontal, 20)
				.padding(.vertical, 16)
				.background(cardBg)
				.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
				.shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
			}
			.buttonStyle(.plain)

			if !selectedImages.isEmpty {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: 12) {
						ForEach(selectedImages.indices, id: \.self) { index in
							Image(uiImage: selectedImages[index])
								.resizable()
								.scaledToFill()
								.frame(width: 88, height: 88)
								.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
						}
					}
				}
			}
		}
	}

	private var saveButton: some View {
		Button(action: saveEntry) {
			Text(isLoading ? "Saving..." : (isEditMode ? "Save Changes" : "Save Entry"))
				.font(.system(size: 18, weight: .bold, design: .rounded))
				.foregroundColor(.white)
				.frame(maxWidth: .infinity)
				.frame(height: 58)
				.background(buttonBlue)
				.clipShape(Capsule())
				.shadow(color: buttonBlue.opacity(0.3), radius: 10, x: 0, y: 6)
		}
		.buttonStyle(.plain)
		.disabled(isLoading)
		.opacity(isLoading ? 0.7 : 1)
	}

	private var titleSection: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text("Title")
				.font(.system(size: 16, weight: .bold, design: .rounded))
				.foregroundColor(titleText)

			TextField("Give this entry a title", text: $title)
				.font(.system(size: 18, weight: .semibold, design: .rounded))
				.foregroundColor(primaryText)
		}
	}

	private var datePickerSheet: some View {
		ZStack {
			bgMain
				.ignoresSafeArea()

			VStack(spacing: 0) {
				HStack(alignment: .top, spacing: 16) {
					VStack(alignment: .leading, spacing: 4) {
						Text("Select Date")
							.font(.system(size: 28, weight: .bold, design: .rounded))
							.foregroundColor(.white)
						Text("& Time")
							.font(.system(size: 28, weight: .bold, design: .rounded))
							.foregroundColor(.white)
					}
					Spacer()
					Button(action: { showDatePickerSheet = false }) {
						Text("Done")
							.font(.system(size: 16, weight: .semibold, design: .rounded))
							.foregroundColor(.white)
							.padding(.horizontal, 24)
							.padding(.vertical, 10)
							.background(
								RoundedRectangle(cornerRadius: 24)
									.stroke(Color.white.opacity(0.3), lineWidth: 1.5)
							)
					}
				}
				.padding(.horizontal, 20)
				.padding(.top, 20)
				.padding(.bottom, 24)

				ScrollView(showsIndicators: false) {
					VStack(alignment: .leading, spacing: 28) {
						calendarSection
						timeSectionDatePicker
					}
					.padding(.horizontal, 20)
					.padding(.bottom, 20)
				}
			}
		}
	}

	private var calendarSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack {
				Button(action: previousMonth) {
					Image(systemName: "chevron.left")
						.font(.system(size: 18, weight: .semibold))
						.foregroundColor(buttonBlue)
				}
				.buttonStyle(.plain)

				Text(dateFormatter.string(from: selectedDate))
					.font(.system(size: 18, weight: .semibold, design: .rounded))
					.foregroundColor(.white)

				Button(action: nextMonth) {
					Image(systemName: "chevron.right")
						.font(.system(size: 18, weight: .semibold))
						.foregroundColor(buttonBlue)
				}
				.buttonStyle(.plain)

				Spacer()
			}

			calendarGrid
		}
	}

	private var calendarGrid: some View {
		let columns = Array(repeating: GridItem(.flexible()), count: 7)
		let days = daysInMonth(for: selectedDate)

		return VStack(spacing: 12) {
			HStack(spacing: 0) {
				ForEach(["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"], id: \.self) { day in
					Text(day)
						.font(.system(size: 12, weight: .semibold, design: .rounded))
						.foregroundColor(Color.white.opacity(0.6))
						.frame(maxWidth: .infinity)
						.frame(height: 32)
				}
			}

			LazyVGrid(columns: columns, spacing: 12) {
				ForEach(Array(days.enumerated()), id: \.offset) { _, day in
					if day.day == -1 {
						Color.clear
							.frame(height: 44)
					} else {
						let date = Calendar.current.date(byAdding: .day, value: day.day - 1, to: firstDayOfMonth(selectedDate)) ?? selectedDate
						let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
						let isFutureDate = date > Calendar.current.startOfDay(for: Date())

						Button(action: {
							var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: selectedDate)
							let dayComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
							components.day = dayComponents.day
							components.month = dayComponents.month
							components.year = dayComponents.year
							if let newDate = Calendar.current.date(from: components), !isFutureDay(newDate) {
								selectedDate = clampedDateForToday(newDate)
							}
						}) {
							Text("\(day.day)")
								.font(.system(size: 16, weight: .semibold, design: .rounded))
								.foregroundColor(isFutureDate ? Color.white.opacity(0.3) : .white)
								.frame(maxWidth: .infinity)
								.frame(height: 44)
								.background(
									Circle()
										.fill(isSelected && !isFutureDate ? buttonBlue : Color.clear)
								)
						}
						.buttonStyle(.plain)
						.disabled(isFutureDate)
					}
				}
			}
		}
	}

	private var timeSectionDatePicker: some View {
		let isToday = Calendar.current.isDateInToday(selectedDate)

		return VStack(alignment: .leading, spacing: 16) {
			Text("Time")
				.font(.system(size: 16, weight: .semibold, design: .rounded))
				.foregroundColor(.white)

			HStack {
				Spacer()
				if isToday {
					DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: [.hourAndMinute])
						.datePickerStyle(.wheel)
						.labelsHidden()
						.frame(height: 150)
						.frame(maxWidth: 200)
				} else {
					DatePicker("", selection: $selectedDate, displayedComponents: [.hourAndMinute])
						.datePickerStyle(.wheel)
						.labelsHidden()
						.frame(height: 150)
						.frame(maxWidth: 200)
				}
				Spacer()
			}
		}
		.padding(.bottom, 16)
	}

	private func daysInMonth(for date: Date) -> [(day: Int, offset: Int)] {
		let calendar = Calendar.current
		let range = calendar.range(of: .day, in: .month, for: date)!
		let numDays = range.count
		let firstOfMonth = firstDayOfMonth(date)
		let startingWeekday = calendar.component(.weekday, from: firstOfMonth) - 1

		var days: [(Int, Int)] = []
		for i in 0..<startingWeekday {
			days.append((-1, i))
		}
		for day in 1...numDays {
			days.append((day, startingWeekday + day - 1))
		}
		return days
	}

	private func firstDayOfMonth(_ date: Date) -> Date {
		let calendar = Calendar.current
		let components = calendar.dateComponents([.year, .month], from: date)
		return calendar.date(from: components) ?? date
	}

	private func previousMonth() {
		if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
			selectedDate = clampedDateForToday(newDate)
		}
	}

	private func nextMonth() {
		if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
			selectedDate = clampedDateForToday(newDate)
		}
	}

	private let dateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMMM yyyy"
		return formatter
	}()

	@ViewBuilder
	private func expandableCard(title: String, isExpanded: Binding<Bool>, selectedCount: Int) -> some View {
		Button(action: {
			withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
				isExpanded.wrappedValue.toggle()
			}
		}) {
			HStack {
				Text(title)
					.font(.system(size: 16, weight: .semibold, design: .rounded))
					.foregroundColor(primaryText)
					.multilineTextAlignment(.leading)

				Spacer()

				if selectedCount > 0 {
					Text("\(selectedCount)")
						.font(.system(size: 14, weight: .bold, design: .rounded))
						.foregroundColor(.white)
						.frame(width: 24, height: 24)
						.background(buttonBlue)
						.clipShape(Circle())
						.padding(.trailing, 4)
				}

				Image(systemName: isExpanded.wrappedValue ? "minus" : "plus")
					.font(.system(size: 16, weight: .bold))
					.foregroundColor(titleText)
					.frame(width: 44, height: 44)
					.background(iconBg)
					.clipShape(Circle())
			}
			.padding(.horizontal, 20)
			.padding(.vertical, 16)
			.background(cardBg)
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
		}
		.buttonStyle(.plain)
	}

	@ViewBuilder
	private func tagButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			Text(title)
				.font(.system(size: 15, weight: .semibold, design: .rounded))
				.foregroundColor(isSelected ? .white : primaryText)
				.frame(maxWidth: .infinity, minHeight: 44)
				.background(isSelected ? buttonBlue : cardBg)
				.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
				.overlay(
					RoundedRectangle(cornerRadius: 16, style: .continuous)
						.stroke(isSelected ? Color.clear : .black.opacity(0.05), lineWidth: 1)
				)
		}
		.buttonStyle(.plain)
	}

	private func toggle(selected: inout Set<String>, value: String) {
		if selected.contains(value) {
			selected.remove(value)
		} else {
			selected.insert(value)
		}
	}

	private func formattedTime(from date: Date) -> String {
		let formatter = DateFormatter()
		if Calendar.current.isDateInToday(date) {
			formatter.dateFormat = "'Today,' HH:mm"
		} else if Calendar.current.isDateInYesterday(date) {
			formatter.dateFormat = "'Yesterday,' HH:mm"
		} else {
			formatter.dateFormat = "MMM d, HH:mm"
		}
		return formatter.string(from: date)
	}

	private func saveEntry() {
		isLoading = true
		Task {
			let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
			let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
			let titleToSave = trimmedTitle.isEmpty ? "Note" : trimmedTitle
			let contentToSave = trimmedNote.isEmpty ? "(No note)" : trimmedNote
			selectedDate = clampedDateForToday(selectedDate)
			do {
				let targetJournalId = journalToEdit?.id ?? UUID()
				var uploadedImageUrls = try await uploadSelectedImages(journalId: targetJournalId)
				
				// Handle voice recording upload if present
				if let voiceURL = voiceRecordingURL {
					let voiceData = try Data(contentsOf: voiceURL)
					let voicePublicUrl = try await viewModel.uploadMedia(journalId: targetJournalId, fileData: voiceData, fileName: voiceURL.lastPathComponent)
					uploadedImageUrls.append(voicePublicUrl)
				}

				if let journal = journalToEdit {
					let mergedTags: [String] = []
					let mergedMediaUrls = Array(Set(journal.mediaUrls + uploadedImageUrls))
					try await viewModel.updateJournal(
						id: journal.id,
						title: titleToSave,
						content: contentToSave,
						emotion: moodLabel,
						tags: mergedTags,
						mediaUrls: mergedMediaUrls,
						createdAt: selectedDate
					)
					let updatedJournal = DBJournal(
						id: journal.id,
						userId: journal.userId,
						title: titleToSave,
						content: contentToSave,
						emotion: moodLabel,
						tags: mergedTags,
						mediaUrls: mergedMediaUrls,
						isFavorite: journal.isFavorite,
						entryType: journal.entryType,
						voiceRecordingUrl: voiceRecordingURL?.lastPathComponent,
						transcriptionText: journal.transcriptionText,
						feelings: Array(selectedFeelings),
						activities: Array(selectedActivities),
						createdAt: ISO8601DateFormatter().string(from: selectedDate),
						updatedAt: ISO8601DateFormatter().string(from: Date())
					)
					await MainActor.run {
						isLoading = false
						onSaveCompleted?(updatedJournal)
						dismiss()
					}
				} else {
					let created = try await viewModel.createJournal(
						title: titleToSave,
						content: contentToSave,
						emotion: moodLabel,
						tags: [],
						mediaUrls: uploadedImageUrls,
						isFavorite: false,
						feelings: Array(selectedFeelings),
						activities: Array(selectedActivities),
						createdAt: selectedDate,
						journalId: targetJournalId
					)
					await MainActor.run {
						isLoading = false
						onSaveCompleted?(created)
						dismiss()
					}
				}
			} catch {
				await MainActor.run {
					isLoading = false
					statusMessage = "Could not save: \(error.localizedDescription)"
					showStatusAlert = true
				}
			}
		}
	}

	private func moodIndex(from emotion: String) -> Int {
		switch emotion.lowercased() {
		case "unhappy", "sad", "angry":
			return 0
		case "low", "down":
			return 1
		case "okay", "neutral", "stressed", "anxious":
			return 2
		case "good", "calm":
			return 3
		default:
			return 4
		}
	}

	private func isFutureDay(_ date: Date) -> Bool {
		Calendar.current.startOfDay(for: date) > Calendar.current.startOfDay(for: Date())
	}

	private func clampedDateForToday(_ date: Date) -> Date {
		if Calendar.current.isDateInToday(date) {
			return min(date, Date())
		}
		return date
	}

	private func optimizedImageData(from image: UIImage) -> Data? {
		let resized = resizedImageIfNeeded(image, maxDimension: 1600)
		let targetMaxBytes = 900_000
		let qualitySteps: [CGFloat] = [0.8, 0.7, 0.6, 0.5, 0.45]

		for quality in qualitySteps {
			if let data = resized.jpegData(compressionQuality: quality), data.count <= targetMaxBytes {
				return data
			}
		}

		// Fallback for very large photos: downscale more aggressively.
		let aggressiveResize = resizedImageIfNeeded(resized, maxDimension: 1200)
		return aggressiveResize.jpegData(compressionQuality: 0.5)
	}

	private func resizedImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
		let originalSize = image.size
		let longestSide = max(originalSize.width, originalSize.height)

		guard longestSide > maxDimension else { return image }

		let scale = maxDimension / longestSide
		let newSize = CGSize(width: originalSize.width * scale, height: originalSize.height * scale)
		let renderer = UIGraphicsImageRenderer(size: newSize)

		return renderer.image { _ in
			image.draw(in: CGRect(origin: .zero, size: newSize))
		}
	}

	private func uploadSelectedImages(journalId: UUID) async throws -> [String] {
		guard !selectedImages.isEmpty else { return [] }

		var uploadedUrls: [String] = []
		for (index, image) in selectedImages.enumerated() {
			guard let data = optimizedImageData(from: image) else { continue }
			let fileName = "photo_\(index)_\(Int(Date().timeIntervalSince1970)).jpg"
			let publicUrl = try await viewModel.uploadMedia(
				journalId: journalId,
				fileData: data,
				fileName: fileName,
				contentType: "image/jpeg"
			)
			uploadedUrls.append(publicUrl)
		}

		return uploadedUrls
	}
}

#Preview {
	AddJournalView()
}
