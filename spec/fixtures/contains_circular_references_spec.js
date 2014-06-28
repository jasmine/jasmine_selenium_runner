it("handles circular references", function() {
  var objA = {};
  var objB = {back_reference: objA};
  objA.back_reference = objB;

  expect(objA).not.toBe(objA);
});
