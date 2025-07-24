import XCTest
@testable import Droppy

final class WelcomeTests: XCTestCase {
    private var viewModel: WelcomeViewModel!
    
    @MainActor
    override func setUp() {
        super.setUp()
        viewModel = WelcomeTestDataFactory.createWelcomeViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    @MainActor
    func test_init_thenSetsDefaultFeatures() {
        let expectedFeatures = WelcomeTestDataFactory.createDefaultFeatures()
        
        XCTAssertEqual(viewModel.features.count, expectedFeatures.count)
        XCTAssertEqual(viewModel.features.first?.title, expectedFeatures.first?.title)
        XCTAssertFalse(viewModel.shouldShowAuthentication)
    }
    
    @MainActor
    func test_init_thenSetsCorrectUIStrings() {
        XCTAssertEqual(viewModel.appTitle, "Stil Pusulası")
        XCTAssertEqual(viewModel.appSubtitle, "AI destekli gardırop asistanınız")
        XCTAssertEqual(viewModel.getStartedButtonTitle, "Başlayalım")
        XCTAssertEqual(viewModel.signInButtonTitle, "Zaten hesabım var")
    }
    
    // MARK: - Action Handling Tests
    
    @MainActor
    func test_handleAction_whenGetStarted_thenShowsAuthentication() {
        XCTAssertFalse(viewModel.shouldShowAuthentication)
        
        viewModel.handleAction(.getStarted)
        
        XCTAssertTrue(viewModel.shouldShowAuthentication)
    }
    
    @MainActor
    func test_handleAction_whenSignIn_thenShowsAuthentication() {
        XCTAssertFalse(viewModel.shouldShowAuthentication)
        
        viewModel.handleAction(.signIn)
        
        XCTAssertTrue(viewModel.shouldShowAuthentication)
    }
    
    @MainActor
    func test_dismissAuthentication_whenCalled_thenHidesAuthentication() {
        viewModel.handleAction(.getStarted)
        XCTAssertTrue(viewModel.shouldShowAuthentication)
        
        viewModel.dismissAuthentication()
        
        XCTAssertFalse(viewModel.shouldShowAuthentication)
    }
    
    // MARK: - WelcomeFeature Model Tests
    
    func test_welcomeFeature_defaultFeatures_thenContainsExpectedFeatures() {
        let features = WelcomeFeature.defaultFeatures
        
        XCTAssertEqual(features.count, 3)
        
        XCTAssertEqual(features[0].title, "Fotoğraf Çek")
        XCTAssertEqual(features[0].iconName, "camera")
        XCTAssertFalse(features[0].description.isEmpty)
        
        XCTAssertEqual(features[1].title, "Akıllı Öneriler")
        XCTAssertEqual(features[1].iconName, "wand.and.rays")
        XCTAssertFalse(features[1].description.isEmpty)
        
        XCTAssertEqual(features[2].title, "Kişisel Stil")
        XCTAssertEqual(features[2].iconName, "heart")
        XCTAssertFalse(features[2].description.isEmpty)
    }
    
    // MARK: - WelcomeAction Enum Tests
    
    func test_welcomeAction_hasExpectedCases() {
        let getStartedAction: WelcomeAction = .getStarted
        let signInAction: WelcomeAction = .signIn
        
        XCTAssertNotNil(getStartedAction)
        XCTAssertNotNil(signInAction)
    }
}