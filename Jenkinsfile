pipeline {
    agent any

    environment {
        APP_DIR        = '/opt/childs-play'
        COMPOSE_FILE   = 'docker-compose.yml'
        IMAGE_TAG      = "${env.GIT_COMMIT?.take(7) ?: 'latest'}"
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 20, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo "Branch: ${env.BRANCH_NAME} | Commit: ${env.GIT_COMMIT?.take(7)}"
            }
        }

        stage('Inject .env') {
            steps {
                // 'childs-play-env' is the credential ID you'll create in Jenkins
                // Type: Secret file — upload your production .env
                withCredentials([file(credentialsId: 'childs-play-env', variable: 'ENV_FILE')]) {
                    sh 'cp "$ENV_FILE" .env'
                }
            }
        }

        stage('Build') {
            steps {
                sh 'docker compose -f $COMPOSE_FILE build --pull --no-cache'
            }
        }

        stage('Test') {
            steps {
                // Spin up only the app container (no external traffic) and run tests
                sh '''
                    docker compose -f $COMPOSE_FILE run --rm \
                        -e APP_ENV=testing \
                        app php artisan test --parallel
                '''
            }
            post {
                always {
                    // Tear down test containers regardless of result
                    sh 'docker compose -f $COMPOSE_FILE down --remove-orphans'
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                // 'deploy-server-ssh' is the SSH credential ID (private key) you'll add in Jenkins
                sshagent(credentials: ['deploy-server-ssh']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no deployer@\${DEPLOY_HOST} '
                            set -e
                            cd ${APP_DIR}
                            git pull origin main
                        '
                    """

                    // Copy the production .env to the server
                    withCredentials([file(credentialsId: 'childs-play-env', variable: 'ENV_FILE')]) {
                        sh 'scp -o StrictHostKeyChecking=no "$ENV_FILE" deployer@${DEPLOY_HOST}:${APP_DIR}/.env'
                    }

                    sh """
                        ssh -o StrictHostKeyChecking=no deployer@\${DEPLOY_HOST} '
                            set -e
                            cd ${APP_DIR}
                            docker compose -f ${COMPOSE_FILE} pull
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
            echo "Pipeline FAILED — ${env.JOB_NAME} #${env.BUILD_NUMBER}. Check logs above."
        }
        always {
            // Clean up any dangling build artifacts
            sh 'docker image prune -f || true'
        }
    }
}
