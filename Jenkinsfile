pipeline {
    environment {
        image_name = "l4d2-stats-server"
        registry_user = 'jackzmc'
        registry_creds = 'dockerhub'
        registry_url = 'https://docker.io'
    }

    agent any
    
    stages {
        stage('Build image') {
            steps {
                echo 'Starting to build docker image'
                script {
                    def customImage = docker.build("${env.registry_user}/${env.image_name}:${env.BUILD_ID}")
                }
            }
        }
        stage("Publish image") {
            docker.withRegistry("${env.registry_url}", "${env.registry_creds}") {
                customImage.push()
            }
        }
    }
}
