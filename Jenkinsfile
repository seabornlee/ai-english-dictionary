pipeline {
    agent any

    environment {
        MACOS_APP_DIR = 'ai-dic-mac'
        SERVER_DIR = 'ai-dic-server'
        NODE_VERSION_18 = '18.20.2'  // Changed to specific LTS version
        NODE_VERSION_20 = '20.13.1'  // Changed to specific LTS version
        NVM_DIR = "$HOME/.nvm"
        // Test report directories with workspace-relative paths
        NODE_TEST_REPORTS_DIR = '${WORKSPACE}/test-reports/node'
        XCODE_TEST_REPORTS_DIR = '${WORKSPACE}/test-reports/xcode'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build and Test') {
            parallel {
                stage('macOS App') {
                    agent {
                        label 'macos'
                    }
                    steps {
                        dir(MACOS_APP_DIR) {
                            // Validate Xcode project before building
                            sh '''
                                if [ ! -f "AIDictionary.xcodeproj/project.pbxproj" ]; then
                                    echo "Error: project.pbxproj is missing!"
                                    exit 1
                                fi
                                
                                # Add error handling for Xcode build

                                set +e
                                mkdir -p "${XCODE_TEST_REPORTS_DIR}"
                                xcodebuild clean build test \
                                -scheme AIDictionary \
                                -destination 'platform=macOS' \
                                -resultBundlePath "${XCODE_TEST_REPORTS_DIR}/TestResults.xcresult" \
                                CODE_SIGN_IDENTITY="" \
                                CODE_SIGNING_REQUIRED=NO | xcpretty --report junit --output "${XCODE_TEST_REPORTS_DIR}/test-results.xml"
                                BUILD_STATUS=${PIPESTATUS[0]}
                                if [ $BUILD_STATUS -ne 0 ]; then
                                    echo "Xcode build failed with status $BUILD_STATUS"
                                    exit $BUILD_STATUS
                                fi
                            '''
                        }
                    }
                }

                stage('Server Node 18') {
                    steps {
                        dir(SERVER_DIR) {
                            // Enhanced Node.js setup with version validation
                            sh '''
                                set +e
                                source $NVM_DIR/nvm.sh
                                echo "Installing Node.js ${NODE_VERSION_18}"
                                nvm install ${NODE_VERSION_18}
                                INSTALL_STATUS=$?
                                if [ $INSTALL_STATUS -ne 0 ]; then
                                    echo "Failed to install Node.js ${NODE_VERSION_18}"
                                    exit $INSTALL_STATUS
                                fi
                                
                                nvm use ${NODE_VERSION_18}
                                node -v
                                npm -v
                                
                                echo "Installing dependencies"
                                npm ci
                                CI_STATUS=$?
                                if [ $CI_STATUS -ne 0 ]; then
                                    echo "npm ci failed with status $CI_STATUS"
                                    exit $CI_STATUS
                                fi
                                
                                echo "Running tests with coverage"
                                mkdir -p "${NODE_TEST_REPORTS_DIR}"
                                JEST_JUNIT_OUTPUT_DIR="${NODE_TEST_REPORTS_DIR}" npm run test -- --reporters=default --reporters=jest-junit --coverage
                                TEST_STATUS=$?
                                if [ $TEST_STATUS -ne 0 ]; then
                                    echo "Tests failed with status $TEST_STATUS"
                                    exit $TEST_STATUS
                                fi
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
                                echo "Installing Node.js ${NODE_VERSION_20}"
                                nvm install ${NODE_VERSION_20}
                                INSTALL_STATUS=$?
                                if [ $INSTALL_STATUS -ne 0 ]; then
                                    echo "Failed to install Node.js ${NODE_VERSION_20}"
                                    exit $INSTALL_STATUS
                                fi
                                
                                nvm use ${NODE_VERSION_20}
                                node -v
                                npm -v
                                
                                echo "Installing dependencies"
                                npm ci
                                CI_STATUS=$?
                                if [ $CI_STATUS -ne 0 ]; then
                                    echo "npm ci failed with status $CI_STATUS"
                                    exit $CI_STATUS
                                fi
                                
                                echo "Running tests with coverage"
                                mkdir -p "${NODE_TEST_REPORTS_DIR}"
                                JEST_JUNIT_OUTPUT_DIR="${NODE_TEST_REPORTS_DIR}" npm run test -- --reporters=default --reporters=jest-junit --coverage
                                TEST_STATUS=$?
                                if [ $TEST_STATUS -ne 0 ]; then
                                    echo "Tests failed with status $TEST_STATUS"
                                    exit $TEST_STATUS
                                fi
                            '''
                        }
                    }
                }

                // Then remove the entire 'Server Node 21' stage since it's not needed
            }
        }

        stage('Deploy') {
            parallel {
                stage('Deploy macOS App') {
                    when {
                        branch 'main'
                    }
                    agent {
                        label 'macos'
                    }
                    steps {
                        dir(MACOS_APP_DIR) {
                            // Add error handling for archive and export
                            sh '''
                                set +e
                                xcodebuild archive \
                                -scheme AIDictionary \
                                -archivePath build/AIDictionary.xcarchive
                                ARCHIVE_STATUS=$?
                                
                                if [ $ARCHIVE_STATUS -eq 0 ]; then
                                    xcodebuild -exportArchive \
                                    -archivePath build/AIDictionary.xcarchive \
                                    -exportPath build/export \
                                    -exportOptionsPlist exportOptions.plist
                                    EXPORT_STATUS=$?
                                    
                                    if [ $EXPORT_STATUS -ne 0 ]; then
                                        echo "Export archive failed with status $EXPORT_STATUS"
                                        exit $EXPORT_STATUS
                                    fi
                                else
                                    echo "Archive creation failed with status $ARCHIVE_STATUS"
                                    exit $ARCHIVE_STATUS
                                fi
                            '''
                            // Add steps to upload to distribution platform
                        }
                    }
                }

                stage('Deploy Server') {
                    when {
                        branch 'main'
                        // Deploy with the latest LTS version
                        environment name: 'NODE_VERSION', value: '20.x'
                    }
                    steps {
                        dir(SERVER_DIR) {
                            // Enhanced deployment setup with error handling
                            sh '''
                                set +e
                                source $NVM_DIR/nvm.sh
                                echo "Installing Node.js ${NODE_VERSION_20}"
                                nvm install ${NODE_VERSION_20}
                                INSTALL_STATUS=$?
                                if [ $INSTALL_STATUS -ne 0 ]; then
                                    echo "Failed to install Node.js ${NODE_VERSION_20}"
                                    exit $INSTALL_STATUS
                                fi
                                
                                nvm use ${NODE_VERSION_20}
                                node -v
                                npm -v
                                
                                echo "Installing production dependencies"
                                npm ci --production
                                CI_STATUS=$?
                                if [ $CI_STATUS -ne 0 ]; then
                                    echo "npm ci failed with status $CI_STATUS"
                                    exit $CI_STATUS
                                fi
                            '''
                            // Add deployment steps (e.g., to cloud platform)
                        }
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                // Create test report directories
                sh "mkdir -p ${NODE_TEST_REPORTS_DIR} ${XCODE_TEST_REPORTS_DIR}"
                
                // Publish Node.js test results
                junit allowEmptyResults: true, testResults: "${NODE_TEST_REPORTS_DIR}/*.xml"
                
                // Publish coverage reports
                publishHTML([
                    allowMissing: true,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: "${SERVER_DIR}/coverage/lcov-report",
                    reportFiles: 'index.html',
                    reportName: 'Node.js Coverage Report',
                    reportTitles: 'Node.js Coverage Report'
                ])
                
                // Publish XCode test results
                junit allowEmptyResults: true, testResults: "${XCODE_TEST_REPORTS_DIR}/*.xml"
                // Preserve Xcode project files when cleaning workspace
                if (fileExists('${MACOS_APP_DIR}/AIDictionary.xcodeproj')) {
                    sh "tar -czf xcode_project_backup.tar.gz ${MACOS_APP_DIR}/AIDictionary.xcodeproj"
                }
                cleanWs()
                if (fileExists('xcode_project_backup.tar.gz')) {
                    sh "tar -xzf xcode_project_backup.tar.gz"
                    sh "rm xcode_project_backup.tar.gz"
                }
            }
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
