pipeline {
    agent any

    environment {
        MACOS_APP_DIR = 'ai-dic-mac'
        SERVER_DIR = 'ai-dic-server'
        NODE_VERSION_20 = '20.5.0'
        NVM_DIR = "$HOME/.nvm"
        XCODE_TEST_REPORTS_DIR = "${WORKSPACE}/${MACOS_APP_DIR}/test-reports"
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

        stage('Build and Test') {
            parallel {
                stage('macOS App') {
                    agent { label 'macos' }
                    steps {
                        dir(MACOS_APP_DIR) {
                            sh '''
                                [ ! -f "AIDictionary.xcodeproj/project.pbxproj" ] && { echo "Error: project.pbxproj is missing!"; exit 1; }
                                
                                set +e
                                mkdir -p "${XCODE_TEST_REPORTS_DIR}"
                                xcodebuild clean build test \
                                    -scheme AIDictionary \
                                    -destination 'platform=macOS' \
                                    -resultBundlePath "${XCODE_TEST_REPORTS_DIR}/TestResults.xcresult" \
                                    CODE_SIGN_IDENTITY="" \
                                    CODE_SIGNING_REQUIRED=NO | xcpretty --report junit --output "${XCODE_TEST_REPORTS_DIR}/test-results.xml"
                                [ ${PIPESTATUS[0]} -ne 0 ] && { echo "Xcode build failed"; exit 1; }
                            '''
                        }
                    }
                }

                stage('Server Node 20') {
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
            }
        }

        stage('Deploy') {
            parallel {
                stage('Deploy macOS App') {
                    when { branch 'main' }
                    agent { label 'macos' }
                    steps {
                        dir(MACOS_APP_DIR) {
                            sh '''
                                set +e
                                xcodebuild archive \
                                    -scheme AIDictionary \
                                    -archivePath build/AIDictionary.xcarchive || { echo "Archive failed"; exit 1; }
                                    
                                xcodebuild -exportArchive \
                                    -archivePath build/AIDictionary.xcarchive \
                                    -exportPath build/export \
                                    -exportOptionsPlist exportOptions.plist || { echo "Export failed"; exit 1; }
                            '''
                        }
                    }
                }

                stage('Deploy Server') {
                    when { 
                        branch 'main'
                        environment name: 'NODE_VERSION', value: '20.x'
                    }
                    steps {
                        dir(SERVER_DIR) {
                            sh '''
                                set +e
                                source $NVM_DIR/nvm.sh
                                nvm install ${NODE_VERSION_20} || { echo "Node.js install failed"; exit 1; }
                                nvm use ${NODE_VERSION_20}
                                
                                npm install -g cnpm --registry=https://registry.npmmirror.com
                                cnpm install --production || { echo "Dependencies install failed"; exit 1; }
                            '''
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
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

                cleanWs()
            }
        }
        success { echo 'Pipeline completed successfully!' }
        failure { echo 'Pipeline failed!' }
    }
}
