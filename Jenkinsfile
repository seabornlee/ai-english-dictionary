pipeline {
    agent any

    environment {
        MACOS_APP_DIR = 'ai-dic-mac'
        SERVER_DIR = 'ai-dic-server'
        NODE_VERSION = '18.x'
        NVM_DIR = "$HOME/.nvm"  // Define NVM_DIR in environment
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
                            // Add error handling for Xcode build
                            sh '''
                                set +e
                                xcodebuild clean build test \
                                -scheme AIDictionary \
                                -destination 'platform=macOS' \
                                CODE_SIGN_IDENTITY="" \
                                CODE_SIGNING_REQUIRED=NO
                                BUILD_STATUS=$?
                                if [ $BUILD_STATUS -ne 0 ]; then
                                    echo "Xcode build failed with status $BUILD_STATUS"
                                    exit $BUILD_STATUS
                                fi
                            '''
                        }
                    }
                }

                stage('Server') {
                    steps {
                        dir(SERVER_DIR) {
                            // Replace nodejs step with direct npm commands
                            sh '''
                                source $NVM_DIR/nvm.sh
                                nvm install ${NODE_VERSION}
                                nvm use ${NODE_VERSION}
                                npm ci
                                npm run test
                            '''
                        }
                    }
                }
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
                    }
                    steps {
                        dir(SERVER_DIR) {
                            // Replace nodejs step with direct npm commands
                            sh '''
                                source $NVM_DIR/nvm.sh
                                nvm install ${NODE_VERSION}
                                nvm use ${NODE_VERSION}
                                npm ci --production
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
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
