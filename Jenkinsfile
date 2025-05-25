pipeline {
    environment {
        image_name = "l4d2-stats-server"
        registry_creds = 'dockerhub'
    }

    agent any
    
    stages {
        stage('Build image') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${env.registry_creds}", usernameVariable: 'registry_user', passwordVariable: 'registry_token')]) {
                    sh "docker build -t ${env.registry_user}/${env.image_name}:${env.BUILD_ID} ."
                    sh "docker login -u ${env.registry_user} -p ${env.registry_token}"
                    sh "docker push ${env.registry_user}/${env.image_name}:${env.BUILD_ID}"
                }
            }
        }
    }
}