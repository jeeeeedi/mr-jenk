# JUnit Testing Quick Reference Guide

## 🚀 Quick Start

### Run All Tests
```bash
mvn clean test
```

### Run Single Service Tests
```bash
# User Service
mvn clean test --projects user-service

# Product Service
mvn clean test --projects product-service

# Media Service
mvn clean test --projects media-service

# API Gateway
mvn clean test --projects api-gateway
```

### Run Specific Test Class
```bash
mvn test -Dtest=UserServiceTest
mvn test -Dtest=ProductServiceTest
mvn test -Dtest=JwtServiceTest
```

### Run Specific Test Method
```bash
mvn test -Dtest=UserServiceTest#testGetProfile
```

## 📋 Test File Locations

```
user-service/src/test/java/ax/gritlab/buy_01/user/service/
├── UserServiceTest.java          (6 tests)
└── JwtServiceTest.java           (7 tests)

product-service/src/test/java/ax/gritlab/buy_01/product/service/
└── ProductServiceTest.java       (9 tests)

media-service/src/test/java/ax/gritlab/buy_01/media/service/
└── MediaServiceTest.java         (8 tests)

api-gateway/src/test/java/ax/gritlab/buy_01/apigateway/
└── ApiGatewayApplicationTest.java (3 tests)
```

## 💡 Understanding the Test Structure

### Basic Test Template
```java
@ExtendWith(MockitoExtension.class)
@DisplayName("Service Unit Tests")
public class YourServiceTest {

    @Mock
    private DependencyService dependency;

    @InjectMocks
    private YourService service;

    @BeforeEach
    void setUp() {
        // Initialize test data
    }

    @Test
    @DisplayName("Should do something meaningful")
    void testYourMethod() {
        // Arrange - Set up test conditions
        
        // Act - Execute the method
        
        // Assert - Verify the results
    }
}
```

## 🔍 Common Assertions & Mockito Patterns

### Assertions
```java
// Value assertions
assertEquals(expected, actual);
assertNotNull(result);
assertNull(result);
assertTrue(condition);
assertFalse(condition);

// Exception assertions
assertThrows(Exception.class, () -> service.methodThatThrows());

// Collection assertions
assertTrue(list.contains(item));
assertEquals(expectedSize, list.size());
```

### Mockito Patterns
```java
// Setup mock behavior
when(dependency.method()).thenReturn(value);
when(dependency.method(argument)).thenReturn(value);

// Verify interactions
verify(dependency, times(1)).method();
verify(dependency, never()).method();
verify(dependency, atLeastOnce()).method();

// Setup void methods
doNothing().when(dependency).voidMethod();
doThrow(Exception.class).when(dependency).voidMethod();
```

## ✍️ Writing a New Test

### Example: Testing a Service Method

```java
@Test
@DisplayName("Should update user profile successfully")
void testUpdateProfile() {
    // Arrange
    UpdateProfileRequest request = new UpdateProfileRequest();
    request.setName("New Name");
    
    User existingUser = new User();
    existingUser.setId("user123");
    
    when(userRepository.save(any(User.class)))
        .thenReturn(existingUser);

    // Act
    UserProfileResponse response = userService.updateProfile(existingUser, request);

    // Assert
    assertNotNull(response);
    assertEquals("user123", response.getId());
    verify(userRepository, times(1)).save(any(User.class));
}
```

## 🎯 Testing Best Practices

### 1. Test Naming
Use clear, descriptive names that explain what's being tested:
```java
❌ testUpdate()              // Too vague
✅ testUpdateProfileSuccessfully()
✅ testUpdateProfileThrowsExceptionWhenUnauthorized()
```

### 2. Arrange-Act-Assert Pattern
```java
// Good structure
@Test
void testSomething() {
    // ARRANGE - Setup test data and mocks
    User user = new User();
    user.setId("123");
    
    // ACT - Execute the method being tested
    User result = service.getUser("123");
    
    // ASSERT - Verify the results
    assertEquals("123", result.getId());
}
```

### 3. One Assertion Focus
```java
❌ // Testing too many things
assertEquals(expected1, actual1);
assertEquals(expected2, actual2);
assertEquals(expected3, actual3);

✅ // One main assertion per test
assertEquals(expectedId, result.getId());
// Supporting assertions ok
assertNotNull(result);
```

### 4. Use @BeforeEach for Common Setup
```java
@BeforeEach
void setUp() {
    testUser = new User();
    testUser.setId("user123");
    testUser.setEmail("test@example.com");
}
```

## 🐛 Debugging Tests

### Run with Debug Output
```bash
mvn test -X
```

### Run Single Test with Debug
```bash
mvn test -Dtest=UserServiceTest#testGetProfile -X
```

### View Test Reports
After running tests, check the report:
```bash
cat target/surefire-reports/UserServiceTest.txt
```

## 🔧 Common Issues & Solutions

### Issue: "Cannot find symbol" for dependencies
**Solution**: Make sure all required test dependencies are in pom.xml:
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

### Issue: Mockito not initializing mocks
**Solution**: Add `@ExtendWith(MockitoExtension.class)` to test class:
```java
@ExtendWith(MockitoExtension.class)
public class MyServiceTest {
    @Mock
    private Dependency dependency;
}
```

### Issue: Test fails with NullPointerException
**Solution**: Check that all @Mock fields are initialized in @BeforeEach:
```java
@BeforeEach
void setUp() {
    testObject = new TestObject();
}
```

## 📚 Current Test Coverage

| Service | Tests | Status |
|---------|-------|--------|
| user-service | 13 | ✅ All Pass |
| product-service | 9 | ✅ All Pass |
| media-service | 8 | ✅ All Pass |
| api-gateway | 3 | ✅ All Pass |
| **Total** | **33** | **✅ All Pass** |

## 🔗 Useful Resources
- [JUnit 5 Documentation](https://junit.org/junit5/docs/current/user-guide/)
- [Mockito Documentation](https://javadoc.io/doc/org.mockito/mockito-core/latest/org.mockito/org/mockito/Mockito.html)
- [Spring Boot Testing Guide](https://spring.io/guides/gs/testing-web/)
- [AssertJ Assertions](https://assertj.github.io/assertj-core/)
