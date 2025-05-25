pipeline {
    environment {
        image_name = "l4d2-stats-server"
        registry_user = 'jackzmc'
        registry_creds = 'dockerhub'
    }

    agent any
    
    stages {
        stage('Build image') {
            steps {
                echo 'Starting to build docker image'
                script {
                    def customImage = docker.build("${env.registry_user}/${env.image_name}:${env.BUILD_ID}")
                    docker.withRegistry(credentialsId: "${env.registry_creds}") {
                        customImage.push()
                    }
                }
            }
        }
    }
}
