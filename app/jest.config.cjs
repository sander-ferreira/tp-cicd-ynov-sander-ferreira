module.exports = {
    testEnvironment: 'jest-environment-jsdom',
    transform: {
        '^.+\\.jsx?$': 'babel-jest',
    },
    moduleNameMapper: {
        '\\.(css|scss|svg|png|jpg|jpeg|gif)$': '<rootDir>/test/__mocks__/fileMock.js',
    },
    globals: {
        __VITE_API_URL__: '',
        __VITE_BASE_PATH__: '/Test_cycle_TDD/',
    },
};
