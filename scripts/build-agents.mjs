#!/usr/bin/env node
/**
 * Render per-tool AGENTS.md files from AGENTS.template.md.
 *
 * Run from the repo root (agents-config/):
 *   node scripts/build-agents.mjs
 */
import { readFile, writeFile, mkdir, readdir } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = resolve(__dirname, '..');

async function loadConfig(toolDir) {
  const varsPath = join(toolDir, 'vars.mjs');
  const { default: config } = await import(pathToFileURL(varsPath));
  const builtInPath = join(toolDir, 'built-in-agents.md');
  let builtIn = '';
  try {
    builtIn = await readFile(builtInPath, 'utf8');
  } catch (err) {
    if (err.code !== 'ENOENT') throw err;
  }
  return {
    ...config,
    replacements: {
      ...config.replacements,
      BUILT_IN_AGENTS_SECTION: builtIn,
    },
  };
}

async function renderTool(template, toolName, config) {
  const output = resolve(root, config.output);
  const missing = [];
  const rendered = template.replace(/\{\{([A-Z_]+)\}\}/g, (match, key) => {
    if (key in config.replacements) {
      return config.replacements[key];
    }
    missing.push(key);
    return match;
  });

  if (missing.length) {
    console.error(`[${toolName}] missing replacements: ${missing.join(', ')}`);
    process.exitCode = 1;
  }

  await mkdir(dirname(output), { recursive: true });
  await writeFile(output, rendered, 'utf8');
  console.log(`rendered ${output}`);
}

async function main() {
  const templatePath = join(root, 'template.md');
  const template = await readFile(templatePath, 'utf8');

  const toolConfigsDir = join(root, 'tool-configs');
  const entries = await readdir(toolConfigsDir, { withFileTypes: true });
  const toolDirs = entries
    .filter((d) => d.isDirectory())
    .map((d) => join(toolConfigsDir, d.name));

  for (const toolDir of toolDirs) {
    const toolName = toolDir.split(/[\\/]/).pop();
    const config = await loadConfig(toolDir);
    await renderTool(template, toolName, config);
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
