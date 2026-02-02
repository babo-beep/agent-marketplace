module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testTimeout: 60000, // 60 seconds for blockchain operations
  verbose: true,
  collectCoverage: false,
  testMatch: ['**/*.test.ts', '**/*.test.js'],
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx', 'json'],
  transform: {
    '^.+\\.tsx?$': 'ts-jest',
  },
  globals: {
    'ts-jest': {
      tsconfig: {
        esModuleInterop: true,
        allowSyntheticDefaultImports: true,
      }
    }
  }
};
