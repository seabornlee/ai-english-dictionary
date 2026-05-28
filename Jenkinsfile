pipeline {
    agent { label 'macos' }

    environment {
        MACOS_APP_DIR = 'ai-dic-mac'
        SERVER_DIR = 'ai-dic-server'
        NODE_VERSION_20 = '20.5.0'
        NVM_DIR = "$HOME/.nvm"
        SILICONFLOW_API_KEY = credentials('siliconflow-api-key')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        credentialsId: 'mbp',
                        url: 'git@github.com:seabornlee/ai-english-dictionary.git',
                    ]]
                ])
            }
        }

        stage('Setup Xcode') {
            steps {
                sh '''
                    # 确保 Xcode 命令行工具已安装
                    xcode-select --install || true
                    
                    # 设置 Xcode 路径
                    sudo xcode-select --switch /Applications/Xcode.app || { echo "Failed to switch Xcode"; exit 1; }
                    
                    # 接受 Xcode 许可
                    sudo xcodebuild -license accept || { echo "Failed to accept Xcode license"; exit 1; }
                    
                    # 运行 Xcode 首次启动
                    xcodebuild -runFirstLaunch || { echo "Failed to run Xcode first launch"; exit 1; }
                    
                    # 验证 Xcode 安装
                    xcodebuild -version || { echo "Failed to verify Xcode version"; exit 1; }
                '''
            }
        }

        stage('Format and Lint Swift Code') {
            steps {
                dir(MACOS_APP_DIR) {
                    sh '''
                        # Install SwiftFormat if not present
                        if ! which swiftformat > /dev/null; then
                            echo "Installing SwiftFormat..."
                            brew install swiftformat || { echo "Failed to install SwiftFormat"; exit 1; }
                        fi
                        
                        # Install SwiftLint if not present
                        if ! which swiftlint > /dev/null; then
                            echo "Installing SwiftLint..."
                            brew install swiftlint || { echo "Failed to install SwiftLint"; exit 1; }
                        fi
                        
                        # Run SwiftFormat check (lint mode - no changes)
                        echo "Running SwiftFormat check..."
                        mkdir -p lint-reports
                        swiftformat AIDictionary --config .swiftformat --lint 2>&1 | tee lint-reports/swiftformat-report.txt || true
                        
                        # Run SwiftLint
                        echo "Running SwiftLint..."
                        swiftlint lint --config .swiftlint.yml --reporter json > lint-reports/swiftlint-report.json || true
                        swiftlint lint --config .swiftlint.yml --reporter html > lint-reports/swiftlint-report.html || true
                        
                        # Run again to show output and fail on errors
                        swiftlint lint --config .swiftlint.yml --strict || { echo "SwiftLint found violations"; exit 1; }
                    '''
                }
            }
        }

        stage('Build and Test macOS App') {
            steps {
                dir(MACOS_APP_DIR) {
                    sh '''
                        # 检查项目文件是否存在
                        if [ ! -f "Package.swift" ]; then
                            echo "Error: Package.swift is missing!"
                            echo "Current directory contents:"
                            ls -la
                            exit 1
                        fi
                        
                        # 创建测试报告目录并清理旧文件
                        TEST_REPORTS_DIR="test-reports"
                        mkdir -p "${TEST_REPORTS_DIR}"
                        rm -rf "${TEST_REPORTS_DIR}/TestResults.xcresult"
                        rm -rf "${TEST_REPORTS_DIR}/test-results.xml"
                        rm -rf build.log
                        
                        # 运行构建和测试
                        set +e
                        set -x
                        swift build || { echo "Swift build failed"; exit 1; }
                        swift test --enable-code-coverage | tee build.log | xcpretty --report junit --output "${TEST_REPORTS_DIR}/test-results.xml"
                        
                        # 检查构建和测试结果
                        BUILD_RESULT=${PIPESTATUS[0]}
                        if [ $BUILD_RESULT -ne 0 ]; then
                            echo "Swift build/test failed with exit code $BUILD_RESULT"
                            echo "Build log:"
                            cat build.log
                            exit $BUILD_RESULT
                        fi
                        
                        # 检查测试结果文件
                        if [ ! -f "${TEST_REPORTS_DIR}/test-results.xml" ]; then
                            echo "Error: Test results file not found"
                            exit 1
                        fi
                        
                        echo "Build and test completed successfully"
                    '''
                }
            }
        }

        stage('Build and Test Server') {
            steps {
                dir(SERVER_DIR) {
                    sh '''
                        set +e
                        source $NVM_DIR/nvm.sh
                        nvm install ${NODE_VERSION_20} || { echo "Failed to install Node.js"; exit 1; }
                        nvm use ${NODE_VERSION_20}
                        
                        npm install -g cnpm --registry=https://registry.npmmirror.com
                        
                        rm -rf node_modules package-lock.json
                        npm cache clean --force
                        
                        for i in {1..3}; do
                            cnpm install --no-package-lock --registry=https://registry.npmmirror.com && break
                            [ $i -eq 3 ] && { echo "Failed to install dependencies"; exit 1; }
                            sleep 5
                        done
                        
                        mkdir -p test-reports
                        
                        # Run TypeScript type checking (warnings only during gradual adoption)
                        echo "Running TypeScript type check..."
                        cnpm run typecheck 2>&1 | tee typecheck-report.txt || echo "TypeScript found type issues (non-blocking during adoption phase)"
                        
                        cnpm run test:ci || { echo "Tests failed"; exit 1; }
                    '''
                }
            }
        }
    }

    post {
        always {
            script {
                // 发布测试报告
                junit([
                    allowEmptyResults: true,
                    testResults: "${MACOS_APP_DIR}/test-reports/test-results.xml",
                    healthScaleFactor: 1.0
                ])
                
                // 发布服务器测试报告
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: "${WORKSPACE}/${SERVER_DIR}/test-reports",
                    reportFiles: 'test-report.html',
                    reportName: 'Mocha Test Report',
                    reportTitles: 'Mocha Test Report'
                ])
                
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: "${WORKSPACE}/${SERVER_DIR}/coverage/lcov-report",
                    reportFiles: 'index.html',
                    reportName: 'Node.js Coverage Report',
                    reportTitles: 'Node.js Coverage Report'
                ])
                
                // Publish SwiftLint report
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: "${WORKSPACE}/${MACOS_APP_DIR}/lint-reports",
                    reportFiles: 'swiftlint-report.html',
                    reportName: 'SwiftLint Report',
                    reportTitles: 'SwiftLint Report'
                ])
            }
        }
        success { echo 'Pipeline completed successfully!' }
        failure { echo 'Pipeline failed!' }
    }
}
