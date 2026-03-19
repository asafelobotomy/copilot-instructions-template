---
name: java-build-test
description: Java build and test patterns — Maven/Gradle configuration, JUnit 5 testing, Mockito mocking, and CI integration
---

# Java Build and Test

> Skill metadata: version "1.0"; license MIT; tags [java, maven, gradle, junit, mockito, testing]; recommended tools [codebase, runCommands, editFiles].

## When to use

- Setting up or modifying a Maven or Gradle build
- Writing or reviewing JUnit tests
- Configuring test coverage and CI integration
- Troubleshooting build or test failures

## Build system selection

| Signal | Choose |
|--------|--------|
| `pom.xml` present | Maven |
| `build.gradle` or `build.gradle.kts` present | Gradle |
| New project | Gradle with Kotlin DSL (modern, type-safe) |

## Maven conventions

### Project structure

```text
src/
  main/
    java/com/example/app/
      Application.java
    resources/
      application.yml
  test/
    java/com/example/app/
      ApplicationTest.java
    resources/
pom.xml
```

### Key commands

```bash
mvn clean verify            # Full build + tests
mvn test                    # Unit tests only
mvn dependency:tree         # Dependency tree
mvn versions:display-dependency-updates  # Check for updates
```

## Gradle conventions

### build.gradle.kts

```kotlin
plugins {
    java
    id("org.springframework.boot") version "3.3.0"
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}

dependencies {
    implementation("org.springframework.boot:spring-boot-starter-web")
    testImplementation("org.springframework.boot:spring-boot-starter-test")
}

tasks.test {
    useJUnitPlatform()
}
```

### Key commands

```bash
./gradlew build             # Full build + tests
./gradlew test              # Unit tests only
./gradlew dependencies      # Dependency tree
```

## JUnit 5 testing

### Basic test

```java
@DisplayName("UserService")
class UserServiceTest {

    private UserService service;

    @BeforeEach
    void setUp() {
        service = new UserService(new InMemoryUserRepo());
    }

    @Test
    @DisplayName("returns empty Optional for non-existent user")
    void findById_notFound() {
        Optional<User> result = service.findById("nonexistent");
        assertThat(result).isEmpty();
    }
}
```

### Parameterized tests

```java
@ParameterizedTest
@CsvSource({
    "hello, 5",
    "'', 0",
    "'  spaces  ', 10"
})
void testStringLength(String input, int expected) {
    assertThat(input.length()).isEqualTo(expected);
}
```

### Mockito

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private PaymentGateway gateway;

    @InjectMocks
    private OrderService service;

    @Test
    void processOrder_chargesGateway() {
        when(gateway.charge(any())).thenReturn(ChargeResult.success());

        service.processOrder(testOrder());

        verify(gateway).charge(argThat(charge ->
            charge.amount().equals(new BigDecimal("99.99"))
        ));
    }
}
```

### Assertions

- Use AssertJ (`assertThat`) over JUnit's built-in assertions for fluent, readable tests.
- Test exceptions: `assertThatThrownBy(() -> ...).isInstanceOf(IllegalArgumentException.class)`.

## Coverage

```bash
# Maven with JaCoCo
mvn verify   # JaCoCo report in target/site/jacoco/

# Gradle with JaCoCo
./gradlew jacocoTestReport
```
