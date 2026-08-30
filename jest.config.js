/** @type {import('jest').Config} */
module.exports = {
    testEnvironment: "node",
    rootDir: ".",
    testMatch: ["<rootDir>/test/**/*.test.ts"],
    transform: {
        "^.+\\.ts$": ["ts-jest", {tsconfig: "tsconfig.test.json"}]
    },
    // TypeORM decorators (@Entity, @Column, ...) need this at runtime, same
    // as src/index.ts's own `import "reflect-metadata"`.
    setupFiles: ["reflect-metadata"],
    clearMocks: true
};
