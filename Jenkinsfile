pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('timotheh-dockerhub-password')
        IMAGE_NAME = 'timotheh/tasklist-backend'
        IMAGE_TAG = "${IMAGE_NAME}:${BUILD_NUMBER}"
    }

    stages {
        stage('Installation des dépendances') {
            steps {
                sh 'npm ci'
                sh 'npx prisma generate'
            }
        }

        stage('Tests unitaires') {
            steps {
                sh 'npx prisma generate --schema=prisma/schema-test.prisma'
                sh 'npm run test:coverage'
            }
            post {
                always {
                    junit testResults: 'reports/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('Tests end-to-end') {
            steps {
                sh 'npm run test:e2e:coverage'
            }
            post {
                always {
                    junit testResults: 'reports/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('Analyse SonarQube') {
            steps {
                withSonarQubeEnv('sonarqube-server-1') {
                    withCredentials([string(credentialsId: 'timotheh-sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh 'npx sonar-scanner -Dsonar.token=$SONAR_TOKEN'
                    }
                }
            }
        }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Build image Docker') {
            steps {
                sh "docker buildx build --tag ${IMAGE_TAG} --tag ${IMAGE_NAME}:latest --load ."
            }
        }

        stage('Scan Trivy') {
            steps {
                sh """
                    trivy image \
                        --severity CRITICAL,HIGH \
                        --format table \
                        ${IMAGE_TAG} | tee trivy-report.txt
                """
                sh """
                    trivy image \
                        --exit-code 1 \
                        --severity CRITICAL,HIGH \
                        --format json \
                        -o trivy-report.json \
                        ${IMAGE_TAG}
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'trivy-report.*', allowEmptyArchive: true
                }
            }
        }

        stage('Génération SBOM') {
            steps {
                sh "trivy image --format spdx-json --output sbom-spdx.json ${IMAGE_TAG}"
                sh "trivy image --format cyclonedx --output sbom-cyclonedx.json ${IMAGE_TAG}"
            }
            post {
                always {
                    archiveArtifacts artifacts: 'sbom-*.json', allowEmptyArchive: true
                }
            }
        }

        stage('Push DockerHub') {
            steps {
                sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                sh "docker push ${IMAGE_TAG}"
                sh "docker push ${IMAGE_NAME}:latest"
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline backend terminée avec succès !'
        }
        failure {
            echo 'Échec de la pipeline backend.'
        }
    }
}
