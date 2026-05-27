#!/usr/bin/env node

import { createHash } from 'node:crypto';
import { execSync } from 'node:child_process';
import {
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  renameSync,
  statSync,
  writeFileSync,
} from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const VERSION = '2.0.0';
export const STATE_DIR = '.slim';
export const STATE_FILE = 'codemap.json';
export const LEGACY_STATE_FILE = 'cartography.json';
export const CODEMAP_FILE = 'codemap.md';

// ---------------------------------------------------------------------------
// Git helpers
// ---------------------------------------------------------------------------

export function isGitRepo(root) {
  try {
    execSync('git rev-parse --is-inside-work-tree', {
      cwd: root,
      stdio: 'pipe',
    });
    return true;
  } catch {
    return false;
  }
}

export function getGitHead(root) {
  try {
    return execSync('git rev-parse HEAD', {
      cwd: root,
      encoding: 'utf8',
    }).trim();
  } catch {
    return null;
  }
}

/** Returns list of changed file paths (relative) or null on failure. */
export function getGitChangedFiles(root, baseRef) {
  try {
    const refs = [
      // committed changes since baseRef
      baseRef ? `git diff --name-only ${baseRef}..HEAD` : null,
      // unstaged changes
      'git diff --name-only',
      // staged but uncommitted
      'git diff --name-only --cached',
      // untracked files
      'git ls-files --others --exclude-standard',
    ].filter(Boolean);

    const all = new Set();
    for (const cmd of refs) {
      const out = execSync(cmd, { cwd: root, encoding: 'utf8' }).trim();
      if (out) out.split('\n').filter(Boolean).forEach((f) => all.add(f));
    }
    return [...all];
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Pattern matching
// ---------------------------------------------------------------------------

export class PatternMatcher {
  regex;

  constructor(patterns) {
    if (!patterns.length) {
      this.regex = null;
      return;
    }

    const regexParts = patterns.map((pattern) => {
      let reg = pattern.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      reg = reg.replace(/\\\*\\\*\//g, '(?:.*/)?');
      reg = reg.replace(/\\\*\\\*/g, '.*');
      reg = reg.replace(/\\\*/g, '[^/]*');
      reg = reg.replace(/\\\?/g, '.');

      if (pattern.endsWith('/')) {
        reg += '.*';
      }

      if (pattern.startsWith('/')) {
        reg = `^${reg.slice(1)}`;
      } else {
        reg = `(?:^|.*/)${reg}`;
      }

      return `(?:${reg}$)`;
    });

    this.regex = new RegExp(regexParts.join('|'));
  }

  matches(filePath) {
    if (!this.regex) return false;
    return this.regex.test(filePath);
  }
}

export function loadGitignore(root) {
  const gitignorePath = path.join(root, '.gitignore');
  if (!existsSync(gitignorePath)) return [];

  return readFileSync(gitignorePath, 'utf8')
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'));
}

// ---------------------------------------------------------------------------
// File utilities
// ---------------------------------------------------------------------------

function walkFiles(root) {
  const files = [];

  function visit(currentDir) {
    for (const entry of readdirSync(currentDir, { withFileTypes: true })) {
      const fullPath = path.join(currentDir, entry.name);
      if (entry.isDirectory()) {
        if (!entry.name.startsWith('.')) {
          visit(fullPath);
        }
        continue;
      }

      if (entry.isFile()) {
        files.push(fullPath);
      }
    }
  }

  visit(root);
  return files.sort();
}

export function selectFiles(
  root,
  includePatterns,
  excludePatterns,
  exceptions,
  gitignorePatterns,
) {
  const includeMatcher = new PatternMatcher(includePatterns);
  const excludeMatcher = new PatternMatcher(excludePatterns);
  const gitignoreMatcher = new PatternMatcher(gitignorePatterns);
  const exceptionSet = new Set(exceptions);

  return walkFiles(root).filter((fullPath) => {
    let relPath = path.relative(root, fullPath).replaceAll(path.sep, '/');
    if (relPath.startsWith('./')) {
      relPath = relPath.slice(2);
    }

    if (gitignoreMatcher.matches(relPath)) return false;
    if (excludeMatcher.matches(relPath) && !exceptionSet.has(relPath)) {
      return false;
    }

    return includeMatcher.matches(relPath) || exceptionSet.has(relPath);
  });
}

export function computeFileHash(filePath) {
  try {
    const buffer = readFileSync(filePath);
    return createHash('md5').update(buffer).digest('hex');
  } catch {
    return '';
  }
}

export function computeFolderHash(folder, fileHashes) {
  const folderFiles = Object.entries(fileHashes)
    .filter(
      ([filePath]) =>
        filePath.startsWith(`${folder}/`) ||
        (folder === '.' && !filePath.includes('/')),
    )
    .sort(([a], [b]) => a.localeCompare(b));

  if (!folderFiles.length) return '';

  const hasher = createHash('md5');
  for (const [filePath, hash] of folderFiles) {
    hasher.update(`${filePath}:${hash}\n`);
  }
  return hasher.digest('hex');
}

export function getFoldersWithFiles(files, root) {
  const folders = new Set(['.']);

  for (const filePath of files) {
    const relPath = path.relative(root, filePath).replaceAll(path.sep, '/');
    const parts = relPath.split('/').slice(0, -1);
    for (let i = 0; i < parts.length; i++) {
      folders.add(parts.slice(0, i + 1).join('/'));
    }
  }

  return folders;
}

// ---------------------------------------------------------------------------
// State management
// ---------------------------------------------------------------------------

export function migrateLegacyState(root) {
  const stateDir = path.join(root, STATE_DIR);
  const legacyPath = path.join(stateDir, LEGACY_STATE_FILE);
  const statePath = path.join(stateDir, STATE_FILE);

  if (existsSync(statePath) || !existsSync(legacyPath)) {
    return false;
  }

  mkdirSync(stateDir, { recursive: true });
  renameSync(legacyPath, statePath);
  console.log(
    `Migrated ${STATE_DIR}/${LEGACY_STATE_FILE} -> ${STATE_DIR}/${STATE_FILE}`,
  );
  return true;
}

export function loadState(root) {
  migrateLegacyState(root);
  const statePath = path.join(root, STATE_DIR, STATE_FILE);
  if (!existsSync(statePath)) return null;

  try {
    return JSON.parse(readFileSync(statePath, 'utf8'));
  } catch {
    return null;
  }
}

export function saveState(root, state) {
  const stateDir = path.join(root, STATE_DIR);
  mkdirSync(stateDir, { recursive: true });
  writeFileSync(
    path.join(stateDir, STATE_FILE),
    `${JSON.stringify(state, null, 2)}\n`,
  );
}

export function createEmptyCodemap(folderPath, folderName) {
  const codemapPath = path.join(folderPath, CODEMAP_FILE);
  if (existsSync(codemapPath)) return;

  const content = `# ${folderName}/

<!-- Fixer: Fill in this section with architectural understanding -->

## Responsibility

<!-- What is this folder's job in the system? -->

## Design

<!-- Key patterns, abstractions, architectural decisions -->

## Flow

<!-- How does data/control flow through this module? -->

## Integration

<!-- How does it connect to other parts of the system? -->
`;

  writeFileSync(codemapPath, content);
}

// ---------------------------------------------------------------------------
// Build state (with git HEAD + codemap hashes)
// ---------------------------------------------------------------------------

function buildState(
  root,
  includePatterns,
  excludePatterns,
  exceptions,
  selectedFiles,
) {
  const fileHashes = {};
  for (const filePath of selectedFiles) {
    const relPath = path.relative(root, filePath).replaceAll(path.sep, '/');
    fileHashes[relPath] = computeFileHash(filePath);
  }

  const folders = getFoldersWithFiles(selectedFiles, root);
  const folderHashes = {};
  for (const folder of folders) {
    folderHashes[folder] = computeFolderHash(folder, fileHashes);
  }

  // Compute codemap.md hashes for skip-detection
  const codemapHashes = {};
  for (const folder of folders) {
    const codemapPath =
      folder === '.'
        ? path.join(root, CODEMAP_FILE)
        : path.join(root, folder, CODEMAP_FILE);
    if (existsSync(codemapPath)) {
      codemapHashes[folder] = computeFileHash(codemapPath);
    }
  }

  const state = {
    metadata: {
      version: VERSION,
      last_run: new Date().toISOString(),
      root,
      include_patterns: includePatterns,
      exclude_patterns: excludePatterns,
      exceptions,
      git_head: isGitRepo(root) ? getGitHead(root) : null,
    },
    file_hashes: fileHashes,
    folder_hashes: folderHashes,
    codemap_hashes: codemapHashes,
  };

  return { state, folders };
}

// ---------------------------------------------------------------------------
// Detect changes between two file-hash maps
// ---------------------------------------------------------------------------

function diffFileHashes(currentHashes, savedHashes) {
  const currentPaths = new Set(Object.keys(currentHashes));
  const savedPaths = new Set(Object.keys(savedHashes));

  const added = [...currentPaths]
    .filter((p) => !savedPaths.has(p))
    .sort();
  const removed = [...savedPaths]
    .filter((p) => !currentPaths.has(p))
    .sort();
  const modified = [...currentPaths]
    .filter((p) => savedPaths.has(p))
    .filter((p) => currentHashes[p] !== savedHashes[p])
    .sort();

  return { added, removed, modified };
}

/** Derive affected folders from a list of changed file paths. */
function affectedFoldersFromPaths(filePaths) {
  const folders = new Set();
  for (const fp of filePaths) {
    const parts = fp.split('/').slice(0, -1);
    // Always add leaf folder
    if (parts.length) {
      folders.add(parts.join('/'));
      // Also add all parent folders
      for (let i = 1; i < parts.length; i++) {
        folders.add(parts.slice(0, i).join('/'));
      }
    }
    // Root is always affected if any file changed
    folders.add('.');
  }
  return [...folders].sort();
}

// ---------------------------------------------------------------------------
// Commands
// ---------------------------------------------------------------------------

export function cmdInit({ root, include = [], exclude = [], exception = [] }) {
  const resolvedRoot = path.resolve(root);
  if (!existsSync(resolvedRoot) || !statSync(resolvedRoot).isDirectory()) {
    console.error(`Error: ${resolvedRoot} is not a directory`);
    return 1;
  }

  const includePatterns = include.length ? include : ['**/*'];
  const excludePatterns = exclude;
  const exceptions = exception;
  const gitignore = loadGitignore(resolvedRoot);

  console.log(`Scanning ${resolvedRoot}...`);
  console.log(`Include patterns: ${JSON.stringify(includePatterns)}`);
  console.log(`Exclude patterns: ${JSON.stringify(excludePatterns)}`);
  console.log(`Exceptions: ${JSON.stringify(exceptions)}`);

  const selectedFiles = selectFiles(
    resolvedRoot,
    includePatterns,
    excludePatterns,
    exceptions,
    gitignore,
  );

  console.log(`Selected ${selectedFiles.length} files`);

  const { state, folders } = buildState(
    resolvedRoot,
    includePatterns,
    excludePatterns,
    exceptions,
    selectedFiles,
  );

  saveState(resolvedRoot, state);
  console.log(`Created ${STATE_DIR}/${STATE_FILE}`);

  for (const folder of folders) {
    const folderPath =
      folder === '.' ? resolvedRoot : path.join(resolvedRoot, folder);
    const folderName = folder === '.' ? path.basename(resolvedRoot) : folder;
    createEmptyCodemap(folderPath, folderName);
  }

  console.log(`Created ${folders.size} empty codemap.md files`);
  return 0;
}

/**
 * `changes` command — supports two modes:
 *   --json   → machine-readable JSON (for agent consumption)
 *   default  → human-readable text (legacy)
 *
 * Detection strategy (in priority order):
 *   1. Git fast-path: if git available AND stored git_head is a valid ancestor
 *      → `git diff <head>..HEAD` gives O(changed) file list, skip full hash walk
 *   2. Hash fallback: walk all files, compute MD5, compare with stored state
 */
export function cmdChanges({ root, json: jsonMode = false }) {
  const resolvedRoot = path.resolve(root);
  const state = loadState(resolvedRoot);
  if (!state) {
    const msg = "No codemap state found. Run 'init' first.";
    if (jsonMode) {
      console.log(JSON.stringify({ error: msg, has_changes: false }));
    } else {
      console.error(msg);
    }
    return 1;
  }

  const metadata = state.metadata ?? {};
  const includePatterns = metadata.include_patterns ?? ['**/*'];
  const excludePatterns = metadata.exclude_patterns ?? [];
  const exceptions = metadata.exceptions ?? [];
  const savedHashes = state.file_hashes ?? {};
  const savedCodemapHashes = state.codemap_hashes ?? {};

  // --- Strategy 1: git fast-path ---
  let method = 'hash';
  let diff;

  const useGit = isGitRepo(resolvedRoot);
  const storedHead = metadata.git_head;

  if (useGit && storedHead) {
    const gitFiles = getGitChangedFiles(resolvedRoot, storedHead);
    if (gitFiles !== null) {
      method = 'git';
      // Filter git-changed files against include/exclude patterns
      const gitignore = loadGitignore(resolvedRoot);
      const includeMatcher = new PatternMatcher(includePatterns);
      const excludeMatcher = new PatternMatcher(excludePatterns);
      const gitignoreMatcher = new PatternMatcher(gitignore);
      const exceptionSet = new Set(exceptions);

      const tracked = gitFiles.filter((relPath) => {
        if (gitignoreMatcher.matches(relPath)) return false;
        if (excludeMatcher.matches(relPath) && !exceptionSet.has(relPath))
          return false;
        return includeMatcher.matches(relPath) || exceptionSet.has(relPath);
      });

      // Classify: files in git diff but not in saved state → added
      //           files in saved state but removed from git → we still need full scan for removals
      // For git path, we know modified + added from git diff.
      // We still check for removals by looking at saved paths not in current git tracked files.
      const currentGitTracked = new Set(tracked);
      const added = tracked.filter((f) => !(f in savedHashes)).sort();
      const modified = tracked
        .filter((f) => f in savedHashes)
        .filter((f) => {
          // For modified files, recompute hash to confirm (git diff may include
          // whitespace-only changes or renames that match our patterns differently)
          const fullPath = path.join(resolvedRoot, f);
          return computeFileHash(fullPath) !== savedHashes[f];
        })
        .sort();

      // For removals, do a lightweight check: files in savedHashes that no longer exist
      const removed = Object.keys(savedHashes)
        .filter((f) => !existsSync(path.join(resolvedRoot, f)))
        .sort();

      diff = { added, removed, modified };
    }
  }

  // --- Strategy 2: full hash scan fallback ---
  if (!diff) {
    method = 'hash';
    const gitignore = loadGitignore(resolvedRoot);
    const currentFiles = selectFiles(
      resolvedRoot,
      includePatterns,
      excludePatterns,
      exceptions,
      gitignore,
    );

    const currentHashes = Object.fromEntries(
      currentFiles.map((filePath) => [
        path.relative(resolvedRoot, filePath).replaceAll(path.sep, '/'),
        computeFileHash(filePath),
      ]),
    );

    diff = diffFileHashes(currentHashes, savedHashes);
  }

  const { added, removed, modified } = diff;
  const allChanged = [...added, ...removed, ...modified];
  const hasChanges = allChanged.length > 0;

  // Compute affected folders
  const affected = affectedFoldersFromPaths(allChanged);

  // Compute dirty folders: folders whose codemap.md needs regeneration
  // A folder is dirty if: its files changed OR its codemap.md doesn't exist yet
  const dirtyFolders = affected.filter((folder) => {
    const codemapPath =
      folder === '.'
        ? path.join(resolvedRoot, CODEMAP_FILE)
        : path.join(resolvedRoot, folder, CODEMAP_FILE);
    if (!existsSync(codemapPath)) return true;
    // If codemap hash unchanged and folder had no file changes, it's clean
    const folderChanged = allChanged.some((f) => {
      const parts = f.split('/');
      if (folder === '.') return parts.length <= 1;
      return f.startsWith(folder + '/');
    });
    return folderChanged;
  });

  const currentGitHead = useGit ? getGitHead(resolvedRoot) : null;

  // --- JSON output ---
  if (jsonMode) {
    console.log(
      JSON.stringify(
        {
          has_changes: hasChanges,
          method,
          git_head: currentGitHead,
          summary: {
            added: added.length,
            removed: removed.length,
            modified: modified.length,
            total_tracked: Object.keys(savedHashes).length,
          },
          added,
          removed,
          modified,
          affected_folders: affected,
          dirty_folders: dirtyFolders,
        },
        null,
        2,
      ),
    );
    return hasChanges ? 0 : 2; // exit code 2 = no changes (useful for scripting)
  }

  // --- Text output (legacy) ---
  if (!hasChanges) {
    console.log('No changes detected.');
    return 0;
  }

  if (added.length) {
    console.log(`\n${added.length} added:`);
    for (const filePath of added) console.log(`  + ${filePath}`);
  }

  if (removed.length) {
    console.log(`\n${removed.length} removed:`);
    for (const filePath of removed) console.log(`  - ${filePath}`);
  }

  if (modified.length) {
    console.log(`\n${modified.length} modified:`);
    for (const filePath of modified) console.log(`  ~ ${filePath}`);
  }

  console.log(`\n${dirtyFolders.length} folders need update:`);
  for (const folder of dirtyFolders) {
    console.log(`  ${folder}/`);
  }

  console.log(`\n  [detection: ${method}]`);
  return 0;
}

export function cmdUpdate({ root }) {
  const resolvedRoot = path.resolve(root);
  const state = loadState(resolvedRoot);
  if (!state) {
    console.error("No codemap state found. Run 'init' first.");
    return 1;
  }

  const metadata = state.metadata ?? {};
  const includePatterns = metadata.include_patterns ?? ['**/*'];
  const excludePatterns = metadata.exclude_patterns ?? [];
  const exceptions = metadata.exceptions ?? [];
  const gitignore = loadGitignore(resolvedRoot);

  const selectedFiles = selectFiles(
    resolvedRoot,
    includePatterns,
    excludePatterns,
    exceptions,
    gitignore,
  );

  const { state: nextState } = buildState(
    resolvedRoot,
    includePatterns,
    excludePatterns,
    exceptions,
    selectedFiles,
  );

  saveState(resolvedRoot, nextState);
  console.log(
    `Updated ${STATE_DIR}/${STATE_FILE} with ${selectedFiles.length} files`,
  );
  return 0;
}

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------

export function parseArgs(argv) {
  const [command, ...rest] = argv;
  const options = { include: [], exclude: [], exception: [] };

  for (let i = 0; i < rest.length; i++) {
    const arg = rest[i];
    if (!arg?.startsWith('--')) continue;

    // Boolean flags (no value needed)
    if (arg === '--json') {
      options.json = true;
      continue;
    }

    const value = rest[i + 1];
    if (value === undefined || value.startsWith('--')) {
      throw new Error(`Missing value for ${arg}`);
    }

    const key = arg.slice(2);
    if (key === 'include' || key === 'exclude' || key === 'exception') {
      options[key].push(value);
    } else if (key === 'root') {
      options.root = value;
    } else {
      throw new Error(`Unknown option: ${arg}`);
    }

    i++;
  }

  return { command, options };
}

export function main(argv = process.argv.slice(2)) {
  try {
    const { command, options } = parseArgs(argv);

    if (!command || !options.root) {
      console.error(
        'Usage: codemap.mjs <init|changes|update> --root /path [--include glob] [--exclude glob] [--exception path] [--json]',
      );
      return 1;
    }

    if (command === 'init') return cmdInit(options);
    if (command === 'changes') return cmdChanges(options);
    if (command === 'update') return cmdUpdate(options);

    console.error(`Unknown command: ${command}`);
    return 1;
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    return 1;
  }
}

const currentFilePath = fileURLToPath(import.meta.url);
if (process.argv[1] && path.resolve(process.argv[1]) === currentFilePath) {
  process.exit(main());
}
