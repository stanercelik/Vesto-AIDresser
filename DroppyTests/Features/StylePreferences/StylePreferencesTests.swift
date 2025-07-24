import XCTest
@testable import Droppy

final class StylePreferencesTests: XCTestCase {
//    private var mockService: MockAuthenticationService!
//    private var viewModel: StylePreferencesViewModel!
//    private let testUserId = UUID()
//    
//    @MainActor
//    override func setUp() {
//        super.setUp()
//        mockService = StylePreferencesTestDataFactory.createMockAuthenticationService()
//        viewModel = StylePreferencesViewModel(authService: mockService, userId: testUserId)
//    }
//    
//    override func tearDown() {
//        mockService = nil
//        viewModel = nil
//        super.tearDown()
//    }
//    
//    // MARK: - Selection Tests
//    
//    @MainActor
//    func test_toggleSelection_whenColorNotSelected_thenAddsToSelection() {
//        XCTAssertEqual(viewModel.state.currentStep, .colors)
//        XCTAssertFalse(viewModel.isSelected("Mavi"))
//        
//        viewModel.toggleSelection("Mavi")
//        
//        XCTAssertTrue(viewModel.isSelected("Mavi"))
//        XCTAssertTrue(viewModel.state.selectedColors.contains("Mavi"))
//    }
//    
//    @MainActor
//    func test_toggleSelection_whenColorSelected_thenRemovesFromSelection() {
//        viewModel.toggleSelection("Mavi")
//        XCTAssertTrue(viewModel.isSelected("Mavi"))
//        
//        viewModel.toggleSelection("Mavi")
//        
//        XCTAssertFalse(viewModel.isSelected("Mavi"))
//        XCTAssertFalse(viewModel.state.selectedColors.contains("Mavi"))
//    }
//    
//    @MainActor
//    func test_toggleSelection_whenOnStylesStep_thenUpdatesStylesSelection() {
//        viewModel.state.currentStep = .styles
//        
//        viewModel.toggleSelection("Casual")
//        
//        XCTAssertTrue(viewModel.isSelected("Casual"))
//        XCTAssertTrue(viewModel.state.selectedStyles.contains("Casual"))
//    }
//    
//    @MainActor
//    func test_toggleSelection_whenOnOccasionsStep_thenUpdatesOccasionsSelection() {
//        viewModel.state.currentStep = .occasions
//        
//        viewModel.toggleSelection("İş")
//        
//        XCTAssertTrue(viewModel.isSelected("İş"))
//        XCTAssertTrue(viewModel.state.selectedOccasions.contains("İş"))
//    }
//    
//    // MARK: - Navigation Tests
//    
//    @MainActor
//    func test_goToNextStep_whenOnColorsStep_thenMovesToStylesStep() {
//        XCTAssertEqual(viewModel.state.currentStep, .colors)
//        
//        viewModel.goToNextStep()
//        
//        XCTAssertEqual(viewModel.state.currentStep, .styles)
//    }
//    
//    @MainActor
//    func test_goToNextStep_whenOnStylesStep_thenMovesToOccasionsStep() {
//        viewModel.state.currentStep = .styles
//        
//        viewModel.goToNextStep()
//        
//        XCTAssertEqual(viewModel.state.currentStep, .occasions)
//    }
//    
//    @MainActor
//    func test_goToNextStep_whenOnLastStep_thenStaysOnSameStep() {
//        viewModel.state.currentStep = .occasions
//        
//        viewModel.goToNextStep()
//        
//        XCTAssertEqual(viewModel.state.currentStep, .occasions)
//    }
//    
//    @MainActor
//    func test_goToPreviousStep_whenOnStylesStep_thenMovesToColorsStep() {
//        viewModel.state.currentStep = .styles
//        
//        viewModel.goToPreviousStep()
//        
//        XCTAssertEqual(viewModel.state.currentStep, .colors)
//    }
//    
//    @MainActor
//    func test_goToPreviousStep_whenOnOccasionsStep_thenMovesToStylesStep() {
//        viewModel.state.currentStep = .occasions
//        
//        viewModel.goToPreviousStep()
//        
//        XCTAssertEqual(viewModel.state.currentStep, .styles)
//    }
//    
//    @MainActor
//    func test_goToPreviousStep_whenOnFirstStep_thenStaysOnSameStep() {
//        XCTAssertEqual(viewModel.state.currentStep, .colors)
//        
//        viewModel.goToPreviousStep()
//        
//        XCTAssertEqual(viewModel.state.currentStep, .colors)
//    }
//    
//    // MARK: - Form Validation Tests
//    
//    @MainActor
//    func test_isFormValid_whenHasMinimumSelections_thenReturnsTrue() {
//        viewModel.toggleSelection("Mavi")
//        
//        XCTAssertTrue(viewModel.isFormValid)
//    }
//    
//    @MainActor
//    func test_isFormValid_whenNoSelections_thenReturnsFalse() {
//        XCTAssertFalse(viewModel.isFormValid)
//    }
//    
//    @MainActor
//    func test_isFormValid_whenOnStylesStepWithSelections_thenReturnsTrue() {
//        viewModel.state.currentStep = .styles
//        viewModel.toggleSelection("Casual")
//        
//        XCTAssertTrue(viewModel.isFormValid)
//    }
//    
//    // MARK: - UI State Tests
//    
//    @MainActor
//    func test_primaryButtonTitle_whenNotLastStep_thenReturnsDevamEt() {
//        XCTAssertEqual(viewModel.state.currentStep, .colors)
//        XCTAssertFalse(viewModel.state.isLastStep)
//        
//        XCTAssertEqual(viewModel.primaryButtonTitle, "Devam Et")
//    }
//    
//    @MainActor
//    func test_primaryButtonTitle_whenLastStep_thenReturnsTamamla() {
//        viewModel.state.currentStep = .occasions
//        XCTAssertTrue(viewModel.state.isLastStep)
//        
//        XCTAssertEqual(viewModel.primaryButtonTitle, "Tamamla")
//    }
//    
//    @MainActor
//    func test_showBackButton_whenFirstStep_thenReturnsFalse() {
//        XCTAssertEqual(viewModel.state.currentStep, .colors)
//        XCTAssertFalse(viewModel.showBackButton)
//    }
//    
//    @MainActor
//    func test_showBackButton_whenNotFirstStep_thenReturnsTrue() {
//        viewModel.state.currentStep = .styles
//        XCTAssertTrue(viewModel.showBackButton)
//    }
//    
//    @MainActor
//    func test_currentOptions_whenColorsStep_thenReturnsColorOptions() {
//        XCTAssertEqual(viewModel.state.currentStep, .colors)
//        
//        let expectedColors = PreferenceStep.colors.options
//        XCTAssertEqual(viewModel.currentOptions, expectedColors)
//    }
//    
//    @MainActor
//    func test_currentStepDescription_whenColorsStep_thenReturnsColorDescription() {
//        XCTAssertEqual(viewModel.state.currentStep, .colors)
//        
//        XCTAssertEqual(viewModel.currentStepDescription, "En çok tercih ettiğin renkleri seç")
//    }
//    
//    // MARK: - Save Preferences Tests
//    
//    @MainActor
//    func test_savePreferencesAndComplete_whenValidState_thenSavesSuccessfully() async {
//        let filledState = StylePreferencesTestDataFactory.createFilledStylePreferencesState()
//        viewModel.state = filledState
//        mockService.saveStylePreferencesResult = .success(())
//        mockService.completeOnboardingResult = .success(())
//        
//        let result = await viewModel.savePreferencesAndComplete()
//        
//        XCTAssertTrue(result)
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertNil(viewModel.errorMessage)
//        XCTAssertTrue(mockService.saveStylePreferencesCalled)
//        XCTAssertTrue(mockService.completeOnboardingCalled)
//    }
//    
//    @MainActor
//    func test_savePreferencesAndComplete_whenSaveError_thenReturnsFalseWithError() async {
//        let filledState = StylePreferencesTestDataFactory.createFilledStylePreferencesState()
//        viewModel.state = filledState
//        mockService.saveStylePreferencesResult = .failure(.networkError)
//        
//        let result = await viewModel.savePreferencesAndComplete()
//        
//        XCTAssertFalse(result)
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertNotNil(viewModel.errorMessage)
//        XCTAssertTrue(mockService.saveStylePreferencesCalled)
//    }
//    
//    @MainActor
//    func test_savePreferencesAndComplete_whenNotLastStep_thenReturnsFalse() async {
//        viewModel.state.currentStep = .colors
//        viewModel.toggleSelection("Mavi")
//        
//        let result = await viewModel.savePreferencesAndComplete()
//        
//        XCTAssertFalse(result)
//        XCTAssertFalse(mockService.saveStylePreferencesCalled)
//    }
//    
//    @MainActor
//    func test_savePreferencesAndComplete_whenNoSelections_thenReturnsFalse() async {
//        viewModel.state.currentStep = .occasions
//        
//        let result = await viewModel.savePreferencesAndComplete()
//        
//        XCTAssertFalse(result)
//        XCTAssertFalse(mockService.saveStylePreferencesCalled)
//    }
}