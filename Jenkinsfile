pipeline {
    agent any

    environment {
        MACOS_APP_DIR = 'ai-dic-mac'
        SERVER_DIR = 'ai-dic-server'
        NODE_VERSION_20 = '20.5.0'
        NVM_DIR = "$HOME/.nvm"
        XCODE_TEST_REPORTS_DIR = "${WORKSPACE}/${MACOS_APP_DIR}/test-reports"
        PGYER_API_KEY = credentials('PGYER_API_KEY')
        PGYER_USER_KEY = credentials('PGYER_USER_KEY')
        DEVELOPMENT_TEAM = credentials('DEVELOPMENT_TEAM')
        PROVISIONING_PROFILE = credentials('PROVISIONING_PROFILE')
        CERTIFICATE_P12 = credentials('CERTIFICATE_P12')
        CERTIFICATE_PASSWORD = credentials('CERTIFICATE_PASSWORD')
        CODE_SIGN_IDENTITY = credentials('CODE_SIGN_IDENTITY')
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
            agent { label 'macos' }
            steps {
                sh '''
                    # 安装 xcpretty
                    gem install xcpretty || { echo "Failed to install xcpretty"; exit 1; }
                    
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

        stage('Install Certificates') {
            agent { label 'macos' }
            steps {
                sh '''
                    # 创建临时目录
                    mkdir -p ~/temp_certs
                    cd ~/temp_certs

                    # 导出证书
                    echo "${CERTIFICATE_P12}" | base64 --decode > certificate.p12

                    # 删除已存在的钥匙串（如果存在）
                    security delete-keychain build.keychain || true

                    # 创建钥匙串
                    security create-keychain -p "${CERTIFICATE_PASSWORD}" build.keychain
                    security unlock-keychain -p "${CERTIFICATE_PASSWORD}" build.keychain
                    security set-keychain-settings -t 3600 -l ~/Library/Keychains/build.keychain

                    # 导入证书
                    security import certificate.p12 -k build.keychain -P "${CERTIFICATE_PASSWORD}" -T /usr/bin/codesign
                    security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "${CERTIFICATE_PASSWORD}" build.keychain

                    # 清理临时文件
                    rm -rf ~/temp_certs
                '''
            }
        }

        stage('Build and Test macOS App') {
            agent { label 'macos' }
            steps {
                dir(MACOS_APP_DIR) {
                    sh '''
                        # 检查项目文件是否存在
                        if [ ! -f "AIDictionary.xcodeproj/project.pbxproj" ]; then
                            echo "Error: project.pbxproj is missing!"
                            echo "Current directory contents:"
                            ls -la
                            echo "AIDictionary.xcodeproj contents:"
                            ls -la AIDictionary.xcodeproj/ 2>/dev/null || echo "AIDictionary.xcodeproj directory does not exist"
                            exit 1
                        fi
                        
                        # 创建测试报告目录并清理旧文件
                        mkdir -p "${XCODE_TEST_REPORTS_DIR}"
                        rm -rf "${XCODE_TEST_REPORTS_DIR}/TestResults.xcresult"
                        rm -rf "${XCODE_TEST_REPORTS_DIR}/test-results.xml"
                        rm -rf build.log
                        
                        # 运行构建和测试
                        set +e
                        xcodebuild clean build test \
                            -scheme AIDictionary \
                            -destination 'platform=macOS' \
                            -resultBundlePath "${XCODE_TEST_REPORTS_DIR}/TestResults.xcresult" \
                            DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
                            PROVISIONING_PROFILE="${PROVISIONING_PROFILE}" \
                            CODE_SIGN_STYLE="Manual" \
                            CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
                            CODE_SIGNING_REQUIRED=YES | tee build.log | xcpretty --report junit --output "${XCODE_TEST_REPORTS_DIR}/test-results.xml"
                        
                        # 检查构建和测试结果
                        BUILD_RESULT=${PIPESTATUS[0]}
                        if [ $BUILD_RESULT -ne 0 ]; then
                            echo "Xcode build failed with exit code $BUILD_RESULT"
                            echo "Build log:"
                            cat build.log
                            exit $BUILD_RESULT
                        fi
                        
                        # 检查测试结果文件
                        if [ ! -f "${XCODE_TEST_REPORTS_DIR}/test-results.xml" ]; then
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
                        cnpm run test:ci || { echo "Tests failed"; exit 1; }
                    '''
                }
            }
        }

        stage('Build and Upload to Pgyer') {
            agent { label 'macos' }
            steps {
                dir(MACOS_APP_DIR) {
                    sh '''
                        set +e
                        # 构建应用
                        xcodebuild archive \
                            -scheme AIDictionary \
                            -archivePath build/AIDictionary.xcarchive \
                            DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
                            PROVISIONING_PROFILE="${PROVISIONING_PROFILE}" \
                            CODE_SIGN_STYLE="Manual" \
                            CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
                            CODE_SIGNING_REQUIRED=YES || { echo "Archive failed"; exit 1; }
                            
                        xcodebuild -exportArchive \
                            -archivePath build/AIDictionary.xcarchive \
                            -exportPath build/export \
                            -exportOptionsPlist exportOptions.plist || { echo "Export failed"; exit 1; }

                        # 上传到蒲公英
                        curl -F "file=@build/export/AIDictionary.app.zip" \
                             -F "_api_key=${PGYER_API_KEY}" \
                             -F "buildInstallType=2" \
                             -F "buildPassword=123456" \
                             -F "buildUpdateDescription=${GIT_COMMIT}" \
                             https://www.pgyer.com/apiv2/app/upload || { echo "Upload to Pgyer failed"; exit 1; }
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
                    testResults: "${XCODE_TEST_REPORTS_DIR}/test-results.xml",
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

                //cleanWs()

                // 清理钥匙串
                sh '''
                    security delete-keychain build.keychain || true
                '''
            }
        }
        success { echo 'Pipeline completed successfully!' }
        failure { echo 'Pipeline failed!' }
    }
}
