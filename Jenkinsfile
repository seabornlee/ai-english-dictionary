pipeline {
    agent any

    environment {
        MACOS_APP_DIR = 'ai-dic-mac'
        SERVER_DIR = 'ai-dic-server'
        NODE_VERSION = '18.x'
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
                            sh '''
                                xcodebuild clean build test \
                                -scheme AIDictionary \
                                -destination 'platform=macOS' \
                                CODE_SIGN_IDENTITY="" \
                                CODE_SIGNING_REQUIRED=NO
                            '''
                        }
                    }
                }

                stage('Server') {
                    steps {
                        dir(SERVER_DIR) {
                            nodejs(nodeJSInstallationName: NODE_VERSION) {
                                sh 'npm ci'
                                sh 'npm run test'
                            }
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
                            sh '''
                                xcodebuild archive \
                                -scheme AIDictionary \
                                -archivePath build/AIDictionary.xcarchive
                                
                                xcodebuild -exportArchive \
                                -archivePath build/AIDictionary.xcarchive \
                                -exportPath build/export \
                                -exportOptionsPlist exportOptions.plist
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
                            nodejs(nodeJSInstallationName: NODE_VERSION) {
                                sh 'npm ci --production'
                                // Add deployment steps (e.g., to cloud platform)
                            }
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
            // Add notification steps (e.g., email, Slack)
        }
    }
}