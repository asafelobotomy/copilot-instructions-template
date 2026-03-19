---
description: "Systematic Java debugging workflow — stack traces, debugger, dependency issues, fix, verify"
agent: copilot
---

# Java Debug

Systematic debugging workflow for Java issues.

## Steps

1. **Reproduce** — get the exact error:
   - Compile errors: `mvn compile` or `./gradlew compileJava` — read the diagnostic
   - Test failures: `mvn test -pl module -Dtest=TestClass#testMethod` or `./gradlew test --tests TestClass.testMethod`
   - Runtime exceptions: read the full stack trace including the caused-by chain

2. **Isolate** — narrow the scope:
   - Read the stack trace bottom-up — find the first frame in your code
   - Check if it's a compile error, runtime exception, or test assertion failure
   - For `NullPointerException`: enable helpful NPE messages (`-XX:+ShowCodeDetailsInExceptionMessages`)
   - For `ClassNotFoundException`/`NoSuchMethodError`: check dependency versions (`mvn dependency:tree`)

3. **Inspect** — gather state:
   - Use the IDE debugger with breakpoints and conditional breakpoints
   - Check for null values, missing Spring beans, or incorrect configuration
   - Verify file paths, resource locations, and classpath entries
   - Check for transaction boundaries if dealing with database issues

4. **Fix** — make the minimal change:
   - Fix the root cause, not the symptom
   - Write a JUnit test that fails before the fix
   - Check for ripple effects in related classes

5. **Verify** — confirm the fix:
   - `mvn verify` or `./gradlew build` — full build passes
   - `mvn test` or `./gradlew test` — all tests pass
   - Check for deprecation warnings in the build output
   - Run static analysis if configured (SpotBugs, PMD, Checkstyle)
