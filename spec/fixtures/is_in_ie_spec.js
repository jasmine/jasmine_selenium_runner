describe("browser-specific spec that proves we're running in a browser", function() {
  it("should be in IE", function() {
    expect(navigator.userAgent).toMatch(/MSIE/)
  });
});
