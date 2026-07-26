import test from "node:test";
import assert from "node:assert/strict";
import { renderFormula, validateSpec } from "../scripts/formula-generator.mjs";
const base = { version: 1, repo: "afterdarksys/tool", tag: "v1.2.3", formula: "tool", class: "Tool", description: "Useful command line tool", license: "MIT" };
const sha = "a".repeat(64);
test("renders bounded recipes for supported build kinds", () => {
  const cases = [
    [{ kind: "go", target: "./cmd/tool", binary: "tool" }, /std_go_args/],
    [{ kind: "rust", binary: "tool" }, /cargo.*--release/],
    [{ kind: "cmake", binary: "tool" }, /std_cmake_args/],
    [{ kind: "make", binary: "tool" }, /system "make"/],
    [{ kind: "autotools", binary: "tool" }, /std_configure_args/],
    [{ kind: "script", executable: "bin/tool" }, /write_exec_script/],
    [{ kind: "node-script", executable: "bin/tool.js" }, /depends_on "node"/],
    [{ kind: "python-script", executable: "bin/tool.py", python: "python@3.14" }, /depends_on "python@3.14"/],
  ];
  for (const item of cases) assert.match(renderFormula({ ...base, build: item[0] }, sha), item[1]);
});
test("rejects unsafe paths and arbitrary build commands", () => {
  assert.throws(() => validateSpec({ ...base, build: { kind: "go", target: "../cmd/tool", binary: "tool" } }), /unsafe/);
  assert.throws(() => validateSpec({ ...base, build: { kind: "shell", command: "anything" } }), /unsupported/);
});
