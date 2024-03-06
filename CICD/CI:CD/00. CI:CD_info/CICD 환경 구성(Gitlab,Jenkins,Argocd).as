###################
##### jenkins #####
###################

1. Plugins Install
	1) 경로 : Dashboard > Jenkins 관리 > System Configuration > Plugins
	2) 설치 항목
		* kubernetes
		* copy artifact
		* Pipeline:GitHub
		* Jacoco
		* Github Custom Notification Context SCM Behaviour
		* Warnings Next Generation
		* Multibranch Pipeline Inline Definition
		* SonarQube Scanner (Optional)
		* Slack (Optional)


2. Credentials
	1) 경로 : Dashboard > Jenkins 관리 > Security > Credentials
	2) 필요 항목
		* Jenkins-Secret
			** Type: "Secret text"
			** Secret: "kubernetes secret 키값 확인 (인코딩/디코딩 확인)"

		* Docker-Hub-Secret
			** Type: "Secret text"
			** Secret: "Docker Hub Token"

		* GitLab-Secret
			** Type: "Username with password"
			** Password: "GitLab ID/PW 입력"


3. Build - Cloud 설정
	1) 경로: Dashboard > Jenkins 관리 > Clouds > "kubernetes" 선택
	2) 설정값
		* kubernetes URL: "https:// ip : Port" or "DNS record"
			// ex) https://10.0.15.226:6443

		* Disable https Certificate check: "Enable"
		* Kubernetes Namespace: "Jenkins가 배포 되어 있는 Namespace 입력"
			// ex) promt-service

		* Credentials: "Jekins-Secret (2에서 생성한 키)"

		* WebSocket: "Enable"

		* Jenkins URL: "호스팅 된 정보 입력"
			// ex) https://jenkins-demo.datastackcloud.com


4. 연동 정상 여부 테스트
	1) Pod Templates 추가
		* Test 정보
		---------------------------------------------------------------
		  - Pod Template > Add Pod Template
  		 	- Name : gradle:7.6.1-jdk17
    	  	- Label : gradle:7.6.1-jdk17
    		- Add Container
      			- Name : gradle
      			- Docker image : gradle:7.6.1-jdk17
    		- Add Volumes
      			- Host path : /volumes
      			- Mount path : /volumes
      	  - 저장
		---------------------------------------------------------------    	 	
  		  - Pod Template > Add Pod Template
    		- Name : kaniko
    		- Label: kaniko
    		- Add Container
      			- Name : kaniko
      			- Docker image : gcr.io/kaniko-project/executor:debug
      		- Add Volumes
      			- Host path : /volumes
      			- Mount path : /volumes
   		  - 저장
		---------------------------------------------------------------

	2) Pipline 작성
		* 경로: Dashboard > + 새로운 Item > Pipeline > Advanced project Options > 하단 Pipline - Definition: Pipeline Script > 저장

		* Test Script
		---------------------------------------------------------------
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
		---------------------------------------------------------------

	3) Build 진행 후 결과 확인
		* Console Output 내용 확인하여 진행 상태 확인: "Finished: SUCCESS" 이 떨어져야 정상


5. Jenkins <> GibLab Webhooks 연동을 위한 설정
	1) 경로: Jenkins Pipline > Configure > Build Triggers
	2) 설정값
		* 항목 체크: "Build when a change is pushed to GitLab. GitLab webhook URL: https:// xxx "
			** Push Events: "Enable"
			** Accepted Merge Request Events: "Enable"
			** Rebuild open Merge Requests: "Never"
			** Approved Merge Requests (EE-only): "Enable"
			** Comments: "Enable"
			** 고급
				*** Enable [ci-skip]: "Enable"
				*** Ignore WIP Merge Requests: "Enable"
				*** Set Build Description to Build cause (eg.Merge request ro Git Push): "Enable"
				*** Allowed branches
					**** Allow all branches to Trigger this job: "Enable"
				*** Secret Token
					**** Generate: "표시값 저장 필요"


6. Build & Deployment 를 위한 Project 생성
	1) Build
		* 서비스 별 각각의 Project 생성
		// ex) Build-nginx-web
		//	   Build-nginx-web01

	2) Deployment
		* 1개의 Project 안에 폴더 별 관리


###################
### Docker Hub ####
###################

1. Access Tokens 생성
	1) 경로: My Account > Account Settings > Security > New Access Token
	2) 설정값
		* Access Token Description: "식별 가능한 이름"
		* Access permissions: "Read, Write, Delete"


2. Repository 구성
	1) 경로: Docker Hub 접속 > Repositories > Create Repository
	2) 설정값
		* Namespace: "자신의 ID"
		* Repository Name: "사용할 Repo 이름"
		* Visibility: "Public"


###################
### Kubernetes ####
###################

1. config.json 파일 확인
	1) 경로: docker login > 문구 발생 "WARNING! Your password will be stored unencrypted in /Users/hwangjunsang/.docker/config.json."
		* cat /Users/hwangjunsang/.docker/config.json
	----------------
	{
		"auths": {
			"https://index.docker.io/v1/": {
				"auth": "anVuc2FuZzM2NDA6ZGNrcl9wYXRfTEdEdUY5MXhxS2dwckN5MHA0UHN4aHgta1kw"
			}
		}
	}
	----------------

2. docker-config.yaml 파일 생성
	1) config.json 파일 base64 인코딩
		* base64 config.json
			** 결과값 저장

	2) docker-Config.yaml 파일 생성

	# vi docker-config.yaml
	----------------
	apiVersion: v1
	kind: Secret
	metadata:
 	 name: docker-config
 	 namespace: "promotion-service"
	type: Opaque
	data:
 	 config.json: "base64 인코딩 파일 값"
 	 ----------------

  	3) 배포
		* Kubectl apply -f docker-config.yaml -n "ns"



###################
##### GitLab ######
###################

1. Project 생성
	- Build / Deploy 등 한번에 파악이 가능한 네이밍으로 설정하여 진행

2. Build 용 Project Webhooks 설정
	1) 경로: Project Settings > Webhooks
	2) 설정값
		* URL: Jenkins "5" 경로 확인
		//ex) Build when a change is pushed to GitLab. GitLab webhook URL: https://jenkins-demo.datastackcloud.com/project/build-nginx-web

		* Secret Token: Jenkins "5"에서 발급한 Secret Token 사용

		* Trigger
			** Push branches
			** Comments
			** Merge request Events

	3) Test
		* Push Events 실행 시, "Hook executed successfully: HTTP 200" : 정상 



###################
##### Argo CD #####
###################

1. Project 구성
	1) 경로: Settings > Projects

2. Repositories 구성
	1) 경로: Settings > Repositories
	2) 설정값
		* Choose your connection method: "VIA HTTPS"
			** Type: "Git"
			** Project: "프로젝트 선택"
			** Repository URL: "GitLab Project > Clone with HTTPS"
				// Jenkins "6-2: Deployment"에 해당하는 URL
			** Username: "GitLab ID"
			** Password: "GitLab Password"

3. Cluster 구성
	1) Cluster의 경우, GUI에서 생성이 불가능하며 Kubernetes ArgoCD Pod에 접속하여 생성 필요
		# argocd cluster add "Name"

4. Application 구성
	1) 경로: Application > New App
	2) 설정값
		* General
			** Application Name: "식별을 위한 네이밍 작성"
			** Project Name: "생성한 프로젝트 이름"
			** SYNC POLICY: "Automatic"
		* Source
			** Repository URL: "연동된 GitLab 주소"
			** Revision: "main"
			** Path: "GitLab 프로젝트 하위의 폴더명"
		* Destination
			** Cluster URL: "구성된 클러스터"
			** Namespace: "배포할 NS 명"



###################
#### Test 방법 #####
###################

1. GitLab Repo에 있는 Code 수정 시,
	1) Jenkins Build 진행 여부 확인
	
	2) ArgoCD Sync 진행 여부 확인






































