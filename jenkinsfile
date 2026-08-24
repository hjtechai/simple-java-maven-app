pipeline {
    agent any

    // tools {
    //     maven 'maven-3.9.16'
    // }


    stages {
        stage('Build') {
            agent {
                docker {
                    image 'maven:3.9.11-eclipse-temurin-21'
                }
            }
            steps {
                sh 'mvn clean package -DskipTests=true'
            }
        }
        stage('Unit Test') {
            agent {
                docker {
                    image 'maven:3.9.11-eclipse-temurin-21'
                }
            }
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit(testResults: 'target/surefire-reports/*.xml')
                }
            }
        }
    }
}
