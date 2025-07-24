import XCTest
@testable import Droppy

final class AuthenticationTests: XCTestCase {
//    private var mockService: MockAuthenticationService!
//    private var viewModel: AuthenticationViewModel!
//    
//    @MainActor
//    override func setUp() {
//        super.setUp()
//        mockService = AuthenticationTestDataFactory.createMockAuthenticationService()
//        viewModel = AuthenticationViewModel(authService: mockService)
//    }
//    
//    override func tearDown() {
//        mockService = nil
//        viewModel = nil
//        super.tearDown()
//    }
//    
//    // MARK: - Sign In Tests
//    
//    @MainActor
//    func test_signIn_whenValidCredentials_thenSignsInSuccessfully() async {
//        let expectedUser = AuthenticationTestDataFactory.createMockUser(isOnboardingCompleted: true)
//        mockService.signInResult = .success(expectedUser)
//        
//        let credentials = AuthenticationTestDataFactory.createValidEmailPassword()
//        viewModel.email = credentials.email
//        viewModel.password = credentials.password
//        
//        await viewModel.signIn()
//        
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertNil(viewModel.errorMessage)
//        XCTAssertEqual(viewModel.currentUser, expectedUser)
//        XCTAssertTrue(viewModel.isAuthenticated)
//        XCTAssertFalse(viewModel.shouldShowOnboarding)
//    }
//    
//    @MainActor
//    func test_signIn_whenInvalidEmail_thenShowsErrorMessage() async {
//        mockService.signInResult = .failure(.invalidEmail)
//        
//        let credentials = AuthenticationTestDataFactory.createInvalidEmailPassword()
//        viewModel.email = credentials.email
//        viewModel.password = "validpassword"
//        
//        await viewModel.signIn()
//        
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertEqual(viewModel.errorMessage, AuthenticationError.invalidEmail.localizedDescription)
//        XCTAssertNil(viewModel.currentUser)
//        XCTAssertFalse(viewModel.isAuthenticated)
//    }
//    
//    @MainActor
//    func test_signIn_whenEmptyFields_thenShowsValidationError() async {
//        viewModel.email = ""
//        viewModel.password = ""
//        
//        await viewModel.signIn()
//        
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertEqual(viewModel.errorMessage, "Email ve şifre alanları boş olamaz")
//        XCTAssertFalse(mockService.signInCalled)
//    }
//    
//    // MARK: - Sign Up Tests
//    
//    @MainActor
//    func test_signUp_whenValidCredentials_thenSignsUpSuccessfully() async {
//        let expectedUser = AuthenticationTestDataFactory.createMockUser(isOnboardingCompleted: false)
//        mockService.signUpResult = .success(expectedUser)
//        
//        let credentials = AuthenticationTestDataFactory.createValidEmailPassword()
//        viewModel.email = credentials.email
//        viewModel.password = credentials.password
//        
//        await viewModel.signUp()
//        
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertNil(viewModel.errorMessage)
//        XCTAssertEqual(viewModel.currentUser, expectedUser)
//        XCTAssertTrue(viewModel.isAuthenticated)
//        XCTAssertTrue(viewModel.shouldShowOnboarding)
//    }
//    
//    @MainActor
//    func test_signUp_whenEmailAlreadyExists_thenShowsErrorMessage() async {
//        mockService.signUpResult = .failure(.emailAlreadyExists)
//        
//        let credentials = AuthenticationTestDataFactory.createValidEmailPassword()
//        viewModel.email = credentials.email
//        viewModel.password = credentials.password
//        
//        await viewModel.signUp()
//        
//        XCTAssertFalse(viewModel.isLoading)
//        XCTAssertEqual(viewModel.errorMessage, AuthenticationError.emailAlreadyExists.localizedDescription)
//        XCTAssertNil(viewModel.currentUser)
//        XCTAssertFalse(viewModel.isAuthenticated)
//    }
//    
//    // MARK: - Authentication Mode Tests
//    
//    @MainActor
//    func test_switchAuthenticationMode_whenSignIn_thenSwitchesToSignUp() {
//        XCTAssertEqual(viewModel.authenticationMode, .signIn)
//        
//        viewModel.switchAuthenticationMode()
//        
//        XCTAssertEqual(viewModel.authenticationMode, .signUp)
//    }
//    
//    @MainActor
//    func test_switchAuthenticationMode_whenSignUp_thenSwitchesToSignIn() {
//        viewModel.switchAuthenticationMode() // Switch to SignUp first
//        XCTAssertEqual(viewModel.authenticationMode, .signUp)
//        
//        viewModel.switchAuthenticationMode()
//        
//        XCTAssertEqual(viewModel.authenticationMode, .signIn)
//    }
//    
//    // MARK: - Form Validation Tests
//    
//    @MainActor
//    func test_isFormValid_whenValidInputs_thenReturnsTrue() {
//        let credentials = AuthenticationTestDataFactory.createValidEmailPassword()
//        viewModel.email = credentials.email
//        viewModel.password = credentials.password
//        
//        XCTAssertTrue(viewModel.isFormValid)
//    }
//    
//    @MainActor
//    func test_isFormValid_whenInvalidEmail_thenReturnsFalse() {
//        viewModel.email = "invalid-email"
//        viewModel.password = "validpassword"
//        
//        XCTAssertFalse(viewModel.isFormValid)
//    }
//    
//    @MainActor
//    func test_isFormValid_whenShortPassword_thenReturnsFalse() {
//        viewModel.email = "test@example.com"
//        viewModel.password = "12345"
//        
//        XCTAssertFalse(viewModel.isFormValid)
//    }
//    
//    // MARK: - UI State Tests
//    
//    @MainActor
//    func test_screenTitle_whenSignInMode_thenReturnsSignInTitle() {
//        XCTAssertEqual(viewModel.authenticationMode, .signIn)
//        XCTAssertEqual(viewModel.screenTitle, "Giriş Yap")
//    }
//    
//    @MainActor
//    func test_screenTitle_whenSignUpMode_thenReturnsSignUpTitle() {
//        viewModel.switchAuthenticationMode()
//        XCTAssertEqual(viewModel.authenticationMode, .signUp)
//        XCTAssertEqual(viewModel.screenTitle, "Hesap Oluştur")
//    }
//    
//    @MainActor
//    func test_showPasswordHint_whenSignUpMode_thenReturnsTrue() {
//        viewModel.switchAuthenticationMode()
//        XCTAssertTrue(viewModel.showPasswordHint)
//    }
//    
//    @MainActor
//    func test_showPasswordHint_whenSignInMode_thenReturnsFalse() {
//        XCTAssertFalse(viewModel.showPasswordHint)
//    }
}