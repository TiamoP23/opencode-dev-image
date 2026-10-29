import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';

const dockerfile = readFileSync(new URL('../Dockerfile', import.meta.url), 'utf8');
const compose = readFileSync(new URL('../compose.example.yml', import.meta.url), 'utf8');
const workflow = readFileSync(new URL('../.github/workflows/publish.yml', import.meta.url), 'utf8');

test('image pins the V2 CLI package', () => {
  assert.match(dockerfile, /^ARG OPENCODE_VERSION=2\.2\.1$/m);
  assert.match(dockerfile, /npm install -g "@opencode\/cli@\$\{OPENCODE_VERSION\}"/);
  assert.doesNotMatch(dockerfile, /npm install -g opencode-ai/);
});

test('compose runs the foreground V2 server on the proxy port', () => {
  assert.match(compose, /- opencode\s+- serve\s+- --hostname\s+- 0\.0\.0\.0\s+- --port\s+- ['"]?4096['"]?/);
  assert.match(compose, /^\s+- OPENCODE_PASSWORD=\$\{OPENCODE_PASSWORD:\?OPENCODE_PASSWORD is required\}$/m);
});

test('CI checks the full OpenCode version output', () => {
  assert.ok(workflow.includes('test "$(opencode --version)" = "opencode v2.2.1"'));
});

test('CI publishes the exact loaded image only after smoke testing', () => {
  assert.equal(workflow.match(/uses: docker\/build-push-action@/g)?.length, 1);
  assert.match(workflow, /load: true/);
  assert.match(workflow, /push: false/);
  assert.match(workflow, /tags: \$\{\{ steps\.meta\.outputs\.tags \}\}/);
  assert.match(workflow, /IMAGE_TAGS: \$\{\{ steps\.meta\.outputs\.tags \}\}/);
  const smoke = workflow.indexOf('- name: Smoke test image');
  const publish = workflow.indexOf('- name: Publish tested image');
  assert.ok(smoke !== -1 && publish > smoke);
  assert.match(workflow.slice(publish), /while IFS= read -r tag; do\s+docker push "\$tag"\s+done <<< "\$IMAGE_TAGS"/);
});
