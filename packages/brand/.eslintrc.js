module.exports = require('@backstage/cli/config/eslint-factory')(__dirname, {
  // The Stageshow kit is vendored from the skill (MIT, src/stageshow/kit/LICENSE)
  // and keeps its upstream code style.
  ignorePatterns: ['src/stageshow/kit/**'],
});
