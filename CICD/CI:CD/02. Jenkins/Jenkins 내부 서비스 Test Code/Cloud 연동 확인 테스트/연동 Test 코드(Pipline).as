// Uses Declarative syntax to run commands inside a container.
pipeline {
  agent {
    kubernetes {
      inheritFrom "gradle:7.6.1-jdk17 kaniko"
    }
  }
  stages {
    stage('gradle') {
      steps {
        container("gradle") {
          sh 'hostname'
        }
        container("kaniko") {
          sh 'hostname'
        }
      }
    }
  }
}