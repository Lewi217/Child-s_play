pipeline {
    agent any

    environment {
        APP_DIR      = '/opt/childs-play'
        COMPOSE_FILE = 'docker-compose.yml'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo "Branch: ${env.BRANCH_NAME} | Commit: ${env.GIT_COMMIT?.take(7)}"
            }
        }

        stage('Build') {
            steps {
                // Build the production image (no dev deps, with Vite assets)
                sh 'docker build -t childs-play:${GIT_COMMIT?.take(7) ?: "latest"} .'
            }
        }

        stage('Test') {
            steps {
                // Build a test image (with dev deps/PHPUnit) and run tests.
                // Uses SQLite in-memory — no Postgres needed.
                sh '''
                    docker compose -f docker-compose.test.yml build
                    docker compose -f docker-compose.test.yml run --rm --no-deps app \
                        php artisan test
                '''
            }
            post {
                always {
                    sh 'docker compose -f docker-compose.test.yml down --remove-orphans || true'
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sshagent(credentials: ['deploy-server-ssh']) {
                    // Pull latest code on the production server
                    sh """
                        ssh -o StrictHostKeyChecking=no deployer@\${DEPLOY_HOST} '
                            set -e
                            cd ${APP_DIR}
                            git pull origin main
                        '
                    """

                    // Push the production .env to the server
                    withCredentials([file(credentialsId: 'childs-play-env', variable: 'ENV_FILE')]) {
                        sh 'scp -o StrictHostKeyChecking=no "$ENV_FILE" deployer@${DEPLOY_HOST}:${APP_DIR}/.env'
                    }

                    // Build and start containers on the production server
                    sh """
                        ssh -o StrictHostKeyChecking=no deployer@\${DEPLOY_HOST} '
                            set -e
                            cd ${APP_DIR}
                            docker compose -f ${COMPOSE_FILE} up -d --build --remove-orphans
                        '
                    """
                }
            }
        }

        stage('Post-Deploy') {
            when {
                branch 'main'
            }
            steps {
                sshagent(credentials: ['deploy-server-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no deployer@\${DEPLOY_HOST} '
                            set -e
                            cd ${APP_DIR}
                            docker compose exec -T app php artisan migrate --force
                            docker compose exec -T app php artisan config:cache
                            docker compose exec -T app php artisan route:cache
                            docker compose exec -T app php artisan view:cache
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline succeeded — ${env.JOB_NAME} #${env.BUILD_NUMBER}"
        }
        failure {
            echo "Pipeline FAILED — ${env.JOB_NAME} #${env.BUILD_NUMBER}. Check the stage logs above."
        }
        always {
            // Clean up dangling images on the Jenkins server
            sh 'docker image prune -f || true'
        }
    }
}
