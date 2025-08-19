// eslint.config.mjs
import tseslint from 'typescript-eslint';
import globals from 'globals';

export default [
  { ignores: ['dist/**', 'lib/**', 'node_modules/**'] },
  { languageOptions: { globals: { ...globals.node } } },

  ...tseslint.configs.recommended,

  // 👇 Add this block at the end
  {
    rules: {
      // EITHER completely turn it off:
      '@typescript-eslint/no-explicit-any': 'off',

      // OR make it a warning instead of an error:
      // '@typescript-eslint/no-explicit-any': 'warn',
    },
  },
];
