#!/usr/bin/env node
// Non-destructively merges this repo's opencode.json template into
// the live ~/.config/opencode/opencode.json config, without touching
// unrelated keys the user (or opencode itself) may have added.
import fs from "node:fs";
import path from "node:path";
import os from "node:os";

const [, , templatePath, targetPath] = process.argv;

if (!templatePath || !targetPath) {
  console.error("Usage: merge-json.mjs <template.json> <target.json>");
  process.exit(1);
}

function readJson(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const raw = fs.readFileSync(filePath, "utf8").trim();
  return raw ? JSON.parse(raw) : {};
}

// Expands the literal token "$HOME" inside string values so the template
// stays portable across machines/users.
function expandHome(value) {
  const home = os.homedir();
  if (typeof value === "string") return value.replaceAll("$HOME", home);
  if (Array.isArray(value)) return value.map(expandHome);
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, expandHome(v)]));
  }
  return value;
}

const template = expandHome(readJson(templatePath));
const target = readJson(targetPath);

// Deep merge: for each top-level key the template owns, overwrite/merge it
// into the target. Keys not present in the template are left untouched.
// - Scalar/array keys from template win (model, permission, instructions,
//   $schema, small_model, default_agent, etc.).
// - Object keys (mcp, agent, provider, command, skills, references) are
//   shallow-merged per-server/per-name so user-added entries survive.
const objectMergeKeys = new Set(["mcp", "agent", "provider", "command", "skills", "references", "permission"]);

for (const [key, value] of Object.entries(template)) {
  if (objectMergeKeys.has(key) && value && typeof value === "object" && !Array.isArray(value)) {
    if (key === "permission" && typeof value === "string") {
      target[key] = value;
    } else {
      target[key] = { ...(target[key] || {}), ...value };
    }
  } else {
    target[key] = value;
  }
}

fs.mkdirSync(path.dirname(targetPath), { recursive: true });
fs.writeFileSync(targetPath, JSON.stringify(target, null, 2) + "\n");
console.log(`Updated ${targetPath}`);
