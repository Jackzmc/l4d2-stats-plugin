pipeline {
    agent any
    stages {
        stage('Build image') {
            steps {
                echo 'Starting to build docker image'
                script {
                    docker.withRegistry('https://docker.io', 'dockerhub') {
                        def customImage = docker.build("l4d2-stats-server:${env.BUILD_ID}")
                        customImage.push()
                    }
                    
                }
            }
        }
    }
}
