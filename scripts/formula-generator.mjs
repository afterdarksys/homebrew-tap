#!/usr/bin/env node
import { readFileSync, writeFileSync } from "node:fs";

const kinds = new Set(["script", "node-script", "python-script", "go", "rust", "cmake", "make", "autotools"]);
const simple = /^[A-Za-z0-9._/-]+$/;
const fail = (message) => { throw new Error("formula spec: " + message); };
const exact = (value, keys) => value && typeof value === "object" && !Array.isArray(value) && Object.keys(value).every((key) => keys.includes(key));
const checked = (value, label, pattern) => {
  if (typeof value !== "string" || !value || !pattern.test(value)) fail("invalid " + label);
  return value;
};
const contained = (value, label) => {
  checked(value, label, simple);
  if (value.includes("..") || value.startsWith("/")) fail("unsafe " + label);
  return value;
};

export function validateSpec(spec) {
  if (!exact(spec, ["version", "repo", "tag", "formula", "class", "description", "license", "build"])) fail("unsupported top-level field");
  if (spec.version !== 1) fail("version must be 1");
  checked(spec.repo, "repo", /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/);
  checked(spec.tag, "tag", /^v[0-9]+[.][0-9]+[.][0-9]+([.-][A-Za-z0-9._-]+)?$/);
  checked(spec.formula, "formula", /^[a-z0-9][a-z0-9@._-]*$/);
  checked(spec.class, "class", /^[A-Z][A-Za-z0-9]*$/);
  if (typeof spec.description !== "string" || !spec.description || spec.description.includes('"') || spec.description.includes("\n")) fail("invalid description");
  checked(spec.license, "license", /^[A-Za-z0-9.-]+$/);
  if (!spec.build || !kinds.has(spec.build.kind)) fail("unsupported build kind");
  const b = spec.build;
  const required = b.kind === "go" ? ["kind", "target", "binary"]
    : ["rust", "cmake", "make", "autotools"].includes(b.kind) ? ["kind", "binary"]
      : b.kind === "python-script" ? ["kind", "executable", "python"] : ["kind", "executable"];
  if (!exact(b, required)) fail("unsupported build field for " + b.kind);
  if (b.kind === "go") { contained(b.target, "go target"); checked(b.binary, "binary", /^[A-Za-z0-9._-]+$/); }
  else if (["rust", "cmake", "make", "autotools"].includes(b.kind)) checked(b.binary, "binary", /^[A-Za-z0-9._-]+$/);
  else { contained(b.executable, "executable"); if (b.kind === "python-script") checked(b.python, "python dependency", /^python@[0-9]+[.][0-9]+$/); }
  return spec;
}

export function renderFormula(input, sha) {
  const s = validateSpec(input);
  checked(sha, "sha256", /^[a-f0-9]{64}$/);
  const b = s.build;
  const out = [
    "class " + s.class + " < Formula",
    '  desc "' + s.description + '"',
    '  homepage "https://github.com/' + s.repo + '"',
    '  url "https://github.com/' + s.repo + '/archive/refs/tags/' + s.tag + '.tar.gz"',
    '  sha256 "' + sha + '"',
    '  license "' + s.license + '"',
    "",
  ];
  if (b.kind === "node-script") out.push('  depends_on "node"', "");
  if (b.kind === "python-script") out.push('  depends_on "' + b.python + '"', "");
  if (b.kind === "go") out.push('  depends_on "go" => :build', "");
  if (b.kind === "rust") out.push('  depends_on "rust" => :build', "");
  if (b.kind === "cmake") out.push('  depends_on "cmake" => :build', "");
  out.push("  def install");
  if (["script", "node-script", "python-script"].includes(b.kind)) {
    out.push('    libexec.install Dir["*"]');
    if (b.kind === "node-script") {
      out.push('    (bin/"' + s.formula + '").write_env_script libexec/"' + b.executable + '",');
      out.push('      PATH: "#{Formula["node"].opt_bin}:#{ENV["PATH"]}"');
    } else if (b.kind === "python-script") {
      out.push('    (bin/"' + s.formula + '").write_env_script libexec/"' + b.executable + '",');
      out.push('      PATH: "#{Formula["' + b.python + '"].opt_bin}:#{ENV["PATH"]}"');
    } else out.push('    bin.write_exec_script libexec/"' + b.executable + '"');
  } else if (b.kind === "go") out.push('    system "go", "build", *std_go_args(ldflags: "-s -w"), "' + b.target + '"');
  else if (b.kind === "rust") { out.push('    system "cargo", "build", "--release", "--locked", "--bin", "' + b.binary + '"'); out.push('    bin.install "target/release/' + b.binary + '"'); }
  else if (b.kind === "cmake") { out.push('    system "cmake", "-S", ".", "-B", "build", *std_cmake_args'); out.push('    system "cmake", "--build", "build"'); out.push('    bin.install "build/' + b.binary + '"'); }
  else if (b.kind === "make") { out.push('    system "make"'); out.push('    bin.install "' + b.binary + '"'); }
  else { out.push('    system "./configure", *std_configure_args'); out.push('    system "make", "install"'); }
  out.push("  end", "", "  test do", '    assert_predicate bin/"' + (b.binary || s.formula) + '", :executable?', "  end", "end", "");
  return out.join("\n");
}

function main(args) {
  const values = {};
  while (args.length) { const flag = args.shift(); const value = args.shift(); if (!value || !["--spec", "--sha256", "--output"].includes(flag)) fail("usage: formula-generator.mjs --spec file --sha256 hex --output Formula/name.rb"); values[flag] = value; }
  if (!values["--spec"] || !values["--sha256"] || !values["--output"]) fail("usage: formula-generator.mjs --spec file --sha256 hex --output Formula/name.rb");
  writeFileSync(values["--output"], renderFormula(JSON.parse(readFileSync(values["--spec"], "utf8")), values["--sha256"]));
}
if (process.argv[1] === new URL(import.meta.url).pathname) { try { main(process.argv.slice(2)); } catch (error) { process.stderr.write(error.message + "\n"); process.exitCode = 1; } }
