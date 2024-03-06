
// Jenkins - Kubernetes 연동 설정 이후 정상 여부 확인을 위한 테스트 코드

-----------------------------------------------------------------
Cloud Pod Template 추가
-----------------------------------------------------------------
  - Pod Template > Add Pod Template
    - Name : gradle:7.6.1-jdk17
    - Label : gradle:7.6.1-jdk17
    - Add Container
      - Name : gradle
      - Docker image : gradle:7.6.1-jdk17
    - Add Volumes
      - Host path : /volumes
      - Mount path : /volumes
  - Pod Template > Add Pod Template
    - Name : kaniko
    - Label : kaniko
    - Add Container
      - Name : kaniko
      - Docker image : gcr.io/kaniko-project/executor:debug
    - 저장


-----------------------------------------------------------------
pipeline 작성
-----------------------------------------------------------------
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