pipeline {
    environment {
        image_name = "l4d2-stats-server"
        registry_creds = 'dockerhub'
    }

    agent any
    
    stages {
        stage('Build server image') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${env.registry_creds}", usernameVariable: 'REGISTRY_USER', passwordVariable: 'REGISTRY_TOKEN')]) {
                    sh "docker build -t ${env.REGISTRY_USER}/${env.image_name}:${env.BUILD_ID} ."
                    sh 'echo "$REGISTRY_TOKEN" | docker login -u $REGISTRY_USER --password-stdin'
                    sh "docker push ${env.REGISTRY_USER}/${env.image_name}:${env.BUILD_ID}"
                }
            }
        }
        stage("Build plugin") {
            agent {
                docker {
                    image 'jackzmc/spcomp:debian-1.12-git7202'
                    reuseNode true
                }
            }
            steps {
                sh '/sourcemod/compile_jenkins.sh'
            }
            post {
                success {
                    dir("plugins") {
                        archiveArtifacts(artifacts: '*.smx', fingerprint: true)
                    }
                }
            }
        }
    }
}