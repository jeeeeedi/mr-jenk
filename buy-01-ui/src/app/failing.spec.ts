/**
 * INTENTIONAL FAILING TEST - For testing Jenkins pipeline failure behavior
 * DELETE THIS FILE after testing!
 */
describe('❌ INTENTIONAL FAILING TEST', () => {
  
  it('should FAIL on purpose to test Jenkins pipeline behavior', () => {
    // This test is designed to fail on purpose
    // to demonstrate how Jenkins handles test failures
    
    const expected = 42;
    const actual = 0;  // Wrong value!
    
    expect(actual).toBe(expected);
    // Error message: Expected 0 to be 42
    // DELETE failing.spec.ts after testing!
  });

});
