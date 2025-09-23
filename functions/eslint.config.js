module.exports = [
  {
    languageOptions: {
      globals: {
        es6: true,
        node: true,
      },
    },
    ignores: [
      "/lib/**/*", // Ignore built files.
      "/eslint.config.js", // Ignore eslint config itself
    ],
    plugins: {
      "@typescript-eslint": require("@typescript-eslint/eslint-plugin"),
      "import": require("eslint-plugin-import"),
    },
    rules: {
      "quotes": ["error", "double"],
      "import/no-unresolved": 0,
      "indent": ["error", 2],
      "max-len": ["error", {"code": 100}],
      "@typescript-eslint/no-unused-vars": ["error", { "argsIgnorePattern": "^_" }],
    },
  },
  // extends 대신 직접 추가
  require("@eslint/js").configs.recommended,
  require("@typescript-eslint/eslint-plugin").configs.recommended,
];